#!/usr/bin/env python3
import argparse, json, os, subprocess, sys

SEVERITY_RANK = {"Low": 1, "Medium": 2, "High": 3, "Critical": 4}

def gh_label_exists(pr, label):
    if not pr:
        return False
    r = subprocess.run(
        ["gh", "pr", "view", str(pr), "--json", "labels", "-q",
         f".labels[].name"],
        capture_output=True, text=True)
    return label in r.stdout.split()

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--json", required=True)
    ap.add_argument("--pr", default="0")
    ap.add_argument("--override-label", default="security-override")
    args = ap.parse_args()

    with open(args.json) as f:
        data = json.load(f)

    detectors = data.get("results", {}).get("detectors", [])
    high = [d for d in detectors if d.get("impact") == "High"]
    crit = [d for d in detectors if d.get("impact") == "Critical"]
    med  = [d for d in detectors if d.get("impact") == "Medium"]

    blocked = high + crit
    override = gh_label_exists(args.pr, args.override_label)

    # Emit medium+ markdown for issue creation
    with open("reports/medium_plus_findings.md", "w") as f:
        f.write(f"# Medium+ findings — {os.environ.get('GITHUB_SHA','')[:8]}\n\n")
        for d in med + high + crit:
            f.write(f"## [{d['impact']}] {d['check']}\n")
            f.write(f"- Confidence: {d['confidence']}\n")
            for el in d.get("elements", []):
                f.write(f"- {el.get('type')}: `{el.get('name','')}` "
                        f"@ {el.get('source_mapping',{}).get('filename_relative')}:"
                        f"{el.get('source_mapping',{}).get('lines',[0])[0]}\n")
            f.write(f"\n```\n{d.get('description','')}\n```\n\n")

        # Write output using the new GITHUB_OUTPUT file to fix deprecation warning
    with open(os.environ.get("GITHUB_OUTPUT", "/dev/null"), "a") as f:
        f.write(f"medium_plus_count={len(med)+len(high)+len(crit)}\n")

    if blocked:
        if override:
            print("::warning::High/Critical findings present, but "
                  f"'{args.override_label}' label is set on PR #{args.pr}. "
                  "Pipeline continues — sign-off recorded.")
            return 0
        print(f"::error::Pipeline blocked: {len(blocked)} High/Critical findings.")
        for d in blocked:
            print(f"::error file={d['elements'][0]['source_mapping']['filename_relative']}"
                  f",line={d['elements'][0]['source_mapping']['lines'][0]}"
                  f"::[{d['impact']}] {d['check']} — {d['description']}")
        return 1
    return 0

if __name__ == "__main__":
    sys.exit(main())