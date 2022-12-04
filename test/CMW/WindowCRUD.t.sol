pragma solidity ^0.8.13;

import "test/TestHelper.sol";

contract WindowCRUD is TestHelper {

    function setUp() public {
        deployAll();
    }

    function testSingleCreateWindow() public {
		vm.warp(100); // warp the block.timestamp forward to 100
		uint256 currentTime = block.timestamp;
		cmw.createWindow(currentTime);
		cmw.createWindow(currentTime + 7 weeks);
		assertEq(cmw.readWindowStart(2), 4233700);

		uint256[] memory windows = cmw.readWindowStarts();
		uint256 window0 = windows[0]; // ID 0 = 0 (it does not exist)
		uint256 window1 = windows[1]; // ID 1 = 100
		uint256 window2 = windows[2]; // ID 2 = (100 + 7 weeks)
		uint256 window3 = windows[3]; // ID 3 = (last + 6 weeks) (auto-generated)
		assertEq(windows.length, 4);

		emit log_named_uint("TimeStamp", currentTime);
		emit log_named_uint("window  Zero",window0);
		emit log_named_uint("window   One",window1);
		emit log_named_uint("window   Two",window2);
		emit log_named_uint("window Three",window3);
	}

	function testBatchCreateWindows() public {
		vm.warp(100);
		uint256 currentTime = block.timestamp;
		uint256 length = 10;
		uint256[] memory startTimes = new uint256[](length);

		for(uint256 i = 0; i < length; i++ ) {
			currentTime += 7 weeks;
			startTimes[i] = currentTime;
		}

		cmw.batchCreateWindows(startTimes);
		uint256[] memory windows = cmw.readWindowStarts();
	
		assertEq(windows.length, startTimes.length + 2);
		// windows has 2 extra slots: 0 ID (non-existent), auto-generated ID (end-time for last)
		emit log_named_uint("startTimes   Length", startTimes.length);
		emit log_named_uint("windowStarts Length", windows.length);
	}

	function testUnauthorizedCreateWindow() public {
		vm.warp(100);
		vm.prank(alice);
		vm.expectRevert();
		cmw.createWindow(block.timestamp);
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