pragma solidity ^0.8.13;

import "src/bases/StakingVault.sol";
import "src/interfaces/IVault.sol";
import "src/DebtToken.sol";

contract FRVault is StakingVault, IVault {
    /// @dev available fixed rate deposit duration options
    uint[3] public durations = [ 90 days, 180 days, 365 days];

    /// @dev timestamp => interest_rate
    mapping(uint256 => uint256) recordedInterestRates;

    constructor(TreasuryToken _treasuryToken, CMW _cmw, DebtToken _debtToken)
        StakingVault(_treasuryToken, _cmw, _debtToken) {}

    /// @dev throws an INDEX OUT OF BOUNDS error if _durationId is invalid
    /// @param _durationId index of selected duration in the durations array 
    function deposit(uint256 _amount, uint256 _durationId) external returns(uint256 debtTokenId) {
        //decleration reverts on invalid durationIds
        debtTokenId = _getDebtTokenId(_durationId);
        recordedInterestRates[block.timestamp] = _getCurrentRate();
        _deposit(msg.sender, debtTokenId, _amount);
    }

    /// @dev reverts if there is a mismatch between _isEarly and interest eligibility 
    function withdraw(uint256 _amount, uint256 _debtTokenId, bool _isEarly) external {
        _withdraw(msg.sender, _debtTokenId, _amount, _isEarly);
    }

    /*------------------------------------------------------OVERRIDES--------------------------------------------------------*/

    /// @dev any given _debtTokenId is eligible for interest if the current timestamp is greater than the timestamp
    /// at time of deposit plus the duration of the deposit
    function _isInterestEligible(uint256 _debtTokenId) internal view override returns(bool isInterestEligible) {
        (uint128 duration, uint128 timestamp) = _getDebtTokenIdInfo(_debtTokenId);
        return block.timestamp >= timestamp + duration;
    }

    function _getInterestOwed(uint256 _debtTokenId, uint256 _amount) internal view override returns(uint256 interestOwed) {
        (uint128 duration, uint128 timestamp) = _getDebtTokenIdInfo(_debtTokenId);
        uint256 annualRate = recordedInterestRates[timestamp];
        return (_amount * annualRate * duration) / (365 days * Constants.BASIS_POINTS);
    }

    /*-----------------------------------------------------------------------------------------------------------------------*/

    /// @dev 256 bit id. left 128 bits are the duration, right 128 bits are the current timestamp
    function _getDebtTokenId(uint256 _durationId) private view returns(uint256 debtTokenId) {
        return (durations[_durationId] << Constants.FR_DEBTID_OFFSET ) | block.timestamp;
    }

    /// @notice unpacks duration and timestamp from a given _debtTokenId
    function _getDebtTokenIdInfo(uint256 _debtTokenId) private pure returns(uint128 duration, uint128 timestamp) {
        duration = uint128(_debtTokenId >> Constants.FR_DEBTID_OFFSET);
        timestamp = uint128(_debtTokenId);
    }
}