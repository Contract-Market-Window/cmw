pragma solidity ^0.8.13;

import "test/TestHelper.sol";
// forge test --match-contract FRV2 -vv

contract FRTest is TestHelper {
    
    uint256 debtTokenId;

    enum DurationId { MONTH3, MONTH6, MONTH12 }

    function setUp() public {
        deployVaults();

        createDefaultWindows();
        aliceMintsTreasuryTokens();
    }

    function testDeposit() public {
        uint256 amountToDeposit = treasuryToken.balanceOf(alice);
        uint256 durationId = 2;
        aliceDepositsIntoFRV2(amountToDeposit, durationId);
    }

    function testWithdraw() public {
        uint256 amountToWithdraw = treasuryToken.balanceOf(alice);
        testDeposit();
        vm.warp(365 days + 1);
        aliceWithdrawsFromFRV2(amountToWithdraw, false);
        //emit log_uint(token.balanceOf(alice));
    }

    function testDepositAndWithdraw() public {
        uint principal = treasuryToken.balanceOf(alice);
        uint durationId = 0;

        aliceDepositsIntoFRV2(principal, durationId);

        vm.warp(90 days + 1);
        bool isEarly = false;

        aliceWithdrawsFromFRV2(principal, isEarly);

        emit log_uint(principal);
        emit log_uint(treasuryToken.balanceOf(alice));
    }

    function testEarlyWithdraw() public {
        uint principal = treasuryToken.balanceOf(alice);
        uint durationId = 0;

        aliceDepositsIntoFRV2(principal, durationId);

        vm.warp(90 days);
        bool isEarly = true;

        aliceWithdrawsFromFRV2(principal, isEarly);

        emit log_uint(principal);
        emit log_uint(treasuryToken.balanceOf(alice));  
    }

    function aliceDepositsIntoFRV2(uint256 _amount, uint256 _durationId) internal {
        vm.prank(alice);
        debtTokenId = frVault.deposit(_amount, _durationId);
    }

    function aliceWithdrawsFromFRV2(uint256 _amount, bool _isEarly) internal {
        vm.prank(alice);
        frVault.withdraw(_amount, debtTokenId, _isEarly);
    }
}