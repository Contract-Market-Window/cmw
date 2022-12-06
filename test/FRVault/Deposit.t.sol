pragma solidity ^0.8.13;

import "test/TestHelper.sol";
// forge test --match-contract FRV2 -vv

contract FRDeposit is TestHelper {
    
    uint256 debtTokenId;

    function setUp() public {
        deployVaults();

        createDefaultWindows();
        aliceMintsTreasuryTokens();
    }

    function testWrongIdDeposit() public {
        uint256 amountToDeposit = treasuryToken.balanceOf(alice);
        uint256 durationId = 5;
        vm.expectRevert();
        aliceDepositsIntoFR(amountToDeposit, durationId);
    }

    function testDeposit() public {
        uint256 amountToDeposit = treasuryToken.balanceOf(alice);
        uint256 durationId = 2;
        aliceDepositsIntoFR(amountToDeposit, durationId);
    }
}