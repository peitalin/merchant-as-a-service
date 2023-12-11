// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IBlessedVillager is IERC721 {
    // Burns the given blessed villager.
    // Contract that burns the blessed villager is separate to the blessed villager contract
    function burnBlessed(address _from, uint256 _tokenId) external;
}