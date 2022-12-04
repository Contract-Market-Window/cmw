pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/CMW.sol";
import "src/Treasury.sol";
import "src/TreasuryToken.sol";
import "src/Controller.sol";
import "src/FRVault.sol";
import "src/VRVault.sol";
import "src/DebtToken.sol";

// forge test --match-contract TestDeployer -vv
// note:
// no actual tests are meant to be in the TestHelper, only internal functions that actual tests use.

abstract contract TestHelper is Test {
    CMW public cmw;
    Treasury public treasury;
    TreasuryToken public treasuryToken;
    Controller public controller;

    VRVault public vrVault;
    FRVault public frVault;

    DebtToken public vrToken;
    DebtToken public frToken;

    address internal alice = 0x52F93E794a3A939aaa3152d7D31Ed00EFD6e094C;
    address internal bob = 0x082F2A37Bd9b510fC29E4e78dFaCC5d1069569ee;

    bytes32 internal constant OWNER = keccak256(abi.encodePacked("OWNER"));
    bytes32 internal constant MINTER = keccak256(abi.encodePacked("MINTER"));
    bytes32 internal constant PROTOCOL = keccak256(abi.encodePacked("PROTOCOL"));

    //defaults for testing
    uint256 internal DEFAULT_WINDOW_BATCH = 10;
    uint256 internal DEFAULT_WINDOW_LENGTH = 7 weeks;
    uint256 testPrice = 1e10;
    uint256 testInterest = 100;

    function deployController() internal {
        address[] memory owners = new address[](2);
        owners[0] = address(this);
        owners[1] = bob;
        controller = new Controller(owners);
    }

    function deployTreasury() internal {
        deployController();
        treasuryToken = new TreasuryToken("TreasuryToken", "TT", address(controller));
        treasury = new Treasury(address(treasuryToken), address(controller));
    }

    function deployAll() internal {
        deployTreasury();
        cmw = new CMW(address(controller));

        // grant minter role to treasury and vaults 
        controller.grantRole(MINTER, address(treasury));
    }

    function deployVaults() internal {
        deployAll();

        cmw.setInterestRate(testInterest);

        vrToken = new DebtToken(address(controller));
        vrVault = new VRVault(treasuryToken, cmw, vrToken);
        controller.grantRole(PROTOCOL, address(vrVault));
        controller.grantRole(MINTER, address(vrVault));

        frToken = new DebtToken(address(controller));
        frVault = new FRVault(treasuryToken, cmw, frToken);
        controller.grantRole(PROTOCOL, address(frVault));
        controller.grantRole(MINTER, address(frVault));

        treasury.setPrice(testPrice);
        cmw.setVRVault(vrVault);
    }

    // -- LOG DEPLOYED ADDRESSES --
    function logContractAddrs() internal {
        emit log_named_address("TESTER   Contract", address(this));
        emit log_named_address("Treasury Contract", address(treasury));
        emit log_named_address("Token    Contract", address(treasuryToken));
        emit log_named_address("CMW      Contract", address(cmw));
    }

    // -- ADDITIONAL SETUP FUNCTIONS --
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

    function aliceMintsTreasuryTokens() internal {
		vm.startPrank(alice);
		vm.deal(alice, 100 ether);
		// Alice buys 5 ETH worth of Treasury Tokens
		treasury.mint{value: 5e18}();
		vm.stopPrank();
	}
}
