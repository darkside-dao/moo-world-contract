// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "../src/Whitelist.sol";
import "../src/MooWorld.sol";
import "../src/MooStaking.sol";
import "../src/Milk.sol";

contract MooStakingTest is Test {
    MooStaking staking;
    MooWorld collection;
    Whitelist whitelist;
    Milk reward;

    function setUp() public {
        whitelist = new Whitelist("");
        collection = new MooWorld("", address(whitelist));
        reward = new Milk();
        staking = new MooStaking(address(collection), address(reward));
        reward.addMinter(address(staking));
        collection.startPresale();
        vm.warp(block.timestamp + collection.saleAfter());
    }

    function _mint() private {
        uint256 price = collection.mintPrice() * 10;
        vm.prank(msg.sender);
        collection.mint{value: price}(10);
        vm.prank(msg.sender);
        collection.setApprovalForAll(address(staking), true);
    }

    function _mintAndStake(uint256 quantity) private {
        uint256 price = collection.mintPrice() * quantity;
        vm.prank(msg.sender);
        collection.mint{value: price}(quantity);
        vm.prank(msg.sender);
        collection.setApprovalForAll(address(staking), true);
        uint256[] memory tokenIds = new uint256[](quantity);
        for (uint256 i = 0; i < quantity; i++) tokenIds[i] = i;
        vm.prank(msg.sender);
        staking.stakeMany(tokenIds);
    }

    function testStake() public {
        _mint();
        vm.prank(msg.sender);
        staking.stake(0);
        assertEq(staking.balanceOf(msg.sender), 1);
    }

    function testStakeMany() public {
        _mint();
        uint256[] memory tokenIds = new uint256[](10);
        for (uint256 i = 0; i < 10; i++) tokenIds[i] = i;
        vm.prank(msg.sender);
        staking.stakeMany(tokenIds);
        assertEq(staking.balanceOf(msg.sender), 10);
    }

    function testUnstake() public {
        testStake();
        vm.prank(msg.sender);
        staking.unstake(0);
        assertEq(staking.balanceOf(msg.sender), 0);
    }

    function testUnstakeMany() public {
        testStakeMany();
        uint256[] memory tokenIds = new uint256[](10);
        for (uint256 i = 0; i < 10; i++) tokenIds[i] = i;
        vm.prank(msg.sender);
        staking.unstakeMany(tokenIds);
        assertEq(staking.balanceOf(msg.sender), 0);
    }

    function testCalculateRewards() public {
        testStakeMany();
        vm.warp(block.timestamp + 1 days);
        assertEq(staking.calculateRewards(msg.sender), 10 ether);
    }

    function testClaim() public {
        _mintAndStake(100);
        vm.warp(block.timestamp + 1 days);
        vm.prank(msg.sender);
        staking.claim();
        assertEq(reward.balanceOf(msg.sender), 100 ether);
    }

    function testClaimAndUnstake() public {
        _mintAndStake(100);
        vm.warp(block.timestamp + 1 days);
        vm.prank(msg.sender);
        staking.claimAndUnstake();
        assertEq(staking.balanceOf(msg.sender), 0);
    }

    function testStakeVarious() public {
        _mint();
        _mint();
        _mint();
        _mint();
        _mint();
        _mint();
        _mint();
        _mint();
        _mint();
        _mint();
        _mint();
        _mint();
        vm.prank(msg.sender);
        staking.stake(1);
        vm.prank(msg.sender);
        staking.stake(2);
        vm.prank(msg.sender);
        staking.stake(3);
        vm.prank(msg.sender);
        staking.stake(4);
        vm.prank(msg.sender);
        staking.stake(10);
        vm.prank(msg.sender);
        staking.stake(11);
        vm.prank(msg.sender);
        staking.stake(12);
        uint256[] memory tokenIds = staking.tokensOfOwner(msg.sender);
        assertEq(staking.balanceOf(msg.sender), 7);
    }
}