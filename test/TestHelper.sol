pragma solidity ^0.8.13;
import "forge-std/Test.sol";
import "src/CMW.sol";
import "src/Controller.sol";
//import..

abstract contract TestHelper is Test {
    CMW public cmw;
    address internal alice = 0x52F93E794a3A939aaa3152d7D31Ed00EFD6e094C;
    address internal bob = 0x082F2A37Bd9b510fC29E4e78dFaCC5d1069569ee;

    //defaults for testing
    uint256 internal DEFAULT_WINDOW_BATCH = 10;
    uint256 internal DEFAULT_WINDOW_LENGTH = 7 weeks; 

    function deployCMW() internal {
        address[] memory owners = new address[](1);
        owners[0] = address(this);
        Controller controller = new Controller(owners);
        cmw = new CMW(address(controller));
    }

    function createDefaultWindows() internal {
        uint256 currentTime = block.timestamp;
		uint256 length = DEFAULT_WINDOW_BATCH;
		uint256[] memory startTimes = new uint256[](length);

		for(uint256 i = 0; i < length; i++ ) {
			currentTime += DEFAULT_WINDOW_LENGTH;
			startTimes[i] = currentTime;
		}

		cmw.batchCreateWindows(startTimes);
    }

}
