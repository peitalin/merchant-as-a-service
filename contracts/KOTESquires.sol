// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./AdminableUpgradeable.sol";


// TEST CONTRACT ONLY
contract KOTESquires is ERC721EnumerableUpgradeable, AdminableUpgradeable {

	using Strings for uint256;
	string public baseURI = "http://kote-squires.s3-website-us-east-1.amazonaws.com/";

	//settings
	uint256 public total;
	uint levelCap;

	//allowed contracts for metadata upgrades
	mapping(address => bool) private allowedContracts;

	//mappings
	mapping(uint => uint256) private tokenIdSquireType;
	mapping(uint => uint256) private tokenIdSquireStrength;
	mapping(uint => uint256) private tokenIdSquireWisdom;
	mapping(uint => uint256) private tokenIdSquireLuck;
	mapping(uint => uint256) private tokenIdSquireFaith;
	mapping(uint256  => string) private tokenIdUpgradeAmount;

	//genesis
	mapping(uint => uint256) private genesisToken;

	function initialize() public initializer {
        AdminableUpgradeable.__Adminable_init(msg.sender);
        __ERC721_init("TEST_SQUIRES", "TSQUIRE");
		setBaseURI(baseURI);
		total = 3999;
		levelCap = 100;
	}

	function airdropSquire(
		address[] calldata addr,
		uint squireType,
		uint genesis,
		uint setStength,
		uint setWisdom,
		uint setLuck,
		uint setFaith
	) external onlyAdmin {

		require(totalSupply() + addr.length <= total);

		for (uint256 i = 0; i < addr.length; i++) {
			uint256 s = totalSupply();
			_safeMint(addr[i], s, "");
			tokenIdSquireType[s] = squireType;
			tokenIdSquireStrength[s] = setStength;
			tokenIdSquireWisdom[s] = setWisdom;
			tokenIdSquireLuck[s] = setLuck;
			tokenIdSquireFaith[s] = setFaith;
			genesisToken[s] = genesis;
		}
	}


	// removed in openzeppelin v5
	function _exists(uint256 tokenId) view internal returns (bool) {
			return _ownerOf(tokenId) != address(0);
	}

	//write metadata
	function setBaseURI(string memory _newBaseURI) public onlyOwner {
		baseURI = _newBaseURI;
	}

	//read metadata
	function _BaseURI() internal view virtual returns (string memory) {
		return baseURI;
	}

	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
		uint t = tokenIdSquireType[tokenId];
		uint s = tokenIdSquireStrength[tokenId];
		uint w = tokenIdSquireWisdom[tokenId];
		uint l = tokenIdSquireLuck[tokenId];
		uint f = tokenIdSquireFaith[tokenId];
		uint g = genesisToken[tokenId];
		return bytes(baseURI).length > 0	? string(abi.encodePacked(baseURI, t.toString(),"-",g.toString(),"-",s.toString(),"-",w.toString(),"-",l.toString(),"-",f.toString())) : "";
	}

	//set contract Address
	function setAllowedContracts(address[] calldata contracts) external onlyAdmin {
		for (uint256 i; i < contracts.length; i++) {
			allowedContracts[contracts[i]] = true;
		}
	}

	//check allowed Contracts
	function checkAllowedContracts(address addr) public view returns (bool) {
		return allowedContracts[addr];
	}

	//withdraw all
	function withdraw() public payable onlyAdmin {
	(bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
		require(success);
	}

}


