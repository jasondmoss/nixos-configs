#!/usr/bin/env python3
"""Build-time helper for packages/unclutter: reproducible zip/XPI and CRX3.

    crx3.py zip  <dir> <out.zip|out.xpi>
    crx3.py pack <dir> <out.crx> --seed <string> [--id-file F] [--key-file F]

`pack` derives an RSA-2048 key from --seed (deterministic, see below),
writes the matching `key` into <dir>/manifest.json so an unpacked load of
the same directory gets the same extension ID, zips the directory, and wraps
the zip in a CRX3 container signed with that key. The extension ID (the
first 128 bits of SHA-256 over the DER SubjectPublicKeyInfo, hex mapped to
a-p) goes to --id-file, the base64 public key to --key-file.

Why a seed-derived key instead of a key file: the CRX signature is only an
*identity* here, not a trust anchor. Chrome installs this CRX because root
listed it in an external-extensions directory, not because it trusts the
key; the manifest has no update_url, so nobody can push an update signed
with the key either. A random key would either have to be committed (this
config is a public repo) or kept out of tree, and it would still grant
nothing that root does not already have. Deriving it inside the sandboxed
build keeps the derivation pure and the ID stable across rebuilds.

Only Python's stdlib RNG (Mersenne Twister, stable since 3.2) and the
`cryptography` package are needed; the protobuf header is hand-encoded.
"""

import argparse
import base64
import hashlib
import json
import os
import random
import struct
import sys
import zipfile

from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding, rsa

# --- deterministic RSA ------------------------------------------------------

_SMALL_PRIMES = [p for p in range(3, 2000, 2) if all(p % q for q in range(3, int(p**0.5) + 1, 2))]


def _probable_prime(n, rng, rounds=64):
    if n < 2:
        return False
    for p in _SMALL_PRIMES:
        if n % p == 0:
            return n == p
    d, s = n - 1, 0
    while d % 2 == 0:
        d //= 2
        s += 1
    for _ in range(rounds):
        a = rng.randrange(2, n - 1)
        x = pow(a, d, n)
        if x in (1, n - 1):
            continue
        for _ in range(s - 1):
            x = pow(x, 2, n)
            if x == n - 1:
                break
        else:
            return False
    return True


def _prime(bits, rng):
    while True:
        c = rng.getrandbits(bits) | (1 << (bits - 1)) | 1
        if _probable_prime(c, rng):
            return c


def derive_key(seed, bits=2048):
    rng = random.Random(int.from_bytes(hashlib.sha256(seed.encode()).digest(), "big"))
    e = 65537
    while True:
        p = _prime(bits // 2, rng)
        q = _prime(bits // 2, rng)
        if p == q:
            continue
        n = p * q
        phi = (p - 1) * (q - 1)
        if n.bit_length() != bits or phi % e == 0:
            continue
        if p < q:
            p, q = q, p
        d = pow(e, -1, phi)
        numbers = rsa.RSAPrivateNumbers(
            p=p, q=q, d=d,
            dmp1=d % (p - 1), dmq1=d % (q - 1), iqmp=pow(q, -1, p),
            public_numbers=rsa.RSAPublicNumbers(e, n),
        )
        return numbers.private_key()


def spki(key):
    return key.public_key().public_bytes(
        serialization.Encoding.DER, serialization.PublicFormat.SubjectPublicKeyInfo
    )


def extension_id(spki_der):
    digest = hashlib.sha256(spki_der).hexdigest()[:32]
    return digest.translate(str.maketrans("0123456789abcdef", "abcdefghijklmnop"))


## reproducible zip
# ------------------------------------------------------------------------------

def make_zip(directory, out_path):
    entries = []
    for root, dirs, files in os.walk(directory):
        dirs.sort()
        for name in sorted(files):
            full = os.path.join(root, name)
            entries.append((os.path.relpath(full, directory), full))
    entries.sort()
    with zipfile.ZipFile(out_path, "w") as zf:
        for arcname, full in entries:
            info = zipfile.ZipInfo(arcname, date_time=(1980, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o644 << 16
            with open(full, "rb") as f:
                zf.writestr(info, f.read())


## CRX3
# ------------------------------------------------------------------------------

def _varint(n):
    out = bytearray()
    while True:
        b = n & 0x7F
        n >>= 7
        if n:
            out.append(b | 0x80)
        else:
            out.append(b)
            return bytes(out)


def _field(number, payload):
    return _varint((number << 3) | 2) + _varint(len(payload)) + payload


def make_crx(zip_bytes, key):
    pub = spki(key)
    crx_id = hashlib.sha256(pub).digest()[:16]
    signed_header_data = _field(1, crx_id)  # SignedData { crx_id = 1 }
    to_sign = (
        b"CRX3 SignedData\x00"
        + struct.pack("<I", len(signed_header_data))
        + signed_header_data
        + zip_bytes
    )
    signature = key.sign(to_sign, padding.PKCS1v15(), hashes.SHA256())
    proof = _field(1, pub) + _field(2, signature)  # AsymmetricKeyProof
    header = _field(2, proof) + _field(10000, signed_header_data)  # CrxFileHeader
    return b"Cr24" + struct.pack("<II", 3, len(header)) + header + zip_bytes


## CLI
# ------------------------------------------------------------------------------

def cmd_zip(args):
    make_zip(args.dir, args.out)


def cmd_pack(args):
    key = derive_key(args.seed)
    pub = spki(key)
    ext_id = extension_id(pub)
    pub_b64 = base64.b64encode(pub).decode()

    manifest_path = os.path.join(args.dir, "manifest.json")
    with open(manifest_path) as f:
        manifest = json.load(f)
    manifest["key"] = pub_b64
    with open(manifest_path, "w") as f:
        json.dump(manifest, f, indent=2, sort_keys=True)
        f.write("\n")

    tmp_zip = args.out + ".zip"
    make_zip(args.dir, tmp_zip)
    with open(tmp_zip, "rb") as f:
        zip_bytes = f.read()
    os.unlink(tmp_zip)

    with open(args.out, "wb") as f:
        f.write(make_crx(zip_bytes, key))
    if args.id_file:
        with open(args.id_file, "w") as f:
            f.write(ext_id + "\n")
    if args.key_file:
        with open(args.key_file, "w") as f:
            f.write(pub_b64 + "\n")
    print(ext_id)


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    z = sub.add_parser("zip")
    z.add_argument("dir")
    z.add_argument("out")
    z.set_defaults(func=cmd_zip)
    p = sub.add_parser("pack")
    p.add_argument("dir")
    p.add_argument("out")
    p.add_argument("--seed", required=True)
    p.add_argument("--id-file")
    p.add_argument("--key-file")
    p.set_defaults(func=cmd_pack)
    args = ap.parse_args()
    args.func(args)


if __name__ == "__main__":
    sys.exit(main())
