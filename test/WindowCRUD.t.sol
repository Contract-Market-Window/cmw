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

        vm.expectRevert("unauthorized");
        testSingleCreateWindow();
    }

    function testUnauthorizedCreateWindows() public {
        vm.prank(alice);

        vm.expectRevert("unauthorized");
        testBatchCreateWindows();
    }

    function testBelowMinimumWindow() public {
        //TODO: test creation of below minimum duration window
    }

    function testUpdateWindow() public {
        //TODO: test updating a valid window
    }

    function testUpdateActiveWindow() public {
        //TODO: test updating an active window
    }

    function testUpdateUninitiatedWindow() public {
        //TODO: test a window which has not been set yet. 
    }

    function updateCompressesAdjacentWindow() public {
        //TODO: test updates which cause previous and next windows to be compressed (below minimum duration)
    }
}