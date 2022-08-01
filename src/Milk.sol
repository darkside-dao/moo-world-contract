// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Milk is ERC20Burnable, Ownable {
    mapping(address => bool) private _minters;

    constructor() ERC20("Moo World: Milk", "MILK") {}

    function mint(address to, uint256 amount) external {
        require(_minters[msg.sender], "Only authorized minters can mint");
        _mint(to, amount);
    }

    function burnFrom(address from, uint256 amount) public override {
        _minters[msg.sender] ? _burn(from, amount) : super.burnFrom(from, amount);
    }

    function addMinter(address minter) external onlyOwner {
        _minters[minter] = true;
    }

    function removeMinter(address minter) external onlyOwner {
        delete _minters[minter];
    }
}