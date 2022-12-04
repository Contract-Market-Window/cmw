pragma solidity ^0.8.13;

import "src/TreasuryToken.sol";
import "src/CMW.sol";
import "src/DebtToken.sol";
import "src/helpers/Constants.sol";

/// @notice common vault features:
// on deposit, user sends treasury tokens to vault
// user principal is copied to an erc1155 balance
// user can withdraw principal at any time, burning erc1155 balance
// user can withdraw principal + interest, depending on time elapsed
// interest is always minted

/// @notice vault implementations are responsible for the following:
// keeping track of interest owed to users through _getInterestOwed
// keeping track of whether users' interest is unlocked through _isInterestEligible

abstract contract StakingVault {

    event Deposit(address _user, uint256 _debtTokenId);
    event Withdraw(address _user, uint256 _debtTokenId);

    TreasuryToken public treasuryToken;
    CMW public cmw;
    DebtToken public debtToken;

    constructor(TreasuryToken _treasuryToken, CMW _cmw, DebtToken _debtToken) {
        treasuryToken = _treasuryToken;
        cmw = _cmw;
        debtToken = _debtToken;
    }

    /// @notice transfers treasury tokens from user to vault and mints debt tokens to user
    function _deposit(address _user, uint256 _debtTokenId, uint256 _amount) internal {
        require(_amount > 0, "amount <= 0");
        require(_user != address(0), "null address");
        _transferAndMint(_user, _debtTokenId, _amount);
    }

    function _withdraw(address _user, uint256 _debtTokenId, uint256 _amount, bool _isEarly) internal {
        if(_isEarly) {
            _earlyWithdraw(_user, _debtTokenId, _amount);
        }
        else {
            _timelyWithdraw(_user, _debtTokenId, _amount);
        }
    }

    /// @notice called when a user is attempting to withdraw treasury tokens with interest
    function _timelyWithdraw(address _user, uint256 _debtTokenId, uint256 _principal) internal {
        require(_isInterestEligible(_debtTokenId), "ineligible for interest");
        uint256 maxPrincipal = _getPrincipalOwed(_user, _debtTokenId);
        require(maxPrincipal <= _principal, "insufficient balance");

        uint256 interestOwed = _getInterestOwed(_debtTokenId, _principal);
        _transferAndBurn(_user, _debtTokenId, _principal, interestOwed);
    }

    /// @notice called when a user is withdrawing their principal only
    function _earlyWithdraw(address _user, uint256 _debtTokenId, uint256 _amountToWithdraw) internal {
        uint256 maxToWithdraw = _getPrincipalOwed(_user, _debtTokenId);
        require(maxToWithdraw <= _amountToWithdraw, "insufficient balance");

        _transferAndBurn(_user, _debtTokenId, _amountToWithdraw, 0);
    }

    function _getCurrentRate() internal view returns(uint256 interestRate) {
        return cmw.interestRate();
    }

    function _getPrincipalOwed(address _user, uint256 _debtTokenId) internal view returns(uint256 principalOwed) {
        return debtToken.balanceOf(_user, _debtTokenId);
    }

    /* --------------------------------------------------MUST be overridden in implementation-------------------------------------------------- */

    function _isInterestEligible(uint256 _debtTokenId) internal view virtual returns(bool isInterestEligible){}

    function _getInterestOwed(uint256 _debtTokenId, uint256 _amount) internal view virtual returns(uint256 interestOwed){}

    /* ---------------------------------------------------------------------------------------------------------------------------------------- */

    function _transferAndMint(address _user, uint256 _debtTokenId, uint256 _amount) private {
        treasuryToken.transferFromUserToVault(_user, _amount);
        _mintDebtToken(_user, _debtTokenId, _amount);
    }

    function _transferAndBurn(address _user, uint256 _debtTokenId, uint256 _principal, uint256 _interest) private {
        treasuryToken.transfer(_user, _principal);
        _burnDebtToken(_user, _debtTokenId, _principal);
        if(_interest > 0) treasuryToken.mint(_user, _interest);
    }

    function _mintDebtToken(address _user, uint256 _debtTokenId, uint256 _amountToMint) private {
        debtToken.mint(_user, _debtTokenId, _amountToMint);
    }

    function _burnDebtToken(address _user, uint256 _debtTokenId, uint256 _amountToBurn) private {
        debtToken.burn(_user, _debtTokenId, _amountToBurn);
    }
}