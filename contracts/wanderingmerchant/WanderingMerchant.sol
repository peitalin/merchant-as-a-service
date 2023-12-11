//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import "./WanderingMerchantContracts.sol";


contract WanderingMerchant is Initializable, WanderingMerchantContracts {

    function initialize() external initializer {
        WanderingMerchantContracts.__WanderingMerchantContracts_init(msg.sender);
    }

    function openMerchant(uint128 _openTime, uint128 _closeTime, bool _clearExistingRecipes, Recipe[] calldata _recipes) external onlyAdminOrOwner {
        openTime = _openTime;
        closeTime = _closeTime;

        while(_clearExistingRecipes && activeRecipeIds.length != 0) {
            _removeRecipe(activeRecipeIds[0]);
        }

        addRecipes(_recipes);

        emit WanderingMerchantActiveTimeChanged(_openTime, _closeTime);
    }

    function addRecipes(Recipe[] calldata _recipes) public onlyAdminOrOwner {
        for(uint256 i = 0; i < _recipes.length; i++) {
            _addRecipe(_recipes[i]);
        }
    }

    function removeRecipes(uint64[] calldata _recipeIds) external onlyAdminOrOwner {
        for(uint256 i = 0; i < _recipeIds.length; i++) {
            _removeRecipe(_recipeIds[i]);
        }
    }

    function _addRecipe(Recipe calldata _recipe) private {
        uint64 _recipeId = recipeIdCur;
        recipeIdCur++;

        require(_recipe.currentAvailable <= _recipe.maxAvailable, "Bad available amounts");
        require(_recipe.inputAmount > 0, "Input amount must be greater than 0");

        RecipeInfo storage _recipeInfo = recipeIdToInfo[_recipeId];
        _recipeInfo.currentAvailable = _recipe.currentAvailable;
        _recipeInfo.maxAvailable = _recipe.maxAvailable;
        _recipeInfo.inputTokenId = _recipe.inputTokenId;
        _recipeInfo.inputAmount = _recipe.inputAmount;
        _recipeInfo.inputType = _recipe.inputType;
        _recipeInfo.numberOfOutputs = uint32(_recipe.outputs.length);
        _recipeInfo.isActive = true;

        for(uint32 i = 0; i < _recipe.outputs.length; i++) {
            _recipeInfo.outputIndexToOutput[i] = _recipe.outputs[i];
        }

        activeRecipeIds.push(_recipeId);

        emit WanderingMerchantRecipeAdded(_recipeId, _recipe.currentAvailable, _recipe.maxAvailable, _recipe.inputTokenId, _recipe.inputAmount, _recipe.inputType, _recipe.outputs);
    }

    function _removeRecipe(uint64 _recipeId) private {
        RecipeInfo storage _recipeInfo = recipeIdToInfo[_recipeId];

        require(_recipeInfo.isActive, "Recipe is not active");

        _recipeInfo.isActive = false;

        for(uint256 i = 0; i < activeRecipeIds.length; i++) {
            if(_recipeId == activeRecipeIds[i]) {
                activeRecipeIds[i] = activeRecipeIds[activeRecipeIds.length - 1];
                activeRecipeIds.pop();
                break;
            }
        }

        emit WanderingMerchantRecipeRemoved(_recipeId);
    }

    function fulfillRecipes(FulfillRecipeParams[] calldata _params) external whenNotPaused onlyEOA {
        require(_params.length > 0, "Bad length");
        require(openTime != 0 && closeTime != 0 && openTime <= block.timestamp && block.timestamp < closeTime, "Merchant is not open");

        for(uint256 i = 0; i < _params.length; i++) {
            _fulfillRecipe(_params[i]);
        }
    }

    function _fulfillRecipe(FulfillRecipeParams calldata _params) private {
        RecipeInfo storage _recipeInfo = recipeIdToInfo[_params.recipeId];

        require(_recipeInfo.isActive, "Recipe is not active");
        require(_recipeInfo.currentAvailable > 0, "No more available");

        _recipeInfo.currentAvailable--;

        if(_recipeInfo.inputType == InputType.SQUIRE_POTIONS) {
            require(_params.inputTokenId == _recipeInfo.inputTokenId, "Input token id does not match");
            // Must set SquirePotions.setAllowedContracts(meem.address)
            squirePotions.burn(msg.sender, _params.inputTokenId, _recipeInfo.inputAmount);

        } else if(_recipeInfo.inputType == InputType.GEAR) {
            require(_params.inputTokenId == _recipeInfo.inputTokenId, "Input token id does not match");
            gear.burn(msg.sender, _params.inputTokenId, _recipeInfo.inputAmount);

        } else if(_recipeInfo.inputType == InputType.SQUIRE) {
            require(_recipeInfo.inputAmount == 1, "Cannot require more than one squire");
            squire.safeTransferFrom(msg.sender, address(0xdead), _params.inputTokenId, "");

        } else if(_recipeInfo.inputType == InputType.BLESSED_VILLAGER) {
            require(_recipeInfo.inputAmount == 1, "Cannot require more than one blessed villager");
            blessedVillager.burnBlessed(msg.sender, _params.inputTokenId);
            // burnBlessed() lives on different contract from the BlessedVillager contract
        } else {
            revert("Unknown input type");
        }

        for(uint32 i = 0; i < _recipeInfo.numberOfOutputs; i++) {

            Output storage _output = _recipeInfo.outputIndexToOutput[i];

            if(_output.outputType == OutputType.SQUIRE_POTIONS) {
                // squirePotions.mint() appears to have a hardcoded qty = 1
                for (uint32 j = 0; j < _output.amount; j++) {
                    squirePotions.mint(msg.sender, _output.tokenId);
                    // Must set SquirePotions.setAllowedContracts(meem.address)
                }

            } else if(_output.outputType == OutputType.GEAR) {
                // Must add meem.address as admin for Gear to allow meem to call gear.mint()
                gear.mint(msg.sender, _output.tokenId, _output.amount);

            } else if(_output.outputType == OutputType.TRANSFERRED_ERC20) {
                IERC20(_output.outputAddress).transferFrom(_output.transferredFrom, msg.sender, _output.amount);

            } else if(_output.outputType == OutputType.TRANSFERRED_ERC1155) {
                IERC1155(_output.outputAddress).safeTransferFrom(_output.transferredFrom, msg.sender, _output.tokenId, _output.amount, "");

            } else {
                revert("Unknown outputType");
            }
        }

        emit WanderingMerchantRecipeFulfilled(_params.recipeId, msg.sender);
    }

    function merchantInfo() external view returns(MerchantInfo memory merchantInfo_) {
        merchantInfo_.openTime = openTime;
        merchantInfo_.closeTime = closeTime;
        merchantInfo_.activeRecipes = new RecipeMerchantInfo[](activeRecipeIds.length);

        for(uint256 i = 0; i < activeRecipeIds.length; i++) {
            uint64 _recipeId = activeRecipeIds[i];
            RecipeInfo storage _recipeInfo = recipeIdToInfo[_recipeId];
            merchantInfo_.activeRecipes[i].recipeId = _recipeId;
            merchantInfo_.activeRecipes[i].currentAvailable = _recipeInfo.currentAvailable;
            merchantInfo_.activeRecipes[i].maxAvailable = _recipeInfo.maxAvailable;
            merchantInfo_.activeRecipes[i].inputTokenId = _recipeInfo.inputTokenId;
            merchantInfo_.activeRecipes[i].inputAmount = _recipeInfo.inputAmount;
            merchantInfo_.activeRecipes[i].inputType = _recipeInfo.inputType;

            merchantInfo_.activeRecipes[i].outputs = new Output[](_recipeInfo.numberOfOutputs);
            for(uint32 j = 0; j < _recipeInfo.numberOfOutputs; j++) {
                Output storage _output = _recipeInfo.outputIndexToOutput[j];
                merchantInfo_.activeRecipes[i].outputs[j].outputType = _output.outputType;
                merchantInfo_.activeRecipes[i].outputs[j].transferredFrom = _output.transferredFrom;
                merchantInfo_.activeRecipes[i].outputs[j].tokenId = _output.tokenId;
                merchantInfo_.activeRecipes[i].outputs[j].amount = _output.amount;
                merchantInfo_.activeRecipes[i].outputs[j].outputAddress = _output.outputAddress;
            }
        }
    }
}

struct MerchantInfo {
    uint128 openTime;
    uint128 closeTime;
    RecipeMerchantInfo[] activeRecipes;
}

struct FulfillRecipeParams {
    uint64 recipeId;
    uint32 inputTokenId;
}

struct Recipe {
    uint32 currentAvailable;
    uint32 maxAvailable;
    uint32 inputTokenId;
    uint256 inputAmount;
    InputType inputType;
    Output[] outputs;
}

struct RecipeMerchantInfo {
    uint64 recipeId;
    uint32 currentAvailable;
    uint32 maxAvailable;
    uint32 inputTokenId;
    uint256 inputAmount;
    InputType inputType;
    Output[] outputs;
}