// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "src/bases/Controlled.sol";

contract TreasuryToken is ERC20, Controlled {    
    constructor(string memory _name, string memory _symbol, address _controller) 
    ERC20(_name, _symbol) {
        controller = Controller(_controller);
    }

    function mint(address user, uint256 amount) external onlyMinter {
        _mint(user, amount);
    }

    /// @notice used by protocol contracts (vaults) to transfer tokens from users to the vaults when users deposit
    function transferFromUserToVault(address user, uint256 amount) external onlyProtocol {
        _transfer(user, msg.sender, amount);
    }
}
