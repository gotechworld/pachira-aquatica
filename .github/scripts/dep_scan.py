#!/usr/bin/env python3
import argparse, json, re, os

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--foundry-foundry-toml", default="foundry.toml")
    ap.add_argument("--remappings", default="remappings.txt")
    ap.add_argument("--out", required=True)
    args = ap.parse_args()

    findings = []

    # Check solc version in foundry.toml
    solc_version = None
    if os.path.exists(args.foundry_foundry_toml):
        with open(args.foundry_foundry_toml) as f:
            content = f.read()
            # Looks for solc = "0.8.20" or solc_version = "0.8.20"
            match = re.search(r'solc(?:_version)?\s*=\s*"([^"]+)"', content)
            if match:
                solc_version = match.group(1)

    if solc_version:
        # Example check: versions < 0.8.20 are not recommended due to known bugs
        if solc_version.startswith("0.8."):
            try:
                minor = int(solc_version.split(".")[2])
                if minor < 20:
                    findings.append({
                        "name": "solc",
                        "severity": "medium",
                        "advisory": f"solc version {solc_version} is older than 0.8.20, which may contain known bugs."
                    })
            except Exception:
                pass

    # Write the JSON report expected by vuln_gate.py
    os.makedirs(os.path.dirname(args.out), exist_ok=True)
    with open(args.out, "w") as f:
        json.dump({"findings": findings}, f, indent=2)
    
    print(f"Dependency scan complete. {len(findings)} finding(s) written to {args.out}")

if __name__ == "__main__":
    main()