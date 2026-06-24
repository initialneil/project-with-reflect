#!/usr/bin/env python3
# Upsert the YAML frontmatter of an entity note from scalar managed fields, preserving
# non-managed keys (tags, aliases, …) and the whole body. stdlib-only (no pyyaml).
#   _note.py <md_path> <name> <seed_tag> key=value [key=value ...]
# Pass a key with an empty value (key=) to DROP a stale key without writing a new one.
# Values are emitted as safe double-quoted YAML scalars. Body defaults to "# <name>" if new.
import json, os, re, sys

path, name, tag = sys.argv[1:4]
order, managed, MANAGED = [], {}, set()
for p in sys.argv[4:]:
    k, _, v = p.partition("=")
    order.append(k); MANAGED.add(k)
    if v != "":
        managed[k] = v

def q(s):  # valid double-quoted YAML scalar (handles spaces/punct/unicode)
    return json.dumps(str(s), ensure_ascii=False)

mlines = [f"{k}: {q(managed[k])}" for k in order if k in managed]

txt = open(path).read() if os.path.exists(path) else None
def split_fm(t):
    if not t or not t.startswith("---\n"): return None, (t or "")
    rest = t[4:]; i = rest.find("\n---\n")
    return (rest[:i+1], rest[i+5:]) if i != -1 else (None, t)
fm, body = split_fm(txt)

kept, skip = [], False
for line in (fm.splitlines() if fm else []):
    k = re.match(r'^([A-Za-z0-9_\-]+):', line)
    if k: skip = k.group(1) in MANAGED
    if not skip and line.strip(): kept.append(line)

if not any(re.match(r'^tags:', l) for l in kept):
    kept = ["tags:", f"  - {tag}"] + kept
if not body.strip():
    body = f"# {name}\n"

open(path, "w").write("---\n" + "\n".join(kept + mlines) + "\n---\n\n" + body.lstrip("\n"))
