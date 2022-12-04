pragma solidity ^0.8.13;

import "src/bases/InterestAccumulator.sol";

/// @notice debtTokenId is  uint8 cmwId packed with uint248 multiplier

contract VRVault is InterestAccumulator, Controlled {

    enum CMWId {CMW1, CMW2, CMW3}

    /// @dev basis points to be multiply interest by (e.g. 10000 means twice the interest will be paid)
    uint16[3] public premiums;

    constructor(TreasuryToken _treasuryToken, CMW _cmw, DebtToken _debtToken)
        StakingVault(_treasuryToken, _cmw, _debtToken) {
        hourlyRateX128 = _getHourlyRate(_getCurrentRate());
    }

    function deposit(uint256 _amount, uint256 _cmwId) external returns(uint256 debtTokenId) {
        require(cmw.checkCmwStage(_cmwId), "inactive window");
        _updateMultipliers();
        debtTokenId = _getDebtTokenId(_cmwId);
        _deposit(msg.sender, debtTokenId, _amount);
    }

    function withdraw(uint256 _amount, uint256 _debtTokenId, bool _isEarly) external {
        _updateMultipliers();
        _withdraw(msg.sender, _debtTokenId, _amount, _isEarly);
    }

    function setPremium(CMWId _id, uint16 _premium) external onlyOwner {
        premiums[uint(_id)] = _premium;
    }

    function onInterestRateChange(uint256 _newAnnualRate) external onlyProtocol {
        _updateMultipliers();
        _onInterestRateChange(_newAnnualRate);
    }

    /*------------------------------------------------------OVERRIDES--------------------------------------------------------*/

    function _isInterestEligible(uint256 _debtTokenId) internal view override returns(bool isInterestEligible) {
        //check if multiplier is smaller than active window multiplier
        (uint8 cmwId, uint248 userMultiplier) = _getDebtTokenIdInfo(_debtTokenId);

        uint256 activeMult = _getActiveWindowMultiplier();

        // handles the pre-window cmw1 case. Adds 96 to be sure no pre-window deposits become unlocked.
        if(cmwId == uint8(CMWId.CMW1)) {
            return _add96HoursToMultiplier(userMultiplier) < activeMult;
        }

        return userMultiplier < activeMult;
    }

    function _getInterestOwed(uint256 _debtTokenId, uint256 _amount) internal view override returns(uint256 interestOwed) {
        (uint8 cmwId, uint248 userMultiplier) = _getDebtTokenIdInfo(_debtTokenId);
        uint256 activeWindowMultiplier = _getActiveWindowMultiplier();
        uint256 owedRate = activeWindowMultiplier - userMultiplier;

        uint256 rawOwedInterest = ((_amount * owedRate) >> Constants.HOURLY_RATE_OFFSET) / Constants.BASIS_POINTS;
        uint256 premium = (premiums[cmwId] * rawOwedInterest) / Constants.BASIS_POINTS;

        return rawOwedInterest + premium;
    }

    /*-----------------------------------------------------------------------------------------------------------------------*/

    /// @dev left 8 bits of debtTokenId is the cmwId, right x bits is the multiplier at time of deposit
    function _getDebtTokenId(uint256 _cmwId) internal view returns(uint256 debtTokenId) {
        return ((_cmwId) << Constants.VR_DEBTID_OFFSET) | _getCurrentMultiplier();
    }

    function _getDebtTokenIdInfo(uint256 _debtTokenId) internal pure returns(uint8 cmwId, uint248 multiplier) {
        cmwId = uint8(_debtTokenId >> Constants.VR_DEBTID_OFFSET);
        multiplier = uint248(_debtTokenId);
    }
}