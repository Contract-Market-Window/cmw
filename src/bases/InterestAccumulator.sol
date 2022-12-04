pragma solidity ^0.8.13;

import "src/CMW.sol";
import "src/bases/StakingVault.sol";

/// @dev need to store 2 multipliers in state, since interim rate changes might happen

/// @dev the following are directly called in VRVault
// _updateMultipliers
// _getCurrentMultiplier
// _getActiveWindowMultiplier



abstract contract InterestAccumulator is StakingVault {

    struct InterestMultiplier {
        uint256 windowId; 
        uint256 multiplier;
    }

    InterestMultiplier public lastMultiplier;
    InterestMultiplier public currentMultiplier;

    /// @dev fixed point integer with 128 fractional bits
    /// @dev hourlyRateX128 is the linear hourly rate, so multipliers are not compounded
    uint256 internal hourlyRateX128;

    /// @notice to be called by cmw when there is a rate change
    /// @param _newAnnualRate annual interest rate
    function _onInterestRateChange(uint256 _newAnnualRate) internal {
        uint256 newHourlyRateX128 = _getHourlyRate(_newAnnualRate);
        hourlyRateX128 = newHourlyRateX128;
    }

    /// @notice changes state to store most recent window and its starting multiplier
    /// @dev multipliers stored on state are calculated at time of a window start
    function _updateMultipliers() internal {
        uint256 currentWindowId = _getCurrentWindowId();
        InterestMultiplier memory _currentMultiplier = currentMultiplier;

        //if new window, store new window
        if(currentMultiplier.windowId < currentWindowId) {
            lastMultiplier = _currentMultiplier;
            currentMultiplier = _getUpdatedMultiplier(_currentMultiplier, currentWindowId);
        }
    }

    /// @notice gets multiplier at exact time of function call
    /// @dev interim multipliers can be viewed, however the state multiplier can only be updated once a new window has begun
    function _getCurrentMultiplier() internal view returns(uint256 multiplier) {
        uint256 currentMult = currentMultiplier.multiplier;
        uint256 timeOfMult = _getWindowStart(currentMultiplier.windowId);
        uint256 deltaHours = _getDeltaHours(timeOfMult, block.timestamp);
        multiplier = _addHourlyToMultiplier(currentMult, deltaHours, hourlyRateX128);
    }

    /// @notice gets the multiplier at the start time of the current window
    function _getActiveWindowMultiplier() internal view returns(uint256 multiplier) {
        uint256 currentWindowId = _getCurrentWindowId();
        return (_getUpdatedMultiplier(currentMultiplier, currentWindowId)).multiplier;
    }

    /// @notice adds 96 hours of interest at the current rate to the multiplier
    /// @dev could false positive cmw1 if new window interest rate is significantly lower than prev window interest rate
    function _add96HoursToMultiplier(uint256 _multiplier) internal view returns(uint256 multiplierPadding) {
       return _addHourlyToMultiplier(_multiplier, 96, hourlyRateX128);
    }

    /* --------------------------------------------------PRIVATE-------------------------------------------------- */

    /// @notice calculates multiplier of (probably new) window
    function _getUpdatedMultiplier(InterestMultiplier memory _currentMult, uint256 _currentWindowId) private view returns(InterestMultiplier memory _updatedMult) {
        uint256 windowsDeltaHours = _getWindowsDeltaHours(_currentMult, _currentWindowId);
        uint256 newMultiplier = _addHourlyToMultiplier(_currentMult.multiplier, windowsDeltaHours, hourlyRateX128);
        _updatedMult.windowId = _currentWindowId;
        _updatedMult.multiplier = newMultiplier; 
    }

    /// @notice linearly adds some hours of interest to multiplier
    /// @dev assumes multiplier is on X128 scale
    /// @param _multiplier initial multiplier
    /// @param _deltaHours time difference in hours
    /// @param _hourlyRateX128 hourly interest rate fixed point integer 
    function _addHourlyToMultiplier(uint256 _multiplier, uint256 _deltaHours, uint256 _hourlyRateX128) private pure returns(uint256 summedMultiplier) {
        return _multiplier + ((_deltaHours * _hourlyRateX128));
    }

    /// @notice finds difference in hours between the window in the accumulator and the current window
    function _getWindowsDeltaHours(InterestMultiplier memory _interestMult, uint256 _currentWindowId) private view returns(uint256 deltaHours) {
        uint256 lastWindowStart = _getWindowStart(_interestMult.windowId);
        uint256 currentWindowStart = _getWindowStart(_currentWindowId);
        return _getDeltaHours(lastWindowStart, currentWindowStart);
    }

    function _getCurrentWindowId() private view returns(uint256 windowId) {
        return cmw.getCurrWindow();
    }

    function _getWindowStart(uint256 _windowId) private view returns(uint256 windowStart) {
        return cmw.readWindowStart(_windowId);
    }

    function _getDeltaHours(uint256 initialTime, uint256 finalTime) private pure returns(uint256 deltaHours){
        return (finalTime - initialTime) / 1 hours;
    }

    function _getHourlyRate(uint256 annualRate) internal pure returns(uint256 newHourlyRateX128) {
        return (annualRate << Constants.HOURLY_RATE_OFFSET) / (Constants.HOURS_IN_YEAR);
    }
}