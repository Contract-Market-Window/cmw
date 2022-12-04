pragma solidity ^0.8.13;

import "src/bases/StakingVault.sol";
import "src/DebtToken.sol";

contract FRVault is StakingVault {

    enum DurationId { MONTH3, MONTH6, MONTH12 }

    uint[3] public durations = [ 90 days, 180 days, 365 days];

    /// @dev timestamp => interest_rate
    mapping(uint256 => uint256) recordedInterestRates;

    constructor(TreasuryToken _treasuryToken, CMW _cmw, DebtToken _debtToken)
        StakingVault(_treasuryToken, _cmw, _debtToken) {}

    function deposit(uint256 _amount, uint256 _durationId) external returns(uint256 debtTokenId) {
        require(_isValidDurationId(_durationId), "invalid id");
        debtTokenId = _getDebtTokenId(_durationId);
        recordedInterestRates[block.timestamp] = _getCurrentRate();
        _deposit(msg.sender, debtTokenId, _amount);
    }

    function withdraw(uint256 _amount, uint256 _debtTokenId, bool _isEarly) external {
        _withdraw(msg.sender, _debtTokenId, _amount, _isEarly);
    }

    /*------------------------------------------------------OVERRIDES--------------------------------------------------------*/

    function _isInterestEligible(uint256 _debtTokenId) internal view override returns(bool isInterestEligible) {
        (uint128 durationId, uint128 timestamp) = _getDebtTokenIdInfo(_debtTokenId);
        uint256 duration = durations[durationId];
        return block.timestamp >= timestamp + duration;
    }

    function _getInterestOwed(uint256 _debtTokenId, uint256 _amount) internal view override returns(uint256 interestOwed) {
        (uint128 durationId, uint128 timestamp) = _getDebtTokenIdInfo(_debtTokenId);
        uint256 duration = durations[durationId];
        uint256 annualRate = recordedInterestRates[timestamp];
        return (_amount * annualRate * duration) / (365 days * Constants.BASIS_POINTS);
    }

    /*-----------------------------------------------------------------------------------------------------------------------*/

    function _isValidDurationId(uint256 _durationId) internal pure returns(bool durationIdIsValid) {
        return _durationId <= uint256(DurationId.MONTH12);
    }

    /// @dev left 128 bits of debtTokenId is the durationId, right 128 bits is the timestamp at time of deposit
    function _getDebtTokenId(uint256 _durationId) internal view returns(uint256 debtTokenId) {
        return (_durationId << Constants.FR_DEBTID_OFFSET ) | block.timestamp;
    }


    function _getDebtTokenIdInfo(uint256 _debtTokenId) internal pure returns(uint128 durationId, uint128 timestamp) {
        durationId = uint128(_debtTokenId >> Constants.FR_DEBTID_OFFSET);
        timestamp = uint128(_debtTokenId);
    }
}