// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {LibDebug} from "../libraries/LibDebug.sol";
import {IWETH} from "../interfaces/IWETH.sol";

contract DebugFacet {
    function debug() external view returns (string memory) {
        return "DebugFacet";
    }

    function debugInc() external {
        LibDebug.debugInc();
    }

    function debugWETHDeposit(address _nativeTokenWrapper, uint256 _amount) external payable {
        IWETH(_nativeTokenWrapper).deposit{value: _amount}();
    }
}
