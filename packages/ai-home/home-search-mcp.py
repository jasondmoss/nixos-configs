#!/usr/bin/env python3
"""home-search — MCP server: full-text search over the home directory.

Backed by the Recoll (Xapian) index that ai-home-index.service maintains.
Runs inside the ai-home sandbox (see ../../ai-home.nix): paths listed in
services.ai-home.hiddenPaths do not exist in this mount namespace, and the
index is built inside the same namespace, so it never contains them either.

Transport is stdio; mcp-proxy exposes it over streamable HTTP at
http://127.0.0.1:<port>/servers/search/mcp for Open WebUI / opencode.
"""

import os
import re
import time
from typing import Any

from fastmcp import FastMCP
from recoll import recoll

CONFDIR = os.environ.get("RECOLL_CONFDIR", "/var/lib/ai-home/recoll")
HOME = os.environ.get("AI_HOME_ROOT", "/home/me")

mcp = FastMCP(
    "home-search",
    instructions=(
        "Full-text search over the user's home directory. Use search_files to "
        "find documents, notes, code, configs and mail by content or name, "
        "then read the returned paths with the filesystem tools."
    ),
)


def _path(url: str) -> str:
    return url[7:] if url.startswith("file://") else url


_TAGS = re.compile(r"<[^>]+>")


def _plain(html: str) -> str:
    # Recoll marks matches with <span class="rclmatch">; the model wants text.
    return re.sub(r"\s+", " ", _TAGS.sub("", html)).strip()


def _iso(epoch: str | int | None) -> str | None:
    try:
        return time.strftime("%Y-%m-%d %H:%M", time.localtime(int(epoch)))
    except (TypeError, ValueError):
        return None


@mcp.tool
def search_files(
    query: str,
    max_results: int = 20,
    newest_first: bool = False,
    directory: str | None = None,
) -> list[dict[str, Any]]:
    """Full-text search over the home directory (Recoll query language).

    Query syntax: plain words are ANDed; "quoted phrase"; a OR b; -exclude;
    field filters: ext:pdf  mime:text/plain  filename:*.nix  title:budget
    author:name  dir:/home/me/Documents  date:2025-01-01/2025-12-31
    (relative dates: date:P30D/ for the last 30 days).
    Word stemming is on. Returns path, title, mime type, modification time,
    size, relevance and a query-focused snippet for each hit.
    `directory` restricts results to a subtree (absolute or relative to $HOME).
    """
    if directory:
        d = directory if directory.startswith("/") else os.path.join(HOME, directory)
        query = f'{query} dir:"{d}"'

    db = recoll.connect(confdir=CONFDIR)
    q = db.query()
    if newest_first:
        q.sortby("mtime", ascending=False)
    q.execute(query, stemming=1)

    out: list[dict[str, Any]] = []
    for doc in q.fetchmany(max(1, min(max_results, 100))):
        path = _path(doc.url)
        # Belt and braces: anything the sandbox hides is unreadable here even
        # if a stale index entry survived a hiddenPaths change.
        if not os.access(path, os.R_OK):
            continue
        try:
            snippet = q.makedocabstract(doc)
        except Exception:  # noqa: BLE001 — abstract is best-effort
            snippet = getattr(doc, "abstract", "") or ""
        out.append(
            {
                "path": path,
                "inner_path": getattr(doc, "ipath", "") or None,
                "title": getattr(doc, "title", "") or os.path.basename(path),
                "mime": getattr(doc, "mtype", "") or None,
                "modified": _iso(getattr(doc, "mtime", None)),
                "size_bytes": int(getattr(doc, "fbytes", 0) or 0),
                "relevance": getattr(doc, "relevancyrating", "") or None,
                "snippet": _plain(snippet)[:1200],
            }
        )
    return out


@mcp.tool
def index_status() -> dict[str, Any]:
    """Report the state of the home search index (document count, last run)."""
    status: dict[str, Any] = {"confdir": CONFDIR}
    idx = os.path.join(CONFDIR, "idxstatus.txt")
    if os.path.exists(idx):
        status["last_indexer_update"] = _iso(os.path.getmtime(idx))
        with open(idx, encoding="utf-8", errors="replace") as fh:
            for line in fh:
                if "=" in line:
                    k, v = line.split("=", 1)
                    status[k.strip()] = v.strip()
    return status


if __name__ == "__main__":
    mcp.run()
