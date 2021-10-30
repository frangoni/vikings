pragma solidity ^0.4.8;

contract CryptoPunksMarket {
    // You can use this hash to verify the image file containing all the punks
    string public imageHash =
        "ac39af4793119ee46bbff351d8cb6b5f23da60222126add4268e261199a2921b";

    address owner;

    string public standard = "CryptoVikings";
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    uint256 public nextVikIndexToAssign = 0;

    bool public allViksAssigned = false;
    uint256 public viksRemainingToAssign = 0;

    //mapping (address => uint) public addressToPunkIndex;
    mapping(uint256 => address) public vikIndexToAddress;

    /* This creates an array with all balances */
    mapping(address => uint256) public balanceOf;

    struct Offer {
        bool isForSale;
        uint256 vikIndex;
        address seller;
        uint256 minValue; // in ether
        address onlySellTo; // specify to sell only to a specific person
    }

    struct Bid {
        bool hasBid;
        uint256 vikIndex;
        address bidder;
        uint256 value;
    }

    // A record of punks that are offered for sale at a specific minimum value, and perhaps to a specific person
    mapping(uint256 => Offer) public viksOfferedForSale;

    // A record of the highest vik bid
    mapping(uint256 => Bid) public vikBids;

    mapping(address => uint256) public pendingWithdrawals;

    event Assign(address indexed to, uint256 vikIndex);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event VikTransfer(
        address indexed from,
        address indexed to,
        uint256 vikIndex
    );
    event VikOffered(
        uint256 indexed vikIndex,
        uint256 minValue,
        address indexed toAddress
    );
    event VikBidEntered(
        uint256 indexed vikIndex,
        uint256 value,
        address indexed fromAddress
    );
    event VikBidWithdrawn(
        uint256 indexed vikIndex,
        uint256 value,
        address indexed fromAddress
    );
    event VikBought(
        uint256 indexed vikIndex,
        uint256 value,
        address indexed fromAddress,
        address indexed toAddress
    );
    event VikNoLongerForSale(uint256 indexed punkIndex);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function CryptoVikingsMarket() payable {
        //balanceOf[msg.sender] = initialSupply;                 // Give the creator all initial tokens
        owner = msg.sender;
        totalSupply = 5000; // Update total supply
        viksRemainingToAssign = totalSupply;
        name = "CRYPTOVIKINGS"; // Set the name for display purposes
        symbol = "Ͼ"; // Set the symbol for display purposes
        decimals = 0; // Amount of decimals for display purposes
    }

    function setInitialOwner(address to, uint256 vikIndex) {
        if (msg.sender != owner) throw;
        if (allViksAssigned) throw;
        if (vikIndex >= 10000) throw;
        if (vikIndexToAddress[vikIndex] != to) {
            if (vikIndexToAddress[vikIndex] != 0x0) {
                balanceOf[vikIndexToAddress[vikIndex]]--;
            } else {
                viksRemainingToAssign--;
            }
            vikIndexToAddress[vikIndex] = to;
            balanceOf[to]++;
            Assign(to, vikIndex);
        }
    }

    function setInitialOwners(address[] addresses, uint256[] indices) {
        if (msg.sender != owner) throw;
        uint256 n = addresses.length;
        for (uint256 i = 0; i < n; i++) {
            setInitialOwner(addresses[i], indices[i]);
        }
    }

    function allInitialOwnersAssigned() {
        if (msg.sender != owner) throw;
        allViksAssigned = true;
    }

    function getVik(uint256 vikIndex) {
        if (!allViksAssigned) throw;
        if (viksRemainingToAssign == 0) throw;
        if (vikIndexToAddress[vikIndex] != 0x0) throw;
        if (vikIndex >= 10000) throw;
        vikIndexToAddress[vikIndex] = msg.sender;
        balanceOf[msg.sender]++;
        viksRemainingToAssign--;
        Assign(msg.sender, vikIndex);
    }

    // Transfer ownership of a punk to another user without requiring payment
    function transferVik(address to, uint256 vikIndex) {
        if (!allViksAssigned) throw;
        if (vikIndexToAddress[vikIndex] != msg.sender) throw;
        if (vikIndex >= 10000) throw;
        if (viksOfferedForSale[vikIndex].isForSale) {
            VikNoLongerForSale(vikIndex);
        }
        vikIndexToAddress[vikIndex] = to;
        balanceOf[msg.sender]--;
        balanceOf[to]++;
        Transfer(msg.sender, to, 1);
        VikTransfer(msg.sender, to, vikIndex);
        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        Bid bid = vikBids[vikIndex];
        if (bid.bidder == to) {
            // Kill bid and refund value
            pendingWithdrawals[to] += bid.value;
            vikBids[vikIndex] = Bid(false, vikIndex, 0x0, 0);
        }
    }

    //HASTA ACA LLEGUE

    function punkNoLongerForSale(uint256 punkIndex) {
        if (!allPunksAssigned) throw;
        if (punkIndexToAddress[punkIndex] != msg.sender) throw;
        if (punkIndex >= 10000) throw;
        punksOfferedForSale[punkIndex] = Offer(
            false,
            punkIndex,
            msg.sender,
            0,
            0x0
        );
        PunkNoLongerForSale(punkIndex);
    }

    function offerPunkForSale(uint256 punkIndex, uint256 minSalePriceInWei) {
        if (!allPunksAssigned) throw;
        if (punkIndexToAddress[punkIndex] != msg.sender) throw;
        if (punkIndex >= 10000) throw;
        punksOfferedForSale[punkIndex] = Offer(
            true,
            punkIndex,
            msg.sender,
            minSalePriceInWei,
            0x0
        );
        PunkOffered(punkIndex, minSalePriceInWei, 0x0);
    }

    function offerPunkForSaleToAddress(
        uint256 punkIndex,
        uint256 minSalePriceInWei,
        address toAddress
    ) {
        if (!allPunksAssigned) throw;
        if (punkIndexToAddress[punkIndex] != msg.sender) throw;
        if (punkIndex >= 10000) throw;
        punksOfferedForSale[punkIndex] = Offer(
            true,
            punkIndex,
            msg.sender,
            minSalePriceInWei,
            toAddress
        );
        PunkOffered(punkIndex, minSalePriceInWei, toAddress);
    }

    function buyPunk(uint256 punkIndex) payable {
        if (!allPunksAssigned) throw;
        Offer offer = punksOfferedForSale[punkIndex];
        if (punkIndex >= 10000) throw;
        if (!offer.isForSale) throw; // punk not actually for sale
        if (offer.onlySellTo != 0x0 && offer.onlySellTo != msg.sender) throw; // punk not supposed to be sold to this user
        if (msg.value < offer.minValue) throw; // Didn't send enough ETH
        if (offer.seller != punkIndexToAddress[punkIndex]) throw; // Seller no longer owner of punk

        address seller = offer.seller;

        punkIndexToAddress[punkIndex] = msg.sender;
        balanceOf[seller]--;
        balanceOf[msg.sender]++;
        Transfer(seller, msg.sender, 1);

        punkNoLongerForSale(punkIndex);
        pendingWithdrawals[seller] += msg.value;
        PunkBought(punkIndex, msg.value, seller, msg.sender);

        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        Bid bid = punkBids[punkIndex];
        if (bid.bidder == msg.sender) {
            // Kill bid and refund value
            pendingWithdrawals[msg.sender] += bid.value;
            punkBids[punkIndex] = Bid(false, punkIndex, 0x0, 0);
        }
    }

    function withdraw() {
        if (!allPunksAssigned) throw;
        uint256 amount = pendingWithdrawals[msg.sender];
        // Remember to zero the pending refund before
        // sending to prevent re-entrancy attacks
        pendingWithdrawals[msg.sender] = 0;
        msg.sender.transfer(amount);
    }

    function enterBidForPunk(uint256 punkIndex) payable {
        if (punkIndex >= 10000) throw;
        if (!allPunksAssigned) throw;
        if (punkIndexToAddress[punkIndex] == 0x0) throw;
        if (punkIndexToAddress[punkIndex] == msg.sender) throw;
        if (msg.value == 0) throw;
        Bid existing = punkBids[punkIndex];
        if (msg.value <= existing.value) throw;
        if (existing.value > 0) {
            // Refund the failing bid
            pendingWithdrawals[existing.bidder] += existing.value;
        }
        punkBids[punkIndex] = Bid(true, punkIndex, msg.sender, msg.value);
        PunkBidEntered(punkIndex, msg.value, msg.sender);
    }

    function acceptBidForPunk(uint256 punkIndex, uint256 minPrice) {
        if (punkIndex >= 10000) throw;
        if (!allPunksAssigned) throw;
        if (punkIndexToAddress[punkIndex] != msg.sender) throw;
        address seller = msg.sender;
        Bid bid = punkBids[punkIndex];
        if (bid.value == 0) throw;
        if (bid.value < minPrice) throw;

        punkIndexToAddress[punkIndex] = bid.bidder;
        balanceOf[seller]--;
        balanceOf[bid.bidder]++;
        Transfer(seller, bid.bidder, 1);

        punksOfferedForSale[punkIndex] = Offer(
            false,
            punkIndex,
            bid.bidder,
            0,
            0x0
        );
        uint256 amount = bid.value;
        punkBids[punkIndex] = Bid(false, punkIndex, 0x0, 0);
        pendingWithdrawals[seller] += amount;
        PunkBought(punkIndex, bid.value, seller, bid.bidder);
    }

    function withdrawBidForPunk(uint256 punkIndex) {
        if (punkIndex >= 10000) throw;
        if (!allPunksAssigned) throw;
        if (punkIndexToAddress[punkIndex] == 0x0) throw;
        if (punkIndexToAddress[punkIndex] == msg.sender) throw;
        Bid bid = punkBids[punkIndex];
        if (bid.bidder != msg.sender) throw;
        PunkBidWithdrawn(punkIndex, bid.value, msg.sender);
        uint256 amount = bid.value;
        punkBids[punkIndex] = Bid(false, punkIndex, 0x0, 0);
        // Refund the bid money
        msg.sender.transfer(amount);
    }
}
