pragma solidity ^0.8.13;

import "test/TestHelper.sol";
// forge test --match-contract VRTest -vv

contract VRTest is TestHelper {

    uint256 debtTokenId;

    function setUp() public {
        deployVaults();

        createDefaultWindows();
        aliceMintsTreasuryTokens();
    }
    
    function testDeposit() public {
        uint256 amountToDeposit = treasuryToken.balanceOf(alice);
        uint256 cmwId = 0;
        aliceDepositsIntoVR(amountToDeposit, cmwId);
    }

    function testWithdraw() public {
        uint256 amountToWithdraw = treasuryToken.balanceOf(alice);
        testDeposit();
        InterestAccumulator.InterestMultiplier memory last;
        (last.windowId, last.multiplier) = vrVault.lastMultiplier();
        InterestAccumulator.InterestMultiplier memory current;
        (current.windowId, current.multiplier) = vrVault.currentMultiplier();
        vm.warp(365 days + 1);
        aliceWithdrawsFromVR(amountToWithdraw, false);
        emit log_uint(treasuryToken.balanceOf(alice));
    }

    function aliceDepositsIntoVR(uint256 _amount, uint256 _durationId) internal {
        vm.prank(alice);
        debtTokenId = vrVault.deposit(_amount, _durationId);
    }

    function aliceWithdrawsFromVR(uint256 _amount, bool _isEarly) internal {
        vm.prank(alice);
        vrVault.withdraw(_amount, debtTokenId, _isEarly);
    }

}