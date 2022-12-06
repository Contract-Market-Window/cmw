pragma solidity ^0.8.13;

import "test/TestHelper.sol";
// forge test --match-contract VRWithdraw -vv

contract VRWithdraw is TestHelper {

    uint256 debtTokenId;
    uint256 amountToWithdraw;

    function setUp() public {
        deployVaults();

        createDefaultWindows();
        aliceMintsTreasuryTokens();

        uint256 amountToDeposit = treasuryToken.balanceOf(alice);
        uint256 cmwId = 0;
        debtTokenId = aliceDepositsIntoVR(amountToDeposit, cmwId);
        amountToWithdraw = amountToDeposit;
    }

    function testWithdraw() public {
        InterestAccumulator.InterestMultiplier memory last;
        (last.windowId, last.multiplier) = vrVault.lastMultiplier();
        InterestAccumulator.InterestMultiplier memory current;
        (current.windowId, current.multiplier) = vrVault.currentMultiplier();
        vm.warp(365 days + 1);
        aliceWithdrawsFromVR(amountToWithdraw, false, debtTokenId);
        emit log_uint(treasuryToken.balanceOf(alice));
    }

}