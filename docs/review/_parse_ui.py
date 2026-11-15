import sys, re
path = sys.argv[1]
t = open(path, encoding="utf-8", errors="replace").read()
print("---- nodes ----")
for m in re.finditer(r"<node[^>]*>", t):
    s = m.group(0)
    text = re.search(r'text="([^"]*)"', s)
    desc = re.search(r'content-desc="([^"]*)"', s)
    bounds = re.search(r'bounds="([^"]*)"', s)
    click = re.search(r'clickable="([^"]*)"', s)
    tv = text.group(1) if text else ""
    dv = desc.group(1) if desc else ""
    if tv or dv:
        ck = click.group(1) if click else "?"
        bd = bounds.group(1) if bounds else "?"
        print("text=%r desc=%r click=%s bounds=%s" % (tv, dv, ck, bd))
