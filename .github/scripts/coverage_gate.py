#!/usr/bin/env python3
import argparse, subprocess, sys, re, os

def changed_sol_files(base, head):
    # If there's no base (e.g., first commit on a new branch), get all src/ files
    if not base:
        r = subprocess.run(
            ["git", "ls-files"],
            capture_output=True, text=True, check=True)
        return [f for f in r.stdout.splitlines() if f.startswith("src/") and f.endswith(".sol")]
    
    r = subprocess.run(
        ["git", "diff", "--name-only", f"{base}..{head}"],
        capture_output=True, text=True, check=True)
    return [f for f in r.stdout.splitlines() if f.startswith("src/") and f.endswith(".sol")]

def parse_lcov(path):
    """Return {file: (lines_hit, lines_total, branches_hit, branches_total)}"""
    stats = {}
    cur = None
    
    if not os.path.exists(path):
        print(f"::error::lcov file not found at {path}. Did 'forge coverage' run successfully?")
        sys.exit(1)
        
    with open(path) as f:
        for line in f:
            line = line.strip()
            if line.startswith("SF:"):
                cur = line[3:]
                # Filter out test, script, and lib files directly in Python
                if any(x in cur for x in ['test/', 'script/', 'lib/']):
                    cur = None
                    continue
                stats[cur] = [0, 0, 0, 0]
            elif cur is None:
                continue
            elif line.startswith("DA:"):
                # Line coverage: DA:<line>,<hits>
                _, hits = line[3:].split(",")
                stats[cur][1] += 1
                if int(hits) > 0: 
                    stats[cur][0] += 1
            elif line.startswith("BRDA:"):
                # Branch coverage: BRDA:<line>,<block>,<branch>,<hits>
                _, _, _, hits = line[5:].split(",")
                stats[cur][3] += 1
                if hits != "-" and int(hits) > 0: 
                    stats[cur][2] += 1
    return stats

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--base", required=True)
    ap.add_argument("--head", required=True)
    ap.add_argument("--lcov", required=True)
    ap.add_argument("--threshold", type=float, default=90.0)
    args = ap.parse_args()

    stats = parse_lcov(args.lcov)
    files = changed_sol_files(args.base, args.head)
    
    if not files:
        print("No Solidity source changes in src/ — coverage gate skipped.")
        return 0

    failed = False
    print(f"Checking branch coverage on {len(files)} changed file(s):")
    for f in files:
        # lcov paths are usually repo-relative, but handle absolute paths just in case
        s = stats.get(f) or stats.get(os.path.abspath(f))
        if not s:
            print(f"::warning file={f}::Not found in lcov report; skipping")
            continue
        lh, lt, bh, bt = s
        pct = (100.0 * bh / bt) if bt else 100.0
        status = "OK" if pct >= args.threshold else "FAIL"
        print(f"  [{status}] {f}: branch {bh}/{bt} ({pct:.1f}%), line {lh}/{lt}")
        if pct < args.threshold:
            failed = True

    if failed:
        print(f"::error::Branch coverage below {args.threshold}% on new code.")
        return 1
    return 0

if __name__ == "__main__":
    sys.exit(main())