// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@thirdweb-dev/contracts/drop/DropERC1155.sol";
import "@thirdweb-dev/contracts/token/TokenERC20.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract MiningContract is ReentrancyGuard, ERC1155Holder {
    DropERC1155 public immutable dropNftCollection;
    TokenERC20 public immutable rewardsToken;

    constructor(DropERC1155 editionDropContractAddress, TokenERC20 tokenContractAddress) {
        dropNftCollection = editionDropContractAddress;
        rewardsToken = tokenContractAddress;
    }

    struct MapValue {
        bool isData;
        uint256 value;
    }
    mapping (address => MapValue) public miningToken;

    mapping (address => MapValue) public minerLastUpdate;

    function stake(uint256 _tokenId) external nonReentrant {
        require(dropNftCollection.balanceOf(msg.sender, _tokenId) >= 1, "You must have at least 1 of the NFT you are trying to stake");

        if (miningToken[msg.sender].isData) {
            dropNftCollection.safeTransferFrom(address(this), msg.sender, miningToken[msg.sender].value, 1, "Returning your old NFT");
        }

        uint256 reward = calculateRewards(msg.sender);
        rewardsToken.transfer(msg.sender, reward);

        dropNftCollection.safeTransferFrom(msg.sender, address(this), _tokenId, 1, "Staking your NFT");

        miningToken[msg.sender].value = _tokenId;
        miningToken[msg.sender].isData = true;

        minerLastUpdate[msg.sender].isData = true;
        minerLastUpdate[msg.sender].value = block.timestamp;
    }


    function withdraw() external nonReentrant {
        require(miningToken[msg.sender].isData, "You do not have a NFT to withdraw.");

        uint256 reward = calculateRewards(msg.sender);
        rewardsToken.transfer(msg.sender, reward);

        dropNftCollection.safeTransferFrom(address(this), msg.sender, miningToken[msg.sender].value, 1, "Returning your old NFT");

        miningToken[msg.sender].isData = false;

        minerLastUpdate[msg.sender].isData = true;
        minerLastUpdate[msg.sender].value = block.timestamp;
    }

    function claim() external nonReentrant {
        uint256 reward = calculateRewards(msg.sender);
        rewardsToken.transfer(msg.sender, reward);

        minerLastUpdate[msg.sender].isData = true;
        minerLastUpdate[msg.sender].value = block.timestamp;
    }        

    function calculateRewards(address _miner)
        public
        view
        returns (uint256 _rewards)
    {
        if (!minerLastUpdate[_miner].isData || !miningToken[_miner].isData) {
            return 0;
        }

        uint256 timeDifference = block.timestamp - minerLastUpdate[_miner].value;

        uint256 rewards = timeDifference * 10_000_000_000_000 * (miningToken[_miner].value + 1);

        return rewards;
        
    }
}
