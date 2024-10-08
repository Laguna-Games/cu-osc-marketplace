// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {CutDiamond} from "../../lib/cu-osc-diamond-template/src/diamond/CutDiamond.sol";
import {IDirectListings} from "../interfaces/IMarketplace.sol";
import {IOffers, IEnglishAuctions} from "../interfaces/IMarketplace.sol";
import {IPlatformFee} from "../interfaces/IPlatformFee.sol";

/// @title Dummy "implementation" contract for LG Diamond interface for ERC-1967 compatibility
/// @dev adapted from https://github.com/zdenham/diamond-etherscan?tab=readme-ov-file
/// @dev This interface is used internally to call endpoints on a deployed diamond cluster.

contract MarketplaceImplementation is CutDiamond {
    /// @dev Emitted when the contract URI is updated.
    event ContractURIUpdated(string prevURI, string newURI);

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /// @dev Emitted when fee on primary sales is updated.
    event PlatformFeeInfoUpdated(
        address indexed platformFeeRecipient,
        uint256 platformFeeBps
    );

    /// @dev Emitted when the flat platform fee is updated.
    event FlatPlatformFeeUpdated(address platformFeeRecipient, uint256 flatFee);

    /// @dev Emitted when the platform fee type is updated.
    event PlatformFeeTypeUpdated(IPlatformFee.PlatformFeeType feeType);

    /// @dev Emitted when the address of RoyaltyEngine is set or updated.
    event RoyaltyEngineUpdated(
        address indexed previousAddress,
        address indexed newAddress
    );

    /// @dev Emitted when a new auction is created.
    event NewAuction(
        address indexed auctionCreator,
        uint256 indexed auctionId,
        address indexed assetContract,
        IEnglishAuctions.Auction auction
    );

    /// @dev Emitted when a new bid is made in an auction.
    event NewBid(
        uint256 indexed auctionId,
        address indexed bidder,
        address indexed assetContract,
        uint256 bidAmount,
        IEnglishAuctions.Auction auction
    );

    /// @notice Emitted when a auction is cancelled.
    event CancelledAuction(
        address indexed auctionCreator,
        uint256 indexed auctionId
    );

    /// @dev Emitted when an auction is closed.
    event AuctionClosed(
        uint256 indexed auctionId,
        address indexed assetContract,
        address indexed closer,
        uint256 tokenId,
        address auctionCreator,
        address winningBidder
    );

    /// @dev Emitted when a new offer is created.
    event NewOffer(
        address indexed offeror,
        uint256 indexed offerId,
        address indexed assetContract,
        IOffers.Offer offer
    );

    /// @dev Emitted when an offer is cancelled.
    event CancelledOffer(address indexed offeror, uint256 indexed offerId);

    /// @dev Emitted when an offer is accepted.
    event AcceptedOffer(
        address indexed offeror,
        uint256 indexed offerId,
        address indexed assetContract,
        uint256 tokenId,
        address seller,
        uint256 quantityBought,
        uint256 totalPricePaid
    );
    /// @notice Emitted when a new listing is created.
    event NewListing(
        address indexed listingCreator,
        uint256 indexed listingId,
        address indexed assetContract,
        IDirectListings.Listing listing
    );

    /// @notice Emitted when a listing is updated.
    event UpdatedListing(
        address indexed listingCreator,
        uint256 indexed listingId,
        address indexed assetContract,
        IDirectListings.Listing listing
    );

    /// @notice Emitted when a listing is cancelled.
    event CancelledListing(
        address indexed listingCreator,
        uint256 indexed listingId
    );

    /// @notice Emitted when a buyer is approved to buy from a reserved listing.
    event BuyerApprovedForListing(
        uint256 indexed listingId,
        address indexed buyer,
        bool approved
    );

    /// @notice Emitted when a currency is approved as a form of payment for the listing.
    event CurrencyApprovedForListing(
        uint256 indexed listingId,
        address indexed currency,
        uint256 pricePerToken
    );

    /// @notice Emitted when NFTs are bought from a listing.
    event NewSale(
        address indexed listingCreator,
        uint256 indexed listingId,
        address indexed assetContract,
        uint256 tokenId,
        address buyer,
        uint256 quantityBought,
        uint256 totalPricePaid
    );

    /// @dev Emitted when royalty info is updated.
    event DefaultRoyalty(
        address indexed newRoyaltyRecipient,
        uint256 newRoyaltyBps
    );

    /// @dev Emitted when royalty recipient for tokenId is set
    event RoyaltyForToken(
        uint256 indexed tokenId,
        address indexed royaltyRecipient,
        uint256 royaltyBps
    );

    /*
     * LISTINGS
     */

    function createListing(
        IDirectListings.ListingParameters calldata _params
    ) external returns (uint256 listingId) {}

    function updateListing(
        uint256 _listingId,
        IDirectListings.ListingParameters memory _params
    ) external {}

    function cancelListing(uint256 _listingId) external {}

    function buyFromListing(
        uint256 _listingId,
        address _buyFor,
        uint256 _quantity,
        address _currency,
        uint256 _expectedTotalPrice
    ) external payable {}

    function buyFromMultipleListings(
        uint256[] memory _listingIds,
        address _buyFor,
        uint256[] memory _quantities,
        address[] memory _currencies,
        uint256[] memory _expectedTotalPrices
    ) external payable {}

    function totalListings() external view returns (uint256) {}

    /// @notice Returns whether a buyer is approved for a listing.
    function isBuyerApprovedForListing(
        uint256 _listingId,
        address _buyer
    ) external view returns (bool) {}

    /// @notice Returns whether a currency is approved for a listing.
    function isCurrencyApprovedForListing(
        uint256 _listingId,
        address _currency
    ) external view returns (bool) {}

    /// @notice Returns the price per token for a listing, in the given currency.
    function currencyPriceForListing(
        uint256 _listingId,
        address _currency
    ) external view returns (uint256) {}

    /// @notice Returns all non-cancelled listings.
    function getAllListings(
        uint256 _startId,
        uint256 _endId
    ) external view returns (IDirectListings.Listing[] memory _allListings) {}

    /**
     *  @notice Returns all valid listings between the start and end Id (both inclusive) provided.
     *          A valid listing is where the listing creator still owns and has approved Marketplace
     *          to transfer the listed NFTs.
     */
    function getAllValidListings(
        uint256 _startId,
        uint256 _endId
    ) external view returns (IDirectListings.Listing[] memory _validListings) {}

    /// @notice Returns a listing at a particular listing ID.
    function getListing(
        uint256 _listingId
    ) external view returns (IDirectListings.Listing memory listing) {}

    /*
     * MARKETPLACE V3
     */

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {}

    // implement ERC1155Receiver.onERC1155Received
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4) {}

    function setNativeTokenWrapper(address _nativeTokenWrapper) external {}

    function getNativeTokenWrapper() external view returns (address) {}

    function addCurrency(address _currency) external {}

    function removeCurrency(address _currency) external {}

    function currencies() external view returns (address[] memory) {}

    function currencyIndex(address _currency) external view returns (uint256) {}

    /*
     * OFFERS
     */
    function makeOffer(
        IOffers.OfferParams memory _params
    ) external returns (uint256 _offerId) {}

    function cancelOffer(uint256 _offerId) external {}

    function acceptOffer(uint256 _offerId) external {}

    /// @dev Returns total number of offers
    function totalOffers() public view returns (uint256) {}

    /// @dev Returns existing offer with the given uid.
    function getOffer(
        uint256 _offerId
    ) external view returns (IOffers.Offer memory _offer) {}

    /// @dev Returns all existing offers within the specified range.
    function getAllOffers(
        uint256 _startId,
        uint256 _endId
    ) external view returns (IOffers.Offer[] memory _allOffers) {}

    /// @dev Returns offers within the specified range, where offeror has sufficient balance.
    function getAllValidOffers(
        uint256 _startId,
        uint256 _endId
    ) external view returns (IOffers.Offer[] memory _validOffers) {}

    function hasRole(
        bytes32 role,
        address account
    ) public view returns (bool) {}

    /**
     *  @notice         Checks whether an account has a particular role;
     *                  role restrictions can be swtiched on and off.
     *
     *  @dev            Returns `true` if `account` has been granted `role`.
     *                  Role restrictions can be swtiched on and off:
     *                      - If address(0) has ROLE, then the ROLE restrictions
     *                        don't apply.
     *                      - If address(0) does not have ROLE, then the ROLE
     *                        restrictions will apply.
     *
     *  @param role     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     *  @param account  Address of the account for which the role is being checked.
     */
    function hasRoleWithSwitch(
        bytes32 role,
        address account
    ) public view returns (bool) {}

    /**
     *  @notice         Returns the admin role that controls the specified role.
     *  @dev            See {grantRole} and {revokeRole}.
     *                  To change a role's admin, use {_setRoleAdmin}.
     *
     *  @param role     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32) {}

    /**
     *  @notice         Grants a role to an account, if not previously granted.
     *  @dev            Caller must have admin role for the `role`.
     *                  Emits {RoleGranted Event}.
     *
     *  @param role     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     *  @param account  Address of the account to which the role is being granted.
     */
    function grantRole(bytes32 role, address account) public {}

    /**
     *  @notice         Revokes role from an account.
     *  @dev            Caller must have admin role for the `role`.
     *                  Emits {RoleRevoked Event}.
     *
     *  @param role     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     *  @param account  Address of the account from which the role is being revoked.
     */
    function revokeRole(bytes32 role, address account) public {}

    /**
     *  @notice         Revokes role from the account.
     *  @dev            Caller must have the `role`, with caller being the same as `account`.
     *                  Emits {RoleRevoked Event}.
     *
     *  @param role     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     *  @param account  Address of the account from which the role is being revoked.
     */
    function renounceRole(bytes32 role, address account) public {}

    /// @dev Returns whether all relevant permission and other checks are met before any upgrade.
    function isAuthorizedCallToUpgrade() public view returns (bool) {}

    /**
     *  @notice         Returns the role-member from a list of members for a role,
     *                  at a given index.
     *  @dev            Returns `member` who has `role`, at `index` of role-members list.
     *                  See struct {RoleMembers}, and mapping {roleMembers}
     *
     *  @param role     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     *  @param index    Index in list of current members for the role.
     *
     *  @return member  Address of account that has `role`
     */
    function getRoleMember(
        bytes32 role,
        uint256 index
    ) external view returns (address member) {}

    /**
     *  @notice         Returns total number of accounts that have a role.
     *  @dev            Returns `count` of accounts that have `role`.
     *                  See struct {RoleMembers}, and mapping {roleMembers}
     *
     *  @param role     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     *
     *  @return count   Total number of accounts that have `role`
     */
    function getRoleMemberCount(
        bytes32 role
    ) external view returns (uint256 count) {}

    /// @dev Returns the platform fee recipient and bps.
    function getPlatformFeeInfo()
        public
        view
        virtual
        returns (address, uint16)
    {}

    /// @dev Returns the platform fee bps and recipient.
    function getFlatPlatformFeeInfo()
        public
        view
        virtual
        returns (address, uint256)
    {}

    /// @dev Returns the platform fee type.
    function getPlatformFeeType()
        public
        view
        virtual
        returns (IPlatformFee.PlatformFeeType)
    {}

    /**
     *  @notice         Updates the platform fee recipient and bps.
     *  @dev            Caller should be authorized to set platform fee info.
     *                  See {_canSetPlatformFeeInfo}.
     *                  Emits {PlatformFeeInfoUpdated Event}; See {_setupPlatformFeeInfo}.
     *
     *  @param _platformFeeRecipient   Address to be set as new platformFeeRecipient.
     *  @param _platformFeeBps         Updated platformFeeBps.
     */
    function setPlatformFeeInfo(
        address _platformFeeRecipient,
        uint256 _platformFeeBps
    ) external {}

    /// @notice Lets a module admin set a flat fee on primary sales.
    function setFlatPlatformFeeInfo(
        address _platformFeeRecipient,
        uint256 _flatFee
    ) external {}

    /// @notice Lets a module admin set platform fee type.
    function setPlatformFeeType(
        IPlatformFee.PlatformFeeType _feeType
    ) external {}

    /// @dev Checks whether platform fee info can be set in the given execution context.
    function canSetPlatformFeeInfo() public view returns (bool) {}

    function setRoyaltyEngineAddress(
        address _royaltyEngineAddress
    ) public virtual {}

    /**
     * Get the royalty for a given token (address, id) and value amount.  Does not cache the bps/amounts.  Caches the spec for a given token address
     *
     * @param tokenAddress - The address of the token
     * @param tokenId      - The id of the token
     * @param value        - The value you wish to get the royalty of
     *
     * returns Two arrays of equal length, royalty recipients and the corresponding amount each recipient should get
     */
    function getRoyalty(
        address tokenAddress,
        uint256 tokenId,
        uint256 value
    )
        external
        returns (address payable[] memory recipients, uint256[] memory amounts)
    {}

    /// @dev Returns original or overridden address for RoyaltyEngineV1
    function getRoyaltyEngineAddress()
        public
        view
        returns (address royaltyEngineAddress)
    {}

    /// @dev Returns whether royalty engine address can be set in the given execution context.
    function canSetRoyaltyEngine() public view returns (bool) {}
}
