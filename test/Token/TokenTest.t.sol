pragma solidity ^0.8.13;
import 'test/TestHelper.sol';

// forge test --match-contract TokenTest -vv

contract TokenTest is TestHelper {

	function setUp() public {
		deployAll();
		treasury.setPrice(testPrice);
		hoax(alice, 100 ether);
	}

	function testAliceBal() public {
		assertEq(alice.balance, 100e18);
	}

	function testUserMintWithoutValue() public {
		vm.startPrank(alice);
		vm.expectRevert(bytes("No funds were received"));
		treasury.mint();
		vm.stopPrank();
	}

	function testSetPrice() public {
		assertEq(treasury.costToMint(), testPrice);
	}

	function testUserMintWithValue() public {
		vm.startPrank(alice);
		treasury.mint{value: testPrice}();
		vm.stopPrank();
	}
}