// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IMilk.sol";

contract MooStaking is IERC721Receiver, Pausable, Ownable {
    struct Stake {
        address addr;
        uint64 startTimestamp;
    }

    uint256 public totalStaked;
    uint256 public reward = 1 ether;
    uint256 public interval = 1 days;

    uint256 private constant _BITPOS_START_TIMESTAMP = 160;
    uint256 private constant _BITMASK_ADDRESS = (1 << 160) - 1;

    mapping(uint256 => uint256) private _packedOwnerships;
    mapping(address => uint256) private _balance;

    IERC721 private _collection;
    IMilk private _reward;

    constructor(address collection, address rewardToken) {
        _collection = IERC721(collection);
        _reward = IMilk(rewardToken);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function setCollection(address collection) external onlyOwner {
        _collection = IERC721(collection);
    }

    function setRewardToken(address rewardToken) external onlyOwner {
        _reward = IMilk(rewardToken);
    }

    function setReward(uint256 newReward) external onlyOwner {
        reward = newReward;
    }

    function setInterval(uint256 newInterval) external onlyOwner {
        interval = newInterval;
    }

    function togglePause() external onlyOwner {
        paused() ? _unpause() : _pause();
    }

    function _unpackedOwnership(uint256 packed) private pure returns (Stake memory ownership) {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> _BITPOS_START_TIMESTAMP);
    }

    function _packedOwnershipOf(uint256 tokenId) private view returns (uint256) {
        unchecked {
            uint256 packed = _packedOwnerships[tokenId];
            return packed;
        }
    }

    function _packOwnershipData(address owner) private view returns (uint256 result) {
        assembly {
            owner := and(owner, _BITMASK_ADDRESS)
            result := or(owner, shl(_BITPOS_START_TIMESTAMP, timestamp()))
        }
    }

    function stake(uint256 tokenId) external whenNotPaused {
        _collection.safeTransferFrom(msg.sender, address(this), tokenId, "");
        _packedOwnerships[tokenId] = _packOwnershipData(msg.sender);
        _balance[msg.sender]++;
        totalStaked++;
    }

    function stakeMany(uint256[] calldata tokenIds) external whenNotPaused {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _collection.safeTransferFrom(msg.sender, address(this), tokenIds[i], "");
            _packedOwnerships[tokenIds[i]] = _packOwnershipData(msg.sender);
        }
        _balance[msg.sender] += tokenIds.length;
        totalStaked += tokenIds.length;
    }

    function unstake(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "Not the token owner");
        _collection.safeTransferFrom(address(this), msg.sender, tokenId, "");
        delete _packedOwnerships[tokenId];
        _balance[msg.sender]--;
        totalStaked--;
    }

    function unstakeMany(uint256[] calldata tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(ownerOf(tokenIds[i]) == msg.sender, "Not the token owner");
            _collection.safeTransferFrom(address(this), msg.sender, tokenIds[i], "");
            delete _packedOwnerships[tokenIds[i]];
        }
        _balance[msg.sender] -= tokenIds.length;
        totalStaked -= tokenIds.length;
    }

    function emergencyUnstake(address owner) external onlyOwner {
        require(_balance[owner] > 0, "This address have no token staked");
        uint256[] memory tokenIds = tokensOfOwner(owner);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _collection.safeTransferFrom(address(this), owner, tokenIds[i], "");
            delete _packedOwnerships[tokenIds[i]];
        }
        _balance[owner] -= tokenIds.length;
        totalStaked -= tokenIds.length;
    }

    function calculateRewards(address owner) external view returns (uint256) {
        unchecked {
            if (_balance[owner] == 0) return 0;
            uint256 rewards;
            Stake memory ownership;
            for (uint256 i = 0; i < totalStaked; i++) {
                ownership = _unpackedOwnership(_packedOwnerships[i]);
                if (ownership.addr == owner) {
                    rewards += reward * ((block.timestamp - ownership.startTimestamp) / interval);
                }
            }
            return rewards;
        }
    }

    function claim() external {
        unchecked {
            require(_balance[msg.sender] > 0, "No token staked to claim");
            uint256 rewards;
            Stake memory ownership;
            for (uint256 i = 0; i < totalStaked; i++) {
                ownership = _unpackedOwnership(_packedOwnerships[i]);
                if (ownership.addr == msg.sender) {
                    rewards += reward * ((block.timestamp - ownership.startTimestamp) / interval);
                    _packedOwnerships[i] = _packOwnershipData(msg.sender);
                }
            }
            _reward.mint(msg.sender, rewards);
        }
    }

    function claimAndUnstake() external {
        unchecked {
            require(_balance[msg.sender] > 0, "No token staked to claim");
            uint256 rewards;
            uint256 unstaked;
            Stake memory ownership;
            for (uint256 i = 0; i < totalStaked; i++) {
                ownership = _unpackedOwnership(_packedOwnerships[i]);
                if (ownership.addr == msg.sender) {
                    _collection.safeTransferFrom(address(this), msg.sender, i, "");
                    rewards += reward * ((block.timestamp - ownership.startTimestamp) / interval);
                    delete _packedOwnerships[i];
                    unstaked++;
                }
            }
            _balance[msg.sender] -= unstaked;
            totalStaked -= unstaked;
            _reward.mint(msg.sender, rewards);
        }
    }

    function tokensOfOwner(address owner) public view returns (uint256[] memory) {
        unchecked {
            if (_balance[owner] == 0) return new uint256[](0);
            uint256 tokenIdsIdx;
            uint256[] memory tokenIds = new uint256[](_balance[owner]);
            Stake memory ownership;
            for (uint256 i = 0; tokenIdsIdx != _balance[owner]; i++) {
                ownership = _unpackedOwnership(_packedOwnerships[i]);
                if (ownership.addr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }

    function balanceOf(address owner) public view returns (uint256) {
        return _balance[owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        return address(uint160(_packedOwnershipOf(tokenId)));
    }

    function stakingInfo(uint256 tokenId) external view returns (uint256, uint256, address) {
        require(_collection.ownerOf(tokenId) == address(this), "Token isn't staked");
        Stake memory staked = _unpackedOwnership(_packedOwnerships[tokenId]);
        return (tokenId, staked.startTimestamp, staked.addr);
    }
}