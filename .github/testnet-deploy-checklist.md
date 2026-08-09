# Sepolia Deployment Checklist

Reviewer must check every item before approving the sepolia-review-gate environment deployment.

     [ ] Slither clean (or each finding has a written rationale)
     [ ] No outstanding High/Critical findings (or signed waiver)
     [ ] Branch coverage ≥ 90% on changed code
     [ ] Fuzz tests: 10,000+ runs, no invariant violations
     [ ] Dependency scan: no High/Critical vulnerabilities
     [ ] Deployer wallet has sufficient Sepolia ETH
     [ ] RPC URL is pointing to Sepolia (Chain ID 11155111)
     [ ] No mainnet keys or configurations present in the script
     [ ] Deploy script parameters (initial owners, admins) match testnet requirements
     [ ] Named reviewer 1: ____________  Date: ____________
