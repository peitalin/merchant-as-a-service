// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IGear is IERC1155 {

  // msg.sender must be in allowedContracts to burn. Meem will need to be added to allowedContracts
  function burn(address account, uint256 id, uint256 amount) external;

  // Meem must be admin to mint
  function mint(address wallet, uint256 id, uint256 amount) external;
}