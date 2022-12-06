pragma solidity ^0.8.13;

import "test/TestHelper.sol";
// forge test --match-contract VRDeposit -vv

contract VRDeposit is TestHelper {

    uint256 debtTokenId;
    uint256 amountToDeposit;

    function setUp() public {
        deployVaults();

        createDefaultWindows();
        aliceMintsTreasuryTokens();
        amountToDeposit = treasuryToken.balanceOf(alice);
    }
    
    function testDeposit() public {
        uint256 cmwId = 0;
        aliceDepositsIntoVR(amountToDeposit, cmwId);
    }

    function testLockedCmwDeposit() public {
        uint256 cmwId = 2;
        vm.expectRevert(); //inactive window
        aliceDepositsIntoVR(amountToDeposit, cmwId);
    }

    function testInvalidCmwIdDeposit() public {
        uint256 cmwId = 5;
        vm.expectRevert(); //CMW out of bounds
        aliceDepositsIntoVR(amountToDeposit, cmwId);
    }

}