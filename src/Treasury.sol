// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "src/CMW.sol";
import "src/TreasuryToken.sol";
import "src/bases/Controlled.sol";

contract Treasury is Controlled {

    TreasuryToken public treasuryToken;
    uint256 public costToMint;

    constructor(address _treasuryToken, address _controller) {
        treasuryToken = TreasuryToken(_treasuryToken);
        controller = Controller(_controller);
    }

    function setPrice(uint256 _costToMint) external onlyOwner {
        costToMint = _costToMint;
    }

    function mint() payable external {       
        require(msg.value > 0, "No funds were received");
        uint256 amount =  msg.value / costToMint;

        // mint to user
        treasuryToken.mint(msg.sender, amount);
    }


    receive() external payable {}

    fallback() external payable {}
}
