#!/usr/bin/env python3
"""Make a bootstrap script the "main" of an Electron app.asar, in place.

    patch-asar.py <app.asar> <shim.js> <shim-name>

Appends <shim.js> as /<shim-name> plus a rewritten package.json whose
"main" is <shim-name>, then points the header at them. Existing file data
never moves (the old package.json bytes stay as dead space), so nothing
needs repacking and app.asar.unpacked is untouched. The literal
@ORIGINAL_MAIN@ in the shim becomes a require() path to the previous main.

Fuses on this build: OnlyLoadAppFromAsar=1 and NODE_OPTIONS=0, so code
can only get in through app.asar itself.
"""
import hashlib
import json
import struct
import sys

BLOCK = 4 * 1024 * 1024


def integrity(data):
    blocks = [hashlib.sha256(data[i:i + BLOCK]).hexdigest()
              for i in range(0, len(data), BLOCK)] or [hashlib.sha256(b'').hexdigest()]
    return {
        'algorithm': 'SHA256',
        'hash': hashlib.sha256(data).hexdigest(),
        'blockSize': BLOCK,
        'blocks': blocks,
    }


def pickle_string(raw):
    payload = struct.pack('<I', len(raw)) + raw + b'\0' * (-len(raw) % 4)
    return struct.pack('<I', len(payload)) + payload


def main(asar_path, shim_path, shim_name):
    with open(asar_path, 'rb') as f:
        buf = f.read()

    size_len, header_size = struct.unpack_from('<II', buf, 0)
    _, json_len = struct.unpack_from('<II', buf, 8)
    if size_len != 4:
        sys.exit(f'{asar_path}: not an asar archive')
    header = json.loads(buf[16:16 + json_len])
    data = bytearray(buf[8 + header_size:])
    files = header['files']

    if shim_name in files:
        sys.exit(f'{asar_path}: already contains {shim_name}')

    pkg_entry = files['package.json']
    start = int(pkg_entry['offset'])
    pkg = json.loads(data[start:start + pkg_entry['size']])
    old_main = pkg['main']
    if not old_main.startswith(('./', '../')):
        old_main = './' + old_main

    with open(shim_path, 'rb') as f:
        shim = f.read()
    if b'@ORIGINAL_MAIN@' not in shim:
        sys.exit(f'{shim_path}: missing @ORIGINAL_MAIN@ placeholder')
    shim = shim.replace(b'@ORIGINAL_MAIN@', json.dumps(old_main).encode())

    pkg['main'] = shim_name
    new_pkg = (json.dumps(pkg, indent=2, ensure_ascii=False) + '\n').encode()

    for name, blob in ((shim_name, shim), ('package.json', new_pkg)):
        entry = dict(files.get(name, {}))
        entry.update(size=len(blob), offset=str(len(data)), integrity=integrity(blob))
        files[name] = entry
        data += blob

    header_pickle = pickle_string(
        json.dumps(header, separators=(',', ':'), ensure_ascii=False).encode())
    with open(asar_path, 'wb') as f:
        f.write(struct.pack('<II', 4, len(header_pickle)))
        f.write(header_pickle)
        f.write(data)

    print(f'{asar_path}: main {old_main} -> {shim_name}')


if __name__ == '__main__':
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    main(*sys.argv[1:])
