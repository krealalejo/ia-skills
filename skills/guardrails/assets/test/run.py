import json, subprocess, sys
import os
G = os.environ.get("GUARD") or os.path.expanduser("~/.claude/hooks/guard-bash.sh")
cases = json.load(open(sys.argv[1]))
fails = 0
for exp, cmd in cases:
    p = subprocess.run([G], input=json.dumps(
        {"tool_name": "Bash", "tool_input": {"command": cmd}, "cwd": "/Users/kevinrealalejo"}),
        capture_output=True, text=True)
    tag = {2: "BLOCK", 0: "allow"}.get(p.returncode, "ERR%d" % p.returncode)
    ok = tag.lower().startswith(exp)
    fails += (not ok)
    rule = ""
    if p.stderr.strip():
        rule = p.stderr.strip().split("\n")[0].split("[")[-1].rstrip("]")
    print(f"{'OK  ' if ok else 'FAIL'}[{tag:5}] {cmd[:56].replace(chr(10),' | '):<58}{rule}")
print(f"\n{len(cases)-fails}/{len(cases)} passed")
sys.exit(1 if fails else 0)
