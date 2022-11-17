pragma solidity ^0.8.13;

import "./TestHelper.sol";

contract WindowCRUD is TestHelper {

    function setUp() public {
        deployCMW();
    }

    function testSingleCreateWindow() public {
        cmw.createWindow(block.timestamp);
    }

    function testBatchCreateWindows() public {

        uint numberOfWindows = 20;
        uint[] memory startTimes = new uint[](numberOfWindows);
        

        for(uint i = 0; i < numberOfWindows; i++ ) {
            startTimes[i] = block.timestamp + ((6 weeks) * i);
        }
        cmw.batchCreateWindows(startTimes);
    }

    function testUnauthorizedCreateWindow() public {
        vm.prank(alice);

        vm.expectRevert();
        testSingleCreateWindow();
    }

    function testUnauthorizedCreateWindows() public {
        vm.prank(alice);

        vm.expectRevert();
        testBatchCreateWindows();
    }

    function testBelowMinimumWindow() public {
        cmw.createWindow(block.timestamp);
        vm.expectRevert();
        cmw.createWindow(block.timestamp + 20 hours);
    }

    function testUpdateWindow() public {
        createDefaultWindows();

        cmw.updateWindow(DEFAULT_WINDOW_BATCH, cmw.readWindowStart(DEFAULT_WINDOW_BATCH) + 1 weeks);
    }

    function testUpdateActiveWindow() public {
        createDefaultWindows();

        uint currId = cmw.checkCurrWindow();

        vm.expectRevert("Current or next windows are not updatable");
        cmw.updateWindow(currId, block.timestamp + 1 weeks);
        vm.expectRevert("Current or next windows are not updatable");
        cmw.updateWindow(currId + 1, block.timestamp + 3 weeks);
    }

    function testUpdateUninitiatedWindow() public {
        vm.expectRevert("Id out of bounds");
        cmw.updateWindow(3, block.timestamp);
    }

    function testUpdateCompressesAdjacentWindow() public {
        createDefaultWindows();

        uint targetId = 6;
        uint targetStart = cmw.readWindowStart(targetId);

        vm.expectRevert("Previous window min interval error");
        cmw.updateWindow(targetId, targetStart - 6 weeks - 1);

    }
}