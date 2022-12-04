pragma solidity ^0.8.13;

import "test/TestHelper.sol";


contract InterestRate is TestHelper {

    function setUp() public {
        deployAll();
    }

    function testSetInterestRate() public {
		cmw.setInterestRate(1000);
		assertEq(cmw.interestRate(), 1000);
	}

	function testUnauthorizedSetInterestRate() public {
		vm.startPrank(alice);
		vm.expectRevert();
		cmw.setInterestRate(10);
		vm.stopPrank();
	}

    function testUntimelySetInterestRate() public {
		vm.warp(24 hours + 1);
        vm.expectRevert("Rate edit time expired");
        cmw.setInterestRate(1000);
    }
}