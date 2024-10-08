// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;
import {LibCurrencyTransfer} from './LibCurrencyTransfer.sol';

library LibMarketplace {
    /// @custom:storage-location erc7201:init.storage
    /// @dev storage slot for the entrypoint contract's storage.
    bytes32 internal constant MARKETPLACE_STORAGE_POSITION =
        keccak256(abi.encode(uint256(keccak256('CryptoUnicorns.Marketplace.Storage')) - 1)) & ~bytes32(uint256(0xff));

    /// @dev Layout of the entrypoint contract's storage.
    struct MarketplaceStorage {
        address nativeTokenWrapper;
        mapping(address => uint256) currenciesMap;
        address[] currencies;
    }

    function addCurrency(address _currency) internal {
        marketplaceStorage().currencies.push(_currency);
        marketplaceStorage().currenciesMap[_currency] = marketplaceStorage().currencies.length;
    }

    function removeCurrency(address _currency) internal {
        uint256 index = marketplaceStorage().currenciesMap[_currency];
        require(index > 0, 'Currency not found');
        marketplaceStorage().currenciesMap[_currency] = 0;
        marketplaceStorage().currencies[index - 1] = marketplaceStorage().currencies[
            marketplaceStorage().currencies.length - 1
        ];
        marketplaceStorage().currencies.pop();
    }

    function currencies() internal view returns (address[] memory) {
        return marketplaceStorage().currencies;
    }

    function currencyIndex(address _currency) internal view returns (uint256) {
        return marketplaceStorage().currenciesMap[_currency];
    }

    function enforceCurrencyApproval(address _currency) internal view {
        require(marketplaceStorage().currenciesMap[_currency] > 0, 'Currency not approved');
    }

    function setNativeTokenWrapper(address _nativeTokenWrapper) internal {
        marketplaceStorage().nativeTokenWrapper = _nativeTokenWrapper;
    }

    function nativeTokenWrapper() internal view returns (address) {
        return marketplaceStorage().nativeTokenWrapper;
    }

    /// @dev Returns the entrypoint contract's data at the relevant storage location.
    function marketplaceStorage() internal pure returns (MarketplaceStorage storage mps) {
        bytes32 position = MARKETPLACE_STORAGE_POSITION;
        assembly {
            mps.slot := position
        }
    }

    function enforceNativeTokenNotUsed(address currency) internal view {
        require(
            msg.value == 0 && currency != LibCurrencyTransfer.NATIVE_TOKEN,
            'Marketplace: Native tokens not accepted.'
        );
    }
}
