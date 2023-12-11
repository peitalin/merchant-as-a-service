//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./IWanderingMerchant.sol";
import "../AdminableUpgradeable.sol";
import "../ISquirePotions.sol";
import "../IGear.sol"; // KoteItems
import "../IBlessedVillager.sol";

abstract contract WanderingMerchantState is Initializable, IWanderingMerchant, AdminableUpgradeable {

    event WanderingMerchantActiveTimeChanged(uint128 openTime, uint128 closeTime);
    event WanderingMerchantRecipeAdded(uint64 indexed recipeId, uint32 currentAvailable, uint32 maxAvailable, uint32 inputTokenId, uint256 inputAmount, InputType inputType, Output[] outputs);
    event WanderingMerchantRecipeRemoved(uint64 indexed recipeId);
    event WanderingMerchantRecipeFulfilled(uint64 indexed recipeId, address indexed user);

    ISquirePotions public squirePotions;
    IGear public gear;
    IERC721 public squire;
    IBlessedVillager public blessedVillager;

    uint128 public openTime;
    uint128 public closeTime;

    mapping(uint64 => RecipeInfo) recipeIdToInfo;
    uint64 public recipeIdCur;

    uint64[] public activeRecipeIds;

    function __WanderingMerchantState_init(address _initialOwner) internal initializer {
        AdminableUpgradeable.__Adminable_init(_initialOwner);

        recipeIdCur = 1;
    }
}

struct RecipeInfo {
    // Slot 1
    mapping(uint32 => Output) outputIndexToOutput;

    // Slot 2 (144/256)
    //
    // The remaining times this recipe can be used. Will be decremented until
    // it reaches 0.
    //
    uint32 currentAvailable;
    uint32 maxAvailable;
    // If squire potion, corresponds to the squire potion id.
    // If squire will be 0.
    //
    uint32 inputTokenId;
    InputType inputType;
    uint32 numberOfOutputs;
    bool isActive;

    // Slot 3
    uint256 inputAmount;
}

struct Output {
    // Slot 1 (200/256)
    //
    OutputType outputType;
    address transferredFrom;
    uint32 tokenId;

    // Slot 2
    //
    uint256 amount;

    // Slot 3 (160/256)
    //
    // Used to determine which token/collection is being transferred for OutputType.TRANSFERRED_ERC20 and OutputType.TRANSFERRED_ERC1155.
    //
    address outputAddress;
}

enum InputType {
    SQUIRE_POTIONS,
    GEAR,
    SQUIRE,
    BLESSED_VILLAGER
}

enum OutputType {
    SQUIRE_POTIONS,
    GEAR,
    TRANSFERRED_ERC20,
    TRANSFERRED_ERC1155
}
