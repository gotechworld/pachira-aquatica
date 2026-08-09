// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Chainlink-style Aggregator Interface
interface IPriceFeed {
    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

contract PachiraAquatica is ERC20, Ownable, ReentrancyGuard {
    IPriceFeed public priceFeed;

    // Security: Timeout to prevent stale oracle data manipulation
    uint256 public constant ORACLE_TIMEOUT = 1 hours;

    event TokensBought(address indexed buyer, uint256 ethSent, uint256 tokensMinted);
    event OracleUpdated(address indexed newOracle);

    constructor(address _priceFeed) ERC20("Pachira Aquatica", "PACHIRA") Ownable(msg.sender) {
        require(_priceFeed != address(0), "Invalid oracle address");
        priceFeed = IPriceFeed(_priceFeed);
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }

    /**
     * @dev Authentication: Only the owner can update the oracle.
     */
    function setOracle(address _priceFeed) external onlyOwner {
        require(_priceFeed != address(0), "Invalid oracle address");
        priceFeed = IPriceFeed(_priceFeed);
        emit OracleUpdated(_priceFeed);
    }

    /**
     * @dev Oracle Manipulation Defense: Fetches price and checks for staleness or invalid data.
     */
    function getLatestPrice() public view returns (int256) {
        (uint80 roundId, int256 price,, uint256 updatedAt, uint80 answeredInRound) = priceFeed.latestRoundData();

        // Check 1: Price must be greater than 0
        require(price > 0, "Oracle: Invalid price");
        // Check 2: Round must be complete
        require(answeredInRound >= roundId, "Oracle: Stale round");

        // Note: Validators can manipulate block.timestamp by ~15s, but this is negligible against a 1-hour timeout.
        // forge-lint: disable-next-line(block-timestamp)
        require(block.timestamp - updatedAt <= ORACLE_TIMEOUT, "Oracle: Timeout");

        return price;
    }

    /**
     * @dev Buy tokens with ETH. Protected against Re-entrancy and Oracle Manipulation.
     */
    function buyTokens() external payable nonReentrant {
        require(msg.value > 0, "Must send ETH");

        int256 ethPrice = getLatestPrice();

        // Note: Casting to uint256 is safe because getLatestPrice() requires price > 0.
        // forge-lint: disable-next-line(unsafe-typecast)
        uint256 tokensToMint = (msg.value * uint256(ethPrice)) / 1e8;

        require(tokensToMint > 0, "Insufficient ETH sent");

        _mint(msg.sender, tokensToMint);
        emit TokensBought(msg.sender, msg.value, tokensToMint);
    }

    /**
     * @dev Authentication & Re-entrancy: Only owner can withdraw, protected against re-entrancy.
     */
    function withdrawEth() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");

        (bool success,) = payable(owner()).call{value: balance}("");
        require(success, "Withdraw failed");
    }
}
