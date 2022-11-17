// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library CMWLib {
	
	function CMW1(uint256 start, uint256 end) internal view returns (bool b) {
		uint256 halfDuration = (end - start) / 2;
		if ((block.timestamp - start) < halfDuration) {
				// cmw1 rate for current window
				b = (block.timestamp - start) <= 2 days;
		} else {
				// cmw1 rate for next window (current window not yet terminated)
				b = (end - block.timestamp) <= 2 days;
		}
	}

	function CMW2(uint256 start, uint256 end) internal view returns (bool b) {
			b = start + ((end - start) / 2) > block.timestamp;
	}

	function CMW3(uint256 start, uint256 end) internal view returns (bool b) {
			b = start + ((end - start) / 2) <= block.timestamp;
	}
}