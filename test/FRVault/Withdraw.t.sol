pragma solidity ^0.8.13;

import "test/TestHelper.sol";
// forge test --match-contract FRV2 -vv

contract FRWithdraw is TestHelper {
    
    uint256 debtTokenId;
    uint256 principal;
    uint256 durationId;

    function setUp() public {
        deployVaults();

        createDefaultWindows();
        aliceMintsTreasuryTokens();

        principal = treasuryToken.balanceOf(alice);
        durationId = 0;
        debtTokenId = aliceDepositsIntoFR(principal, durationId);
    }

    function testTimelyWithdraw() public {
        vm.warp(90 days + 1);
        bool isEarly = false;

        aliceWithdrawsFromFR(principal, isEarly, debtTokenId);

        emit log_uint(principal);
        emit log_uint(treasuryToken.balanceOf(alice));
    }

    function testEarlyWithdraw() public {
        vm.warp(90 days);
        bool isEarly = true;

        aliceWithdrawsFromFR(principal, isEarly, debtTokenId);

        emit log_uint(principal);
        emit log_uint(treasuryToken.balanceOf(alice));  
    }
}