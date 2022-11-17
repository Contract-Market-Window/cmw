pragma solidity ^0.8.13;

import "./TestHelper.sol";

contract ActiveCMW is TestHelper {

    function setUp() public {
        deployCMW();
        createDefaultWindows();
    }

    function testCMW1() public {
        // [ 48 hours before, 48 hours after ]

        assertEq(cmw.checkCmwStage(1), true);
        assertEq(cmw.checkCmwStage(2), false);
        assertEq(cmw.checkCmwStage(3), false);

        vm.warp(48 hours + 1);
        assertEq(cmw.checkCmwStage(1), false);


        vm.warp(cmw.readWindowStart(1) - 49 hours);
        assertEq(cmw.checkCmwStage(1), false);

        vm.warp(cmw.readWindowStart(1) - 48 hours);
        assertEq(cmw.checkCmwStage(1), true);
    }

    function testCMW2() public {
        // ( 48 hours after, halfway through window duration ]
        vm.warp(48 hours + 1);
        assertEq(cmw.checkCmwStage(1), false);
        assertEq(cmw.checkCmwStage(2), true);
        assertEq(cmw.checkCmwStage(3), false);
    }

    function testCMW3() public {
        // ( halfway, end ]

        uint currId = cmw.checkCurrWindow();

        uint start = cmw.readWindowStart(currId);
        uint end = cmw.readWindowStart(currId + 1);
        uint halfway = (end - start) / 2;

        vm.warp(halfway + 1);
        assertEq(cmw.checkCmwStage(1), false);
        assertEq(cmw.checkCmwStage(2), false);
        assertEq(cmw.checkCmwStage(3), true);
    }

}