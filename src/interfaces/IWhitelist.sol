//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IWhitelist {
    function burn(uint256 tokenId) external;
    function balanceOf(address owner) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}