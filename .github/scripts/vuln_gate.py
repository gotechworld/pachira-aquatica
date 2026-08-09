#!/usr/bin/env python3
import argparse, json, sys

def parse_npm(path):
    if not path: return []
    try:
        with open(path) as f: d = json.load(f)
    except Exception: return []
    out = []
    for name, info in d.get("vulnerabilities", {}).items():
        for v in info.get("via", []):
            if isinstance(v, dict):
                out.append((name, v.get("severity","unknown"), v.get("title","")))
    return out

def parse_pip(path):
    if not path: return []
    try:
        with open(path) as f: d = json.load(f)
    except Exception: return []
    return [(x.get("name"), x.get("severity","unknown"), x.get("vulid",""))
            for x in d.get("dependencies",[])]

def parse_dep(path):
    if not path: return []
    try:
        with open(path) as f: d = json.load(f)
    except Exception: return []
    return [(x["name"], x["severity"], x.get("advisory",""))
            for x in d.get("findings",[])]

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--npm"); ap.add_argument("--pip"); ap.add_argument("--dep")
    args = ap.parse_args()
    findings = parse_npm(args.npm) + parse_pip(args.pip) + parse_dep(args.dep)

    high_crit = [f for f in findings if f[1] in ("high","critical","Critical","High")]
    for f in findings:
        print(f"[{f[1].upper()}] {f[0]} — {f[2]}")
    if high_crit:
        print(f"::error::{len(high_crit)} high/critical dependency vulnerabilities.")
        return 1
    return 0

if __name__ == "__main__":
    sys.exit(main())