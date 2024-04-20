// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract BASCFoundersCollection is ERC721Enumerable, Ownable, ReentrancyGuard {
    uint256 private _nextTokenId = 0;
    bool public saleIsActive = false;
    string public baseTokenURI;

    // ApeCoin interface to interact with the ApeCoin token
    IERC20 public apeCoin;

    struct NFTType {
        uint256 priceInETH;
        uint256 priceInApe;
        uint256 maxSupply;
        uint256 totalSupply;
    }

    // NFT type details
    mapping(string => NFTType) public nftTypes;
    mapping(uint256 => string) public nftClasses;

    constructor(address initialOwner, address apeCoinAddress) ERC721("BASC Statues Founders Collection", "BASC") Ownable() {
        transferOwnership(initialOwner);
        apeCoin = IERC20(apeCoinAddress);

        // Initialize each NFT type with price and supply
        nftTypes["TableTop"] = NFTType(0.42 ether, 610 * 10**18, 50, 0);
        nftTypes["Shorty"] = NFTType(1 ether, 1454.45 * 10**18, 10, 0);
        nftTypes["Biggie"] = NFTType(3 ether, 4363.35 * 10**18, 10, 0);
        nftTypes["2Mac"] = NFTType(6 ether, 8726.70 * 10**18, 2, 0);
    }

    function setNFTTypeDetails(string memory nftType, uint256 priceInETH, uint256 priceInApe, uint256 maxSupply) public onlyOwner {
        NFTType storage nft = nftTypes[nftType];
        nft.priceInETH = priceInETH;
        nft.priceInApe = priceInApe;
        nft.maxSupply = maxSupply;
    }

    function toggleSaleActive() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function buyNFTwithETH(string memory nftType) public payable nonReentrant {
        require(saleIsActive, "Sale must be active to mint NFT");
        require(nftTypes[nftType].totalSupply < nftTypes[nftType].maxSupply, "Exceeds maximum supply");
        require(msg.value >= nftTypes[nftType].priceInETH, "Ether sent is not correct");

        nftTypes[nftType].totalSupply++;
        _safeMint(msg.sender, _nextTokenId++);
        nftClasses[_nextTokenId]=nftType;
    }

    function buyNFTwithApe(string memory nftType, uint256 apeAmount) public nonReentrant {
        require(saleIsActive, "Sale must be active to mint NFT");
        require(nftTypes[nftType].totalSupply < nftTypes[nftType].maxSupply, "Exceeds maximum supply");
        require(apeAmount >= nftTypes[nftType].priceInApe, "ApeCoin amount sent is not correct");
        require(apeCoin.transferFrom(msg.sender, address(this), apeAmount), "Failed to transfer ApeCoins");

        nftTypes[nftType].totalSupply++;
        _safeMint(msg.sender, _nextTokenId++);
        nftClasses[_nextTokenId]=nftType;

    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    function withdrawApeCoins() public onlyOwner {
        uint apeBalance = apeCoin.balanceOf(address(this));
        apeCoin.transfer(owner(), apeBalance);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }
}

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);  
}