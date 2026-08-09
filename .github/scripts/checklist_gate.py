#!/usr/bin/env python3
import argparse, re, sys

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--file", required=True)
    ap.add_argument("--require-all-checked", action="store_true")
    args = ap.parse_args()
    with open(args.file) as f: txt = f.read()
    unchecked = re.findall(r"^\s*- \[ \]", txt, flags=re.M)
    if args.require_all_checked and unchecked:
        print(f"::error::{len(unchecked)} unchecked audit checklist items:")
        for line in unchecked: print("  " + line.strip())
        return 1
    print("All audit checklist items checked.")
    return 0

if __name__ == "__main__":
    sys.exit(main())