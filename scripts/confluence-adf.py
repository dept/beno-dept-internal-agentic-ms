#!/usr/bin/env python3
"""Read and write a Confluence page as ADF without losing its macros or extensions.

The community Atlassian MCP rewrites a page body through Markdown, which deletes the
Mermaid Diagrams Viewer extension; storage format mangles its guestParams. This script
round-trips the page's own ADF instead, and refuses a write that would drop an extension.

Usage:
  python3 scripts/confluence-adf.py get <page-id>
  python3 scripts/confluence-adf.py put <page-id> "<version message>"
  python3 scripts/confluence-adf.py selftest

`get` writes the page's ADF to .confluence-adf/<page-id>.json in the working directory; edit
that file, then `put`. The path is derived from the numeric page id, never taken from the
command line, and the directory ignores itself in git, so the file is never committed. `get` records
the page version next to the file (.version); `put` refuses if the page changed since, so a
human edit is never overwritten. Credentials come from CONFLUENCE_URL
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

# Bounded quantifiers only, so the pattern cannot backtrack on long text.
# Up to three words may sit between "confidence" and the score ("Confidence score: 90%").
CONFIDENCE = re.compile(r"confidence(?:\W{1,3}[a-z]{1,20}){0,3}\W{0,3}\d{1,3} ?%|\d{1,3} ?%(?:\W{1,3}[a-z]{1,20}){0,3}\W{0,3}confidence", re.IGNORECASE)
# Nodes a Markdown round-trip loses. Compared by type plus attrs (localId ignored).
PROTECTED = {"extension", "bodiedExtension", "inlineExtension", "status", "mention", "date", "media", "mediaSingle", "mediaGroup", "mediaInline"}
MERMAID = re.compile(r"\s*(graph|flowchart|sequenceDiagram|classDiagram|stateDiagram|erDiagram|gantt|pie|journey|mindmap|timeline|C4\w*)\b")


def walk(node):
    yield node
    for child in node.get("content") or []:
        yield from walk(child)


def protected(adf):
    out = []
    for n in walk(adf):
        if n.get("type") in PROTECTED:
            attrs = {k: v for k, v in (n.get("attrs") or {}).items() if k != "localId"}
            out.append(json.dumps([n["type"], attrs], sort_keys=True))
    return sorted(out)


def extensions(adf):
    return [p for p in protected(adf) if "xtension" in p.split(",")[0]]


def text_of(node):
    return "".join(n.get("text", "") for n in walk(node))


def viewer_indexes(adf):
    for n in walk(adf):
        params = (n.get("attrs") or {}).get("parameters")
        guest = params.get("guestParams") if isinstance(params, dict) else None
        if isinstance(guest, dict) and "index" in guest:
            yield guest["index"]


def problems(old, new):
    """Reasons a write of `new` over `old` must be refused. Empty list means safe."""
    found = []
    missing = list(protected(old))
    for node in protected(new):
        if node in missing:
            missing.remove(node)
    if missing:
        found.append(f"{len(missing)} macro/extension/status/mention/media node(s) on the live page are missing or changed")
    blocks = [n for n in walk(new) if n.get("type") in ("paragraph", "heading", "tableRow", "listItem", "codeBlock")]
    if any(CONFIDENCE.search(text_of(b)) for b in blocks):
        found.append("page text contains a confidence score; confidence stays in .ai/")
    code = [text_of(n) for n in walk(new) if n.get("type") == "codeBlock"]
    for index in viewer_indexes(new):
        if not (isinstance(index, int) and 0 <= index < len(code)):
            found.append(f"Mermaid viewer guestParams.index {index!r} does not point at one of {len(code)} code blocks")
        elif not MERMAID.match(code[index]):
            found.append(f"Mermaid viewer guestParams.index {index} points at a code block that is not Mermaid source; a code block was added or removed above the diagram, update the index")
    return found


def request(method, path, body=None):
    env = {k: os.environ.get(k, "") for k in ("CONFLUENCE_URL", "CONFLUENCE_USERNAME", "CONFLUENCE_API_TOKEN")}
    if not all(env.values()):
        sys.exit("Cannot run: CONFLUENCE_URL, CONFLUENCE_USERNAME and CONFLUENCE_API_TOKEN must be set.")
    base = env["CONFLUENCE_URL"].rstrip("/")
    auth = f'{env["CONFLUENCE_USERNAME"]}:{env["CONFLUENCE_API_TOKEN"]}'
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
        with urllib.request.urlopen(req, timeout=60) as resp:
            return json.load(resp)
    except urllib.error.HTTPError as err:
        sys.exit(f"{method} {path}: HTTP {err.code} {err.read()[:500]!r}")


def page_number(arg):
    if not arg.isdigit():
        sys.exit(f"Page id must be numeric, got {arg!r}")
    return int(arg)


WORK_DIR = ".confluence-adf"


def adf_path(page_id):
    # Inside the workspace, not /tmp, so no world-writable directory is involved.
    os.makedirs(WORK_DIR, exist_ok=True)
    with open(os.path.join(WORK_DIR, ".gitignore"), "w", encoding="utf-8") as fh:
        fh.write("*\n")
    return os.path.join(WORK_DIR, f"{page_id}.json")


def fetch(page_id):
    page = request("GET", f"/api/v2/pages/{page_id}?body-format=atlas_doc_format")
    return page, json.loads(page["body"]["atlas_doc_format"]["value"])


def get(page_id):
    path = adf_path(page_id)
    page, adf = fetch(page_id)
    with open(path, "w", encoding="utf-8") as fh:
        json.dump(adf, fh, indent=1, ensure_ascii=False)
    with open(path + ".version", "w", encoding="utf-8") as fh:
        fh.write(str(page["version"]["number"]))
    print(f'{page["title"]} | version {page["version"]["number"]} | {len(extensions(adf))} extension(s) -> {path}')


def put(page_id, message):
    path = adf_path(page_id)
    with open(path, encoding="utf-8") as fh:
        new = json.load(fh)
    with open(path + ".version", encoding="utf-8") as fh:
        expected = int(fh.read().strip())
    page, old = fetch(page_id)
    if page["version"]["number"] != expected:
        sys.exit(f'Refusing to write: the page moved from version {expected} to {page["version"]["number"]} since get. Run get again and redo the edit.')
    found = problems(old, new)
    if found:
        sys.exit("Refusing to write:\n- " + "\n- ".join(found))
    version = page["version"]["number"] + 1
    request("PUT", f"/api/v2/pages/{page_id}", {
        "id": str(page_id),
        "status": "current",
        "title": page["title"],
        "body": {"representation": "atlas_doc_format", "value": json.dumps(new)},
        "version": {"number": version, "message": message},
    })
    _, stored = fetch(page_id)
    if extensions(stored) != extensions(new):
        sys.exit(f"Written as version {version}, but the stored extensions differ from what was sent. Do not retry; list the page in the PR body for a human to check.")
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
    bash = {"type": "codeBlock", "content": [{"type": "text", "text": "pnpm install"}]}
    assert problems(old, {"type": "doc", "content": [bash, code, viewer, para]}), "shifted index must be refused"
    bold = {"type": "paragraph", "content": [{"type": "text", "text": "Confidence", "marks": [{"type": "strong"}]}, {"type": "text", "text": ": 90%"}]}
    assert problems(old, {"type": "doc", "content": [code, viewer, bold]}), "split confidence must be refused"
    status = {"type": "paragraph", "content": [{"type": "status", "attrs": {"text": "DONE", "localId": "a"}}]}
    with_status = {"type": "doc", "content": [code, viewer, status]}
    assert problems(with_status, {"type": "doc", "content": [code, viewer, para]}), "dropped status must be refused"
    relabelled = json.loads(json.dumps(with_status))
    relabelled["content"][2]["content"][0]["attrs"]["localId"] = "b"
    assert problems(with_status, relabelled) == [], "a new localId alone is not a change"
    inline = {"type": "paragraph", "content": [{"type": "mediaInline", "attrs": {"id": "m"}}]}
    assert problems({"type": "doc", "content": [code, viewer, inline]}, old), "dropped inline media must be refused"
    assert problems(old, {"type": "doc", "content": [code, viewer, {"type": "paragraph", "content": [{"type": "text", "text": "90 % confidence"}]}]})
    for text in ["Confidence score: 90%", "confidence level is 85 %", "90% overall confidence"]:
        worded = {"type": "paragraph", "content": [{"type": "text", "text": text}]}
        assert problems(old, {"type": "doc", "content": [code, viewer, worded]}), f"{text!r} must be refused"
    plain = {"type": "paragraph", "content": [{"type": "text", "text": "We have confidence in the 2026 plan and 90% test coverage"}]}
    assert problems(old, {"type": "doc", "content": [code, viewer, plain]}) == [], "unrelated percentages are allowed"
    print("selftest ok")


if __name__ == "__main__":
    args = sys.argv[1:]
    if args[:1] == ["get"] and len(args) == 2:
        get(page_number(args[1]))
    elif args[:1] == ["put"] and len(args) == 3:
        put(page_number(args[1]), args[2])
    elif args == ["selftest"]:
        selftest()
    else:
        sys.exit(__doc__)
