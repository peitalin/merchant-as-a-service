//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./WanderingMerchantState.sol";

abstract contract WanderingMerchantContracts is Initializable, WanderingMerchantState {

    function __WanderingMerchantContracts_init(address _initialOwner) internal initializer {
        WanderingMerchantState.__WanderingMerchantState_init(_initialOwner);
    }

    function setContracts(
        address _squirePotionsAddress,
        address _gearAddress,
        address _squireAddress,
        address _blessedVillagerAddress
    ) external onlyAdminOrOwner {

        squirePotions = ISquirePotions(_squirePotionsAddress);
        gear = IGear(_gearAddress);
        squire = IERC721(_squireAddress);
        blessedVillager = IBlessedVillager(_blessedVillagerAddress);
    }

    modifier contractsAreSet() {
        require(areContractsSet(), "WanderingMerchant: Contracts aren't set");
        _;
    }

    function areContractsSet() public view returns(bool) {
        return address(squirePotions) != address(0)
            && address(gear) != address(0)
            && address(squire) != address(0)
            && address(blessedVillager) != address(0);
    }
}