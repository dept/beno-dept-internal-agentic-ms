#!/usr/bin/env python3
"""Read and write a Confluence page as ADF without losing its macros or extensions.

The community Atlassian MCP rewrites a page body through Markdown, which deletes the
Mermaid Diagrams Viewer extension; storage format mangles its guestParams. This script
round-trips the page's own ADF instead, and refuses a write that would drop an extension.

Usage:
  python3 scripts/confluence-adf.py get <page-id> <file.json>
  python3 scripts/confluence-adf.py put <page-id> <file.json> "<version message>"
  python3 scripts/confluence-adf.py selftest

Edit the ADF in <file.json> between get and put. Credentials come from CONFLUENCE_URL
(the api.atlassian.com gateway URL ending in /wiki), CONFLUENCE_USERNAME and
CONFLUENCE_API_TOKEN, the same variables the maintainer workflow passes to the MCP.
"""
import base64
import json
import os
import re
import sys
import urllib.error
import urllib.request

CONFIDENCE = re.compile(r"confidence\s*:\s*\d+\s*%", re.IGNORECASE)


def walk(node):
    yield node
    for child in node.get("content") or []:
        yield from walk(child)


def extensions(adf):
    return sorted(
        json.dumps(n.get("attrs", {}), sort_keys=True)
        for n in walk(adf)
        if n.get("type") in ("extension", "bodiedExtension", "inlineExtension")
    )


def problems(old, new):
    """Reasons a write of `new` over `old` must be refused. Empty list means safe."""
    found = []
    missing = list(extensions(old))
    for ext in extensions(new):
        if ext in missing:
            missing.remove(ext)
    if missing:
        found.append(f"{len(missing)} macro/extension node(s) on the live page are missing or changed")
    if any(CONFIDENCE.search(n.get("text", "")) for n in walk(new)):
        found.append("page text contains a confidence score; confidence stays in .ai/")
    code_blocks = sum(1 for n in walk(new) if n.get("type") == "codeBlock")
    for n in walk(new):
        index = ((n.get("attrs") or {}).get("parameters") or {}).get("guestParams", {})
        index = index.get("index") if isinstance(index, dict) else None
        if index is not None and not (isinstance(index, int) and 0 <= index < code_blocks):
            found.append(f"Mermaid viewer guestParams.index {index!r} does not point at one of {code_blocks} code blocks")
    return found


def request(method, path, body=None):
    base = os.environ["CONFLUENCE_URL"].rstrip("/")
    auth = f'{os.environ["CONFLUENCE_USERNAME"]}:{os.environ["CONFLUENCE_API_TOKEN"]}'
    req = urllib.request.Request(
        base + path,
        method=method,
        data=json.dumps(body).encode() if body is not None else None,
        headers={
            "Authorization": "Basic " + base64.b64encode(auth.encode()).decode(),
            "Accept": "application/json",
            "Content-Type": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(req) as resp:
            return json.load(resp)
    except urllib.error.HTTPError as err:
        sys.exit(f"{method} {path}: HTTP {err.code} {err.read()[:500]!r}")


def fetch(page_id):
    page = request("GET", f"/api/v2/pages/{page_id}?body-format=atlas_doc_format")
    return page, json.loads(page["body"]["atlas_doc_format"]["value"])


def get(page_id, path):
    page, adf = fetch(page_id)
    with open(path, "w", encoding="utf-8") as fh:
        json.dump(adf, fh, indent=1, ensure_ascii=False)
    print(f'{page["title"]} | version {page["version"]["number"]} | {len(extensions(adf))} extension(s) -> {path}')


def put(page_id, path, message):
    with open(path, encoding="utf-8") as fh:
        new = json.load(fh)
    page, old = fetch(page_id)
    found = problems(old, new)
    if found:
        sys.exit("Refusing to write:\n- " + "\n- ".join(found))
    version = page["version"]["number"] + 1
    request("PUT", f"/api/v2/pages/{page_id}", {
        "id": page_id,
        "status": "current",
        "title": page["title"],
        "body": {"representation": "atlas_doc_format", "value": json.dumps(new)},
        "version": {"number": version, "message": message},
    })
    _, stored = fetch(page_id)
    if extensions(stored) != extensions(new):
        sys.exit(f"Written as version {version}, but the stored extensions differ from what was sent. Check the page.")
    print(f'{page["title"]} | version {version} written, {len(extensions(stored))} extension(s) intact')


def selftest():
    viewer = {"type": "extension", "attrs": {"extensionKey": "k", "parameters": {"guestParams": {"index": 0}}}}
    code = {"type": "codeBlock", "content": [{"type": "text", "text": "graph LR"}]}
    para = {"type": "paragraph", "content": [{"type": "text", "text": "Hello"}]}
    old = {"type": "doc", "content": [code, viewer, para]}
    assert problems(old, old) == []
    assert problems(old, {"type": "doc", "content": [code, para]}), "dropped extension must be refused"
    conf = {"type": "paragraph", "content": [{"type": "text", "text": "Confidence: 90%"}]}
    assert problems(old, {"type": "doc", "content": [code, viewer, conf]}), "confidence must be refused"
    assert problems(old, {"type": "doc", "content": [viewer, para]}), "viewer without code block must be refused"
    print("selftest ok")


if __name__ == "__main__":
    args = sys.argv[1:]
    if args[:1] == ["get"] and len(args) == 3:
        get(args[1], args[2])
    elif args[:1] == ["put"] and len(args) == 4:
        put(args[1], args[2], args[3])
    elif args == ["selftest"]:
        selftest()
    else:
        sys.exit(__doc__)
