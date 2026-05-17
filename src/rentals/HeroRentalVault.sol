// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {PriceOracleAdapter} from "../oracle/PriceOracleAdapter.sol";
import {RentalRevenueVault} from "./RentalRevenueVault.sol";

contract HeroRentalVault is AccessControl, ERC721Holder, Pausable, ReentrancyGuard {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    struct Listing {
        address owner;
        uint128 dailyFee;
        uint128 minCollateralUsd;
        bool exists;
    }

    struct Rental {
        address renter;
        uint64 expiresAt;
        uint128 collateralAmount;
        bool active;
    }

    IERC721 public immutable heroCollection;
    RentalRevenueVault public immutable revenueVault;
    PriceOracleAdapter public immutable oracle;

    mapping(uint256 tokenId => Listing listing) public listings;
    mapping(uint256 tokenId => Rental rental) public rentals;

    event HeroDeposited(uint256 indexed tokenId, address indexed owner, uint256 dailyFee, uint256 minCollateralUsd);
    event HeroWithdrawn(uint256 indexed tokenId, address indexed owner, address indexed recipient);
    event RentalStarted(
        uint256 indexed tokenId, address indexed renter, uint256 expiresAt, uint256 feePaid, uint256 collateralAmount
    );
    event RentalClosed(uint256 indexed tokenId, address indexed renter, bool overdue);

    constructor(address admin, address heroCollection_, address revenueVault_, address oracle_) {
        require(admin != address(0), "admin=0");
        require(heroCollection_ != address(0), "hero=0");
        require(revenueVault_ != address(0), "vault=0");
        require(oracle_ != address(0), "oracle=0");

        heroCollection = IERC721(heroCollection_);
        revenueVault = RentalRevenueVault(revenueVault_);
        oracle = PriceOracleAdapter(oracle_);

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MANAGER_ROLE, admin);
    }

    function pause() external onlyRole(MANAGER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(MANAGER_ROLE) {
        _unpause();
    }

    function depositHero(uint256 tokenId, uint128 dailyFee, uint128 minCollateralUsd) external whenNotPaused {
        require(!listings[tokenId].exists, "listed");

        heroCollection.safeTransferFrom(msg.sender, address(this), tokenId);
        listings[tokenId] =
            Listing({owner: msg.sender, dailyFee: dailyFee, minCollateralUsd: minCollateralUsd, exists: true});

        emit HeroDeposited(tokenId, msg.sender, dailyFee, minCollateralUsd);
    }

    function withdrawHero(uint256 tokenId, address recipient) external nonReentrant {
        Listing memory listing = listings[tokenId];
        require(listing.exists, "missing");
        require(listing.owner == msg.sender, "not owner");
        require(!rentals[tokenId].active, "active rental");
        require(recipient != address(0), "recipient=0");

        delete listings[tokenId];
        heroCollection.safeTransferFrom(address(this), recipient, tokenId);

        emit HeroWithdrawn(tokenId, msg.sender, recipient);
    }

    function rentHero(uint256 tokenId, uint64 durationDays) external payable nonReentrant whenNotPaused {
        Listing memory listing = listings[tokenId];
        require(listing.exists, "missing");
        require(durationDays != 0, "duration=0");
        require(!rentals[tokenId].active, "already rented");

        uint256 collateralUsd = oracle.quoteToUsd(msg.value, 18);
        require(collateralUsd >= listing.minCollateralUsd, "low collateral");

        uint256 feePaid = uint256(listing.dailyFee) * durationDays;
        revenueVault.harvestFrom(msg.sender, feePaid);

        rentals[tokenId] = Rental({
            renter: msg.sender,
            expiresAt: uint64(block.timestamp + (uint256(durationDays) * 1 days)),
            collateralAmount: uint128(msg.value),
            active: true
        });

        emit RentalStarted(tokenId, msg.sender, rentals[tokenId].expiresAt, feePaid, msg.value);
    }

    function closeRental(uint256 tokenId) external nonReentrant {
        Listing memory listing = listings[tokenId];
        Rental memory current = rentals[tokenId];
        require(listing.exists, "missing");
        require(current.active, "inactive");
        require(msg.sender == current.renter || block.timestamp > current.expiresAt, "not allowed");

        delete rentals[tokenId];

        bool overdue = block.timestamp > current.expiresAt;
        address collateralRecipient = overdue ? listing.owner : current.renter;

        (bool success,) = collateralRecipient.call{value: current.collateralAmount}("");
        require(success, "collateral transfer failed");

        emit RentalClosed(tokenId, current.renter, overdue);
    }

    function canUseHero(uint256 tokenId, address player) external view returns (bool) {
        Rental memory current = rentals[tokenId];
        return current.active && current.renter == player && block.timestamp <= current.expiresAt;
    }

    function supportsInterface(bytes4 interfaceId) public view override(AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
