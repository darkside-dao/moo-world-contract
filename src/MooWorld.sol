//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/IWhitelist.sol";

contract MooWorld is ERC721Enumerable, ERC721Burnable, ERC721Pausable, ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    uint256 constant public maxTokenIds = 888;
    
    uint256 public mintPrice = 1 ether;
    uint256 public saleAfter = 20 minutes;
    uint256 public presaleEnded;

    bool public presaleStarted;

    Counters.Counter private _tokenIds;

    IWhitelist private _whitelistToken;

    string private _defaultBaseURI;

    constructor(string memory baseURI, address whitelistContract) ERC721("Moo World", "MOO") {
        _defaultBaseURI = baseURI;
        _whitelistToken = IWhitelist(whitelistContract);
    }

    //
    
    function mint(uint quantity) external payable whenNotPaused {
        uint256 tokenId = _tokenIds.current();
        require(presaleStarted && block.timestamp >= presaleEnded, "Public sale not started");
        require(msg.value >= quantity * mintPrice, "Wrong price");
        require((tokenId + quantity) < maxTokenIds, "Exceed max supply");
        for (uint i = 0; i < quantity; i++) {
            _safeMint(msg.sender, tokenId + i);
            _tokenIds.increment();
        }
    }

    function presaleMint(uint8 quantity) external payable whenNotPaused {
        uint256 tokenId = _tokenIds.current();
        require(_whitelisted(msg.sender), "Not whitelisted");
        require(presaleStarted && block.timestamp < presaleEnded, "Presale ended or not started");
        require(msg.value >= quantity * mintPrice, "Wrong price");
        require((tokenId + quantity) < maxTokenIds, "Exceed max supply");
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(msg.sender, tokenId + i);
            _tokenIds.increment();
        }
    }

    //

    function _whitelisted(address to) private view returns (bool) {
        return _whitelistToken.balanceOf(to) > 0;
    }

    //

    function giveaway(address to, uint8 quantity) external onlyOwner {
        uint256 tokenId = _tokenIds.current();
        require((tokenId + quantity) < maxTokenIds, "Exceed max supply");
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(to, tokenId + i);
            _tokenIds.increment();
        }
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Withdraw failed");
    }

    function togglePause() external onlyOwner {
        paused() ? _unpause() : _pause();
    }

    function startPresale() external onlyOwner {
        presaleStarted = true;
        presaleEnded = block.timestamp + saleAfter;
    }

    function resetPresale() external onlyOwner {
        presaleStarted = false;
        presaleEnded = 0;
    }

    function setMintPrice(uint256 newPrice) external onlyOwner {
        mintPrice = newPrice;
    }

    function setWhitelistContract(address newAddress) external onlyOwner {
        _whitelistToken = IWhitelist(newAddress);
    }

    function setBaseURI(string calldata newURI) external onlyOwner {
        _defaultBaseURI = newURI;
    }

    //

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        _requireMinted(tokenId);
        return string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"));
    }

    function _baseURI() internal view override(ERC721) returns (string memory) {
        return _defaultBaseURI;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable, ERC721Pausable) {
        ERC721Enumerable._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}