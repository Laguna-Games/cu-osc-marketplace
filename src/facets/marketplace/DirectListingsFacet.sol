// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

// ====== External imports ======
import {ReentrancyGuard} from "@solidstate-contracts/security/reentrancy_guard/ReentrancyGuard.sol";

// ====== Internal imports ======
import {IDirectListings} from "../../interfaces/IMarketplace.sol";
import {LibContractOwner} from "../../../lib/cu-osc-diamond-template/src/libraries/LibContractOwner.sol";
import {LibDirectListings} from "../../libraries/LibDirectListings.sol";

contract DirectListingsFacet is ReentrancyGuard {
    /*///////////////////////////////////////////////////////////////
                            External functions
    //////////////////////////////////////////////////////////////*/

    /// @notice List NFTs (ERC721 or ERC1155) for sale at a fixed price.
    function createListing(
        IDirectListings.ListingParameters calldata _params
    ) external returns (uint256 listingId) {
        return LibDirectListings.createListing(_params);
    }

    /// @notice Update parameters of a listing of NFTs.
    function updateListing(
        uint256 _listingId,
        IDirectListings.ListingParameters memory _params
    ) external {
        LibDirectListings.updateListing(_listingId, _params);
    }

    /// @notice Cancel a listing.
    function cancelListing(uint256 _listingId) external {
        LibDirectListings.cancelListing(_listingId);
    }

    /// @notice Buy NFTs from a listing.
    function buyFromListing(
        uint256 _listingId,
        address _buyFor,
        uint256 _quantity,
        address _currency,
        uint256 _expectedTotalPrice
    ) external payable {
        uint256 targetTotalPrice = LibDirectListings.getTargetTotalPrice(
            _listingId,
            _quantity,
            _currency
        );
        LibDirectListings.buyFromListing(
            _listingId,
            _buyFor,
            _quantity,
            _currency,
            _expectedTotalPrice,
            targetTotalPrice,
            false
        );
    }

    function buyFromMultipleListings(
        uint256[] memory _listingIds,
        address _buyFor,
        uint256[] memory _quantities,
        address[] memory _currencies,
        uint256[] memory _expectedTotalPrices
    ) external payable {
        LibDirectListings.buyFromMultipleListings(
            _listingIds,
            _buyFor,
            _quantities,
            _currencies,
            _expectedTotalPrices
        );
    }

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice Returns the total number of listings created.
     *  @dev At any point, the return value is the ID of the next listing created.
     */
    function totalListings() external view returns (uint256) {
        return LibDirectListings.totalListings();
    }

    /// @notice Returns whether a buyer is approved for a listing.
    function isBuyerApprovedForListing(
        uint256 _listingId,
        address _buyer
    ) external view returns (bool) {
        return LibDirectListings.isBuyerApprovedForListing(_listingId, _buyer);
    }

    /// @notice Returns whether a currency is approved for a listing.
    function isCurrencyApprovedForListing(
        uint256 _listingId,
        address _currency
    ) external view returns (bool) {
        return
            LibDirectListings.isCurrencyApprovedForListing(
                _listingId,
                _currency
            );
    }

    /// @notice Returns the price per token for a listing, in the given currency.
    function currencyPriceForListing(
        uint256 _listingId,
        address _currency
    ) external view returns (uint256) {
        return LibDirectListings.currencyPriceForListing(_listingId, _currency);
    }

    /// @notice Returns all non-cancelled listings.
    function getAllListings(
        uint256 _startId,
        uint256 _endId
    ) external view returns (IDirectListings.Listing[] memory _allListings) {
        return LibDirectListings.getAllListings(_startId, _endId);
    }

    /**
     *  @notice Returns all valid listings between the start and end Id (both inclusive) provided.
     *          A valid listing is where the listing creator still owns and has approved Marketplace
     *          to transfer the listed NFTs.
     */
    function getAllValidListings(
        uint256 _startId,
        uint256 _endId
    ) external view returns (IDirectListings.Listing[] memory _validListings) {
        return LibDirectListings.getAllValidListings(_startId, _endId);
    }

    /// @notice Returns a listing at a particular listing ID.
    function getListing(
        uint256 _listingId
    ) external view returns (IDirectListings.Listing memory listing) {
        return LibDirectListings.getListing(_listingId);
    }
}
