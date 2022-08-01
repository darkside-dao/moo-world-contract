// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Whitelist is ERC721AQueryable, Ownable {
    string private _defaultBaseURI;
    address private _burner;

    constructor(string memory metadata) ERC721A("Moo World: Whitelist", "MOOWL") {
        _defaultBaseURI = metadata;
    }

    function burn(uint256 tokenId) public {
        _burn(tokenId, true);
    }

    function give(address to, uint256 quantity) external onlyOwner {
        _safeMint(to, quantity);
    }

    function giveMany(address[] calldata to, uint256 quantity) external onlyOwner {
        for (uint i = 0; i < to.length; i++) {
            _safeMint(to[i], quantity);
        }
    }

    function setBaseURI(string calldata newURI) external onlyOwner {
        _defaultBaseURI = newURI;
    }

    function setBurner(address burner) external onlyOwner {
        _burner = burner;
    }

    function tokenURI(uint256) public view override(ERC721A, IERC721A) returns (string memory) {
        return _defaultBaseURI;
    }
}