// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library Constants {
    uint256 internal constant BASIS_POINTS = 10_000;
    uint256 internal constant PRECISION = 1e10; //TODO sanity check against max uint256
    uint256 internal constant HOURS_IN_YEAR = 8760;
    uint256 internal constant HOURLY_RATE_OFFSET = 128;
    uint256 internal constant FR_DEBTID_OFFSET = 128;
    uint256 internal constant VR_DEBTID_OFFSET = 128;
}