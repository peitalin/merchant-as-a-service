// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./AdminableUpgradeable.sol";


// TEST CONTRACT ONLY
contract SquirePotions is ERC1155BurnableUpgradeable, AdminableUpgradeable {

    enum ItemType { RING, POTION, TRINKET }

    //mappings
    mapping(address => bool) private allowedContracts;

    uint256 thisType;
    string public _baseURI;
    string public _contractURI;


    function initialize() external initializer {
        AdminableUpgradeable.__Adminable_init(msg.sender);
        thisType = uint(ItemType.POTION);
        _baseURI = "ipfs://QmdhMRMrEWZRWyEFAF9whfBdyaCuSECQuc7WmT9eoncV6B/";
        __ERC1155_init("TEST_POTIONS");
    }

    function mint(address to, uint typeChoice) external {
        require(allowedContracts[msg.sender]);

        _mint(to, typeChoice, 1, "");
    }

    function mintMany(address to, uint id, uint256 amount) external onlyAdmin {

        _mint(to, id, amount, "");
    }

    function burn(address account, uint256 id, uint256 qty) public override {
        require(allowedContracts[msg.sender]);
        require(balanceOf(account, id) >= qty, "balance too low");

        _burn(account, id, qty);
    }


    function setBaseURI(string memory newuri) public onlyOwner {
        _baseURI = newuri;
    }

    function setContractURI(string memory newuri) public onlyOwner {
        _contractURI = newuri;
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(_baseURI, uint2str(tokenId)));
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {return "0";}
            uint256 j = _i;
            uint256 len;
        while (j != 0) {len++; j /= 10;}
            bytes memory bstr = new bytes(len);
            uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function setAllowedContracts(address[] calldata contracts) external onlyOwner {
        for (uint256 i; i < contracts.length; i++) {
            allowedContracts[contracts[i]] = true;
        }
    }

    function checkAllowedContracts(address account) public view returns (bool) {
        return allowedContracts[account];
    }

    //withdraw any funds
    function withdrawToOwner() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}