#eg:
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFTMarketplace is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private tokenIdCounter;

    address public owner;
    uint256 public listingFee = 0.1 ether; // Fee to list an NFT for sale

    struct NFT {
        address owner;
        uint256 price;
        bool forSale;
        bool inAuction;
    }

    mapping(uint256 => NFT) public nftsForSale;

    event NFTMinted(uint256 tokenId, address owner);
    event NFTListedForSale(uint256 tokenId, uint256 price);
    event NFTRemovedFromSale(uint256 tokenId);
    event NFTSold(uint256 tokenId, address buyer);

    constructor() ERC721("NFTMarketplace", "NFTM") {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    function mintNFT() public {
        tokenIdCounter.increment();
        uint256 newTokenId = tokenIdCounter.current();
        _mint(msg.sender, newTokenId);
        nftsForSale[newTokenId].owner = msg.sender;
        emit NFTMinted(newTokenId, msg.sender);
    }

    function listNFTForSale(uint256 _tokenId, uint256 _price) public {
        require(_exists(_tokenId), "NFT does not exist");
        require(ownerOf(_tokenId) == msg.sender, "You don't own this NFT");
        nftsForSale[_tokenId].price = _price;
        nftsForSale[_tokenId].forSale = true;
        emit NFTListedForSale(_tokenId, _price);
    }

    function removeNFTFromSale(uint256 _tokenId) public {
        require(_exists(_tokenId), "NFT does not exist");
        require(ownerOf(_tokenId) == msg.sender, "You don't own this NFT");
        nftsForSale[_tokenId].forSale = false;
        emit NFTRemovedFromSale(_tokenId);
    }

    function buyNFT(uint256 _tokenId) public payable {
        require(nftsForSale[_tokenId].forSale, "NFT is not for sale");
        require(msg.value >= nftsForSale[_tokenId].price, "Insufficient funds");
        address seller = ownerOf(_tokenId);
        _transfer(seller, msg.sender, _tokenId);
        nftsForSale[_tokenId].forSale = false;
        seller.transfer(msg.value);
        emit NFTSold(_tokenId, msg.sender);
    }

    function setListingFee(uint256 _fee) public onlyOwner {
        listingFee = _fee;
    }

    function withdrawFunds() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        payable(owner).transfer(balance);
    }
}

