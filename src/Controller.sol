pragma solidity ^0.8.13;

import "lib/openzeppelin-contracts/contracts/access/AccessControl.sol";

contract Controller is AccessControl {

    bytes32 private constant OWNER = keccak256(abi.encodePacked("OWNER"));
    bytes32 private constant MINTER = keccak256(abi.encodePacked("MINTER"));
    bytes32 private constant PROTOCOL = keccak256(abi.encodePacked("PROTOCOL"));


    constructor(address[] memory _owners) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER, _treasury);
        for (uint256 i; i < _owners.length; i++) {
            _grantRole(OWNER, _owners[i]);
        }
    }

    function grantMinterToTreasury(address _treasury) onlyRole(OWNER) {
        _grantRole(MINTER, _treasury);
    }

    function isOwner(address sender) external view {
        _checkRole(OWNER, sender);
    }

    function isMinter(address sender) external view {
        _checkRole(MINTER, sender);
    }

    function isProtocol(address sender) external view {
        _checkRole(PROTOCOL, sender);
    }
}