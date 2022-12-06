pragma solidity ^0.8.13;

import "test/TestHelper.sol";
// forge test --match-contract AdHoc -vv

contract AdHoc is TestHelper {

    uint256 debtTokenId;

    function setUp() public {
        deployAll();
    }

    function testThing() public {
        emit log_uint(treasuryToken.decimals());
    }

}