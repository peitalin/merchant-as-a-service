// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./AdminableUpgradeable.sol";


// TEST CONTRACT ONLY
contract Gear is ERC1155BurnableUpgradeable, AdminableUpgradeable {

    string tokenURI;

    mapping(address => bool) public admin;

    function initialize() external initializer {
        AdminableUpgradeable.__Adminable_init(msg.sender);
        tokenURI = "ipfs://QmZ1uycD52AD5oSA16bUFJR5s3nzgBuJKFi7VXdcCWF1WN/";
        __ERC1155_init("TEST_GEAR");
    }

    function adminMint(address[] memory wallets, uint256[] memory ids, uint256[] memory amounts) public onlyOwner {

        for(uint i = 0; i < wallets.length; i++)
            for(uint j = 0; j < ids.length; j++)
                _mint(wallets[i], ids[j], amounts[j], "");
    }

    function mint(address wallet, uint256 id, uint256 amount) public onlyAdmin {
        _mint(wallet, id, amount, "");
    }

    function burn(address wallet, uint256 id, uint256 amount) public override onlyAdmin {
        _burn(wallet, id, amount);
    }

    function uri(uint256 tokenId) public view override returns(string memory) {
        return string(abi.encodePacked(tokenURI, Strings.toString(tokenId), ".json"));
    }

    function setURI(string memory _URI) public onlyOwner {
        tokenURI = _URI;
    }

    function setAdmin(address wallet, bool state) public onlyOwner {
        admin[wallet] = state;
    }
}