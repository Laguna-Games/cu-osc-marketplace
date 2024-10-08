// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {MockERC20} from '../../lib/forge-std/src/mocks/MockERC20.sol';

contract MyERC20Token is MockERC20 {
    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }
}
