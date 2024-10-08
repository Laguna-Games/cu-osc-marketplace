// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

// ====== External imports ======
import {ReentrancyGuard} from '@solidstate-contracts/security/reentrancy_guard/ReentrancyGuard.sol';

// ====== Internal imports ======

import {IPlatformFee} from '../../interfaces/IPlatformFee.sol';
import {LibCurrencyTransfer} from '../../libraries/LibCurrencyTransfer.sol';
import {LibEvents} from '../../libraries/LibEvents.sol';
import {IOffers} from '../../interfaces/IMarketplace.sol';

import {LibOffers} from '../../libraries/LibOffers.sol';

contract OffersFacet is ReentrancyGuard {
    /*///////////////////////////////////////////////////////////////
                            External functions
    //////////////////////////////////////////////////////////////*/

    function makeOffer(IOffers.OfferParams memory _params) external returns (uint256 _offerId) {
        return LibOffers.makeOffer(_params);
    }

    function cancelOffer(uint256 _offerId) external {
        LibOffers.cancelOffer(_offerId);
    }

    function acceptOffer(uint256 _offerId) external nonReentrant {
        LibOffers.acceptOffer(_offerId);
    }

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns total number of offers
    function totalOffers() public view returns (uint256) {
        return LibOffers.totalOffers();
    }

    /// @dev Returns existing offer with the given uid.
    function getOffer(uint256 _offerId) external view returns (IOffers.Offer memory _offer) {
        return LibOffers.getOffer(_offerId);
    }

    /// @dev Returns all existing offers within the specified range.
    function getAllOffers(uint256 _startId, uint256 _endId) external view returns (IOffers.Offer[] memory _allOffers) {
        return LibOffers.getAllOffers(_startId, _endId);
    }

    /// @dev Returns offers within the specified range, where offeror has sufficient balance.
    function getAllValidOffers(
        uint256 _startId,
        uint256 _endId
    ) external view returns (IOffers.Offer[] memory _validOffers) {
        return LibOffers.getAllValidOffers(_startId, _endId);
    }
}
