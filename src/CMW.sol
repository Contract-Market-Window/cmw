// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "lib/openzeppelin-contracts/contracts/utils/Counters.sol";
import "src/helpers/CMWLib.sol";
import "src/bases/Controlled.sol";
import "src/VRVault.sol";

contract CMW is Controlled {
    using Counters for Counters.Counter;
    /// @dev Counter keeping track of the highest windowId
    Counters.Counter public _totalWindowIds;
    /// @dev Variable rate vault needs to be notified of interest rate updates 
    VRVault public vrVault;
    /// @dev id of the active window (could be out of date if checkCurrWindow has not been called in a while)
    uint256 public currWindowId;
    /// @dev Active interest rate in basis points (100% = 10,000)
    uint256 public interestRate;
    /// @dev the duration of the window with the highest id
    uint256 public defaultWindowInterval = 6 weeks;
    /// @dev minimum permitted window duration. Transactions attempting to reduce a window duration below this will revert
    uint256 constant minWindowInterval = 1 weeks;

    /// @dev windowId => unix timestamp (in seconds)
    mapping(uint256 => uint256) windowStarts;

    constructor(address _controller) {
        controller = Controller(_controller);
    }

    /// @notice Allows owner to adjust the interest rate.
    /// @dev Owner can only adjust rates within a 24h window from the current window start. 
    /// @param _interestRate The desired interset rate in basis points. (100% = 10,000)
    function setInterestRate(uint256 _interestRate) external onlyOwner {
        require((block.timestamp - windowStarts[checkCurrWindow()]) <= 1 days, "Rate edit time expired");
        interestRate = _interestRate;
        _notifyVault(_interestRate);
    }

    /// @notice sets the variable rate vault
    /// @dev does no interface compat check
    function setVRVault(VRVault _vrVault) external onlyOwner {
        vrVault = _vrVault;
    }

    /// @notice Sets the default window duration (window with highest id has this duration)
    /// @dev default cannot be shorter than minimum
    /// @param _defaultWindowInterval the default window interval in seconds (1 week = 604,800)
    function setDefaultWindowInterval(uint256 _defaultWindowInterval)
        external onlyOwner
    {
        require(_defaultWindowInterval >= minWindowInterval, "Interval below minimum");
        defaultWindowInterval = _defaultWindowInterval;
    }

    /// @notice Defines a new window which gets assigned the new highest window id
    /// @dev Starting time of new window has to be strictly larger than the last window
    /// @param _windowStart the unix timestamp of the new windows starting time
    function createWindow(uint256 _windowStart) public onlyOwner {
        if (_totalWindowIds.current() > 0) {
            // check new window is after current window by at least 1 week
            require(
                (windowStarts[_totalWindowIds.current()] + minWindowInterval) <=
                    _windowStart
            );
        }
        _totalWindowIds.increment();
        windowStarts[_totalWindowIds.current()] = _windowStart;
        windowStarts[_totalWindowIds.current() + 1] =
            _windowStart +
            defaultWindowInterval;
    }

    /// @notice Updates the starting time of an existing window.
    /// @dev Updating the start time of a window, also updates the end time of the window immediately before.
    /// Active windows or their adjacent windows cannot be updated. Past windows cannot be updated.
    /// @param _id id of the window we intend to update
    /// @param _newWindowStart new unix timestamp of the window
    function updateWindow(uint256 _id, uint256 _newWindowStart) external onlyOwner {
        require(_id <= _totalWindowIds.current(), "Id out of bounds");
        require(_id > (checkCurrWindow() + 1), "Current or next windows are not updatable");
        require((_newWindowStart - windowStarts[_id - 1]) >= minWindowInterval, "Previous window min interval error");
        require((windowStarts[_id + 1] - _newWindowStart) >= minWindowInterval, "Next window min interval error");

        windowStarts[_id] = _newWindowStart;
    }

    /// @notice Creates multiple windows in a single transaction.
    /// @dev Gas usage increases linearly with input array size. 
    /// @param _windowStarts array containing strictly increasing unix timestamps.
    function batchCreateWindows(uint256[] memory _windowStarts)
        external onlyOwner
    {
        for (uint256 i = _totalWindowIds.current(); i < _windowStarts.length; i++) {
            createWindow(_windowStarts[i]);
        }
    }

    /// @notice Reads the start time of a particular window 
    /// @param _id id of desired window. 
    function readWindowStart(uint256 _id) public view returns (uint256) {
        return windowStarts[_id];
    }

    /// @notice Reads start times of all windows
    /// @dev Length gets 2 added to it since Counter starts at 1 and we have a default window cap.
    function readWindowStarts() external view returns (uint256[] memory) {
        uint256 length = (_totalWindowIds.current() + 2);
        uint256[] memory windowStartsArray = new uint256[](length);
        
        for (uint256 i = 0; i < length; i++) {
            windowStartsArray[i] = readWindowStart(i);
        }
        return windowStartsArray;
    } 

    /// @notice Checks whether a cmw stage is currently available
    /// @param _cmwStage the cmw stage we wish to check for activity ( [cmw1, cmw2, cmw3] = [0, 1, 2] )
    /// @return stageIsActive true if the given cmw stage is currently active. 
    function checkCmwStage(uint256 _cmwStage) public returns (bool stageIsActive) {
        require(_cmwStage <= 2, "CMW out of bounds");
        uint256 id = checkCurrWindow();
        uint256 start = windowStarts[id];
        uint256 end = windowStarts[id + 1];
        if (_cmwStage == 0) {
            stageIsActive = CMWLib.CMW1(start, end);
        } else if (_cmwStage == 1) {
            stageIsActive = CMWLib.CMW2(start, end);
        } else {
            stageIsActive = CMWLib.CMW3(start, end);
        }
    }

    /// @notice Finds the window currently active. 
    /// @dev Changes state to store the current window id
    /// @return currentWindowId id of the current window
    function checkCurrWindow() public returns (uint256 currentWindowId) {
        currentWindowId = getCurrWindow();
        currWindowId = currentWindowId;
    }

    /// @notice same as checkCurrWindow without modifying state
    function getCurrWindow() public view returns (uint256 currentWindowId) {
        uint256 totalWindows = _totalWindowIds.current();
        for (uint256 i = currWindowId; i < totalWindows; i++) {
            if (windowStarts[i] < block.timestamp) {
                if (windowStarts[i + 1] > block.timestamp) {
                    currentWindowId = i;
                    return currentWindowId;
                }
            }
        }
    }

    /// @notice updates interest rates on the vrVault
    function _notifyVault(uint256 _newRate) private {
        if(address(vrVault) != address(0)) {
            vrVault.onInterestRateChange(_newRate);
        }
    }
}
