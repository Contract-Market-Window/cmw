pragma solidity ^0.8.13;
import "forge-std/Test.sol";
import "src/CMW.sol";
//import..

abstract contract TestHelper is Test {
    CMW public cmw;
    address internal alice = 0x52F93E794a3A939aaa3152d7D31Ed00EFD6e094C;
    address internal bob = 0x082F2A37Bd9b510fC29E4e78dFaCC5d1069569ee;

    function deployCMW() internal {
        address[] memory owners = new address[](1);
        owners[0] = address(this);
        cmw = new CMW(address(this));
    }
}
