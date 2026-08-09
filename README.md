# 🌳 Pachira Aquatica (PACHIRA)

Welcome to the official repository for `Pachira Aquatica`, an ERC-20 token built with Foundry. This project goes beyond a standard token implementation by integrating enterprise-grade security countermeasures and a fully automated, strict CI/CD security pipeline.

## 📖 Overview

The `PachiraAquatica` token features a dynamic minting mechanism where users can purchase tokens using ETH. The conversion rate is determined dynamically using a decentralized Chainlink Oracle.

Because interacting with oracles and native ETH transfers introduces attack vectors, this contract is heavily fortified against the most common smart contract vulnerabilities.

## 🛡️ Security Features

This contract implements the following security countermeasures:

1. **Re-entrancy Attack Prevention:**
   - Uses OpenZeppelin's ReentrancyGuard.
   - The `nonReentrant` modifier is applied to all functions that move ETH or mint tokens (`buyTokens`, `withdrawEth`), preventing malicious contracts from recursively draining the contract balance.

2. **Oracle Manipulation Defense:**
   When fetching the ETH/USD price from the Chainlink Oracle, the contract performs three strict checks:
   - **Validity:** `price > 0`
   - **Staleness:** `answeredInRound >= roundId` (ensures the round is complete)
   - **Timeout:** `block.timestamp - updatedAt <= ORACLE_TIMEOUT` (rejects stale data)

3. **Authentication & Access Control:**
   Uses OpenZeppelin's Ownable.
   Critical functions like `setOracle()` and `withdrawEth()` are restricted to `onlyOwner`.

4. **Integer Overflow/Underflow:**
   - Built with Solidity `^0.8.20`, which has built-in overflow/underflow checks on all arithmetic operations. No external SafeMath libraries are required.

## 🚀 Quick Start

### Prerequisites

Ensure you have the following installed on your machine:

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [Node.js](https://nodejs.org/) (v22+ recommended)
- [Python](https://www.python.org/) (v3.11+ recommended)

1. Clone & Install Dependencies

```bash
git clone https://github.com/gotechworld/pachira-aquatica.git 
cd pachira-aquatica 
```

### Install Foundry dependencies (forge-std, openzeppelin-contracts)

```bash
forge install OpenZeppelin/openzeppelin-contracts
```

2. Configure Remappings 

___

Ensure your `remappings.txt` file in the project root includes OpenZeppelin:
 
```
@openzeppelin/contracts/=lib/openzeppelin-contracts/contracts/
```

3. Build the Contracts
___
Compile the smart contracts:

```bash 
forge build
```

🧪 Testing

This project includes standard unit tests, property-based fuzz tests, and invariant tests to ensure code integrity.

### Run all tests:

```bash 
forge test -vvv
``` 
 

### Run Fuzz Tests specifically:

```bash 
forge test --match-contract Fuzz -vvv
``` 
 

### Run Invariant Tests specifically:

```bash
forge test --match-contract Invariant -vvv
```
 
### Generate Coverage Report:

```bash
forge coverage --report lcov
```

🚢 Deployment to Sepolia Testnet

To deploy the `PachiraAquatica` token to the __Sepolia testnet__, you will need an `RPC URL`, a `funded deployer wallet`, and an `Etherscan API key`.

### Step 1: Get Sepolia ETH

Ensure your deployer wallet has testnet ETH. You can get some from a reputable faucet like [Alchemy Sepolia Faucet](https://www.alchemy.com/faucets/sepolia) or [Google Cloud Web3 Etheurem Sepolia Faucet](https://cloud.google.com/application/web3/faucet/ethereum/sepolia)

### Step 2: Setup Environment Variables

Create a `.env` file in the root of your project (ensure this is in your __.gitignore__):

```bash
SEPOLIA_RPC_URL="https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY"
PRIVATE_KEY="0xYOUR_DEPLOYER_PRIVATE_KEY"
ETHERSCAN_API_KEY="YOUR_ETHERSCAN_API_KEY"
```

Source the variables into your terminal:

```bash 
source .env
```

### Step 3: Run the Deploy Script

The `script/Deploy.s.sol` script is pre-configured to use the official Chainlink ETH/USD Oracle on Sepolia `(0x1b44F3514812d835EB1BDB0acB33d3fA335d5b9D)`.

Run the following command to deploy and verify:

```bash 
forge script script/Deploy.s.sol:DeployScript \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --slow
```


⚙️ CI/CD & Security Pipeline

This repository features a highly strict, automated CI/CD pipeline located at `.github/workflows/security.yml`. It runs on all __Pull Requests__ and __Pushes__.

Also, add the GHA secret `(VCS_TOKEN)` as Repository secret.

___

Pipeline Stages

    1. Lint & Format: Checks formatting (forge fmt) and runs Solhint with strict security rules.
    2. Static Analysis: Runs Slither to detect vulnerabilities. Fails on High/Critical findings. Auto-creates a GitHub Issue for Medium+ findings.
    3. Unit & Invariant Tests: Runs standard tests and enforces 90% branch coverage on newly changed code.
    4. Fuzz Tests: Runs extended Foundry fuzz tests (10,000 runs) to catch edge cases.
    5. Dependency Scan: Scans npm, pip, and Foundry dependencies for known vulnerabilities.
    6. Manual Review Gate: Requires a manual reviewer to check off all items in `.github/testnet-deploy-checklist.md`.
    7. Deployment: If triggered manually or merged to main/develop, deploys to the Sepolia GitHub Environment.


__GitHub Environments Setup__

For the deployment stage to work, you must configure __two environments__ in your GitHub Repository Settings (__Settings > Environments__):

    `sepolia-review-gate`: Add required reviewers (e.g., your dev team).
    `sepolia`: Add the following Environment Secrets:
         `DEPLOYER_KEY` (Your testnet private key)
         `RPC_URL` (Your Sepolia RPC URL)
         `ETHERSCAN_API_KEY` (Your Etherscan API key)




📁 Project Structure

```
pachira-aquatica/
├── .github/
│   ├── scripts/              # Python scripts for CI/CD security gates
│   ├── workflows/
│   │   └── security.yml      # Main CI/CD pipeline file
│   └── testnet-deploy-checklist.md
├── lib/                      # Foundry dependencies (OpenZeppelin, Forge-std)
├── script/
│   └── Deploy.s.sol          # Token deployment script
├── src/
│   └── PachiraAquatica.sol   # Main ERC-20 Token Contract
├── test/
│   └── PachiraAquatica.t.sol # Unit, Fuzz, and Invariant Tests
├── foundry.toml              # Foundry configuration
├── remappings.txt            # Path remappings for dependencies
└── .solhint.json             # Linter configuration

```