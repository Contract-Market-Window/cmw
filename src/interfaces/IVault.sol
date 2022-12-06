// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IVault {

    /// @notice external function VR and FR vaults wrap around the internal _deposit function from StakingVault
    /// @dev name of the _initialId param is different in each vault
    function deposit(uint256 _amount, uint256 _initialId) external returns(uint256 debtTokenId);

    /// @notice external function VR and FR vaults wrap around the internal _withdraw function from StakingVault
    function withdraw(uint256 _amount, uint256 _debtTokenId, bool _isEarly) external;
}