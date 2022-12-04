pragma solidity ^0.8.13;

import "lib/openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import "src/bases/Controlled.sol";

contract DebtToken is ERC1155, Controlled {
    constructor(address _controller) ERC1155("") {
        controller = Controller(_controller);
    }

    function mint(address _to, uint256 _id, uint256 _amount) external onlyProtocol {
        _mint(_to, _id, _amount, "");
    }

    function burn(address _to, uint256 _id, uint256 _amount) external onlyProtocol {
        _burn(_to, _id, _amount);
    }
}