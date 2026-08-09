// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {PachiraAquatica} from "../src/PachiraAquatica.sol";

contract DeployScript is Script {
    // Official Chainlink ETH/USD Price Feed on Sepolia Testnet (Fixed checksum)
    address constant SEPOLIA_ETH_USD_ORACLE = 0x1b44F3514812D835eb1bDb0acb33d3fa335d5b9d;

    function run() public {
        vm.startBroadcast();

        // Deploy the token with the Sepolia Oracle address
        PachiraAquatica token = new PachiraAquatica(SEPOLIA_ETH_USD_ORACLE);

        vm.stopBroadcast();

        console.log("Pachira Aquatica deployed to:", address(token));
        console.log("Using Oracle at:", SEPOLIA_ETH_USD_ORACLE);
    }
}
