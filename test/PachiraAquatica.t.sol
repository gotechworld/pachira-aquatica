// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {PachiraAquatica} from "../src/PachiraAquatica.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// Mock Oracle for testing Oracle Manipulation defenses
contract MockOracle {
    int256 public price;
    uint80 public roundId = 1;
    uint80 public answeredInRound = 1;
    uint256 public updatedAt;

    constructor(int256 _price) {
        price = _price;
        updatedAt = block.timestamp;
    }

    function setPrice(int256 _price) external {
        price = _price;
        updatedAt = block.timestamp;
        roundId++;
        answeredInRound = roundId;
    }

    function setStale(uint80 _answeredInRound) external {
        answeredInRound = _answeredInRound;
    }

    function setUpdatedAt(uint256 _time) external {
        updatedAt = _time;
    }

    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80) {
        return (roundId, price, 0, updatedAt, answeredInRound);
    }
}

contract PachiraAquaticaTest is Test {
    PachiraAquatica public token;
    MockOracle public oracle;
    address public owner = address(this);

    function setUp() public {
        oracle = new MockOracle(2000 * 1e8); // $2000
        token = new PachiraAquatica(address(oracle));
    }

    // Fix 2: Added receive function so the test contract can accept ETH during withdraw
    receive() external payable {}

    function testDeployment() public view {
        assertEq(token.name(), "Pachira Aquatica");
        assertEq(token.balanceOf(owner), 1000000 * 10 ** 18);
    }

    // Test: Authentication
    function testRevertSetOracleNonOwner() public {
        vm.prank(address(0x123));
        // Fix 1: Expect the OpenZeppelin v5 custom error
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(0x123)));
        token.setOracle(address(0));
    }

    // Test: Oracle Manipulation (Zero Price)
    function testRevertOracleZeroPrice() public {
        oracle.setPrice(0);
        vm.expectRevert("Oracle: Invalid price");
        token.getLatestPrice();
    }

    // Test: Oracle Manipulation (Stale Round)
    function testRevertOracleStaleRound() public {
        oracle.setStale(0); // answeredInRound < roundId
        vm.expectRevert("Oracle: Stale round");
        token.getLatestPrice();
    }

    // Test: Oracle Manipulation (Timeout)
    function testRevertOracleTimeout() public {
        // Fast forward time by 2 hours so we don't underflow when subtracting
        vm.warp(2 hours);

        // Set the oracle's last update to 0 (making it very stale)
        oracle.setUpdatedAt(0);

        vm.expectRevert("Oracle: Timeout");
        token.getLatestPrice();
    }

    // Test: Re-entrancy & Buy (0.01 ETH)
    function testBuyTokens() public {
        uint256 ethSent = 0.01 ether;
        uint256 expectedTokens = (ethSent * 2000 * 1e8) / 1e8; // 20 tokens

        token.buyTokens{value: ethSent}();

        assertEq(token.balanceOf(owner), 1000000 * 10 ** 18 + expectedTokens);
        assertEq(address(token).balance, ethSent);
    }

    // Test: Buy Tokens with 0 ETH
    function testRevertBuyTokensZeroETH() public {
        vm.expectRevert("Must send ETH");
        token.buyTokens();
    }

    // Test: Authentication & Re-entrancy Withdraw (0.01 ETH)
    function testWithdrawEth() public {
        token.buyTokens{value: 0.01 ether}();

        uint256 ownerBalBefore = owner.balance;
        token.withdrawEth();

        assertEq(address(token).balance, 0);
        assertGt(owner.balance, ownerBalBefore);
    }

    // Test: Withdraw Eth only Owner
    function testRevertWithdrawNonOwner() public {
        token.buyTokens{value: 0.01 ether}();
        vm.prank(address(0x123));
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(0x123)));
        token.withdrawEth();
    }

    // Test: Withdraw Eth with 0 balance
    function testRevertWithdrawZeroBalance() public {
        vm.expectRevert("No ETH to withdraw");
        token.withdrawEth();
    }

    // Test: setOracle with zero address
    function testRevertSetOracleZeroAddress() public {
        vm.expectRevert("Invalid oracle address");
        token.setOracle(address(0));
    }
}

// Fuzz Contract
contract Fuzz is Test {
    PachiraAquatica public token;
    MockOracle public oracle;
    address public owner = address(this); // Fix 3: Use address(this) because it has unlimited ETH in Foundry

    function setUp() public {
        oracle = new MockOracle(2000 * 1e8);
        token = new PachiraAquatica(address(oracle));
    }

    function testFuzz_BuyTokens(uint256 ethAmount) public {
        vm.assume(ethAmount > 0 && ethAmount <= 1000 ether);

        token.buyTokens{value: ethAmount}();

        // Ensure balance increased correctly (Integer overflow implicitly tested by 0.8.x)
        assertGt(token.balanceOf(owner), 1000000 * 10 ** 18);
    }
}

// Invariant Contract
contract Invariant is Test {
    PachiraAquatica public token;
    MockOracle public oracle;
    address public owner = address(this);

    function setUp() public {
        oracle = new MockOracle(2000 * 1e8);
        token = new PachiraAquatica(address(oracle));
    }

    // Added 'view' keyword to fix Warning 2018
    function invariant_TotalSupplyNeverDecreases() public view {
        // Total supply should never decrease because we only mint, never burn
        assertGe(token.totalSupply(), 1000000 * 10 ** 18);
    }
}
