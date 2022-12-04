// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "src/Controller.sol";

abstract contract Controlled {
    /// @dev Controller responsible for access control
    Controller public controller;

    modifier onlyOwner {
        controller.isOwner(msg.sender);
        _;
    }

    modifier onlyProtocol {
        controller.isProtocol(msg.sender);
        _;
    }

    modifier onlyMinter {
        controller.isMinter(msg.sender);
        _;
    }
}