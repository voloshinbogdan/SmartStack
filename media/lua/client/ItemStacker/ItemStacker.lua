require("ISUI/ISInventoryPage");
require("ISUI/PlayerData/ISPlayerData");
require("ISUI/ISLayoutManager");
require("TimedActions/ISTimedActionQueue");

ItemStacker = {};
ItemStacker.playerId = {};
ItemStacker.stackItemsButton = {};

ItemStacker.addContainerStackButton = function(playerId)
    ItemStacker.playerId = playerId;
    local playerLoot = getPlayerLoot(playerId);
    local buttonX = playerLoot.transferAll:getX() - getTextManager():MeasureStringX(UIFont.Small, getText("UI_StackAll")) - 10;
    ItemStacker.stackItemsButton = ISButton:new(buttonX, -1, 50, 14, getText("UI_StackAll"), playerLoot, ItemStacker.stackItemsFromCurrentToSelected);
    ItemStacker.stackItemsButton:initialise();
    ItemStacker.stackItemsButton.borderColor.a = 0.0;
    ItemStacker.stackItemsButton.backgroundColor.a = 0.0;
    ItemStacker.stackItemsButton.backgroundColorMouseOver.a = 0.7;
    playerLoot:addChild(ItemStacker.stackItemsButton);
    ItemStacker.stackItemsButton:setVisible(true);
    ItemStacker.stackItemsButton:setAnchorRight(true);
    ItemStacker.stackItemsButton:setAnchorLeft(false);
end

-- Stacks given items to destination containers, assuming that items are from one of the player's inventories
ItemStacker.stackItems = function(items, destinationContainers)
    for i = 0, items:size()-1 do
        local item = items:get(i);
        if not item:isEquipped() and item:getType() ~= "KeyRing" and not item:isFavorite() then
            for j = 1, #destinationContainers do
                local destinationContainer = destinationContainers[j];
                local player = getPlayer();
                local sourceContainer = item:getContainer();
                if ItemStacker.canStackItem(item, destinationContainer) then
                    ISTimedActionQueue.add(ISInventoryTransferAction:new(player, item, sourceContainer, destinationContainer));
                end
            end
        end
    end
end

-- Stacks items from current player's inventory to nearby containers
ItemStacker.stackItemsFromCurrentToNearby = function ()
    local nearbyContainers =  getPlayerLoot(ItemStacker.playerId).inventoryPane.inventoryPage.backpacks;
    local destinationContainers = {};
    for i = 1, #nearbyContainers do
        destinationContainers[i] = nearbyContainers[i].inventory;
    end
    local items = getPlayerInventory(ItemStacker.playerId).inventory:getItems();
    ItemStacker.stackItems(items, destinationContainers);
end

-- Stacks items from currentplayer's inventory to selected loot container
ItemStacker.stackItemsFromCurrentToSelected = function()
    local destinationContainers = { getPlayerLoot(ItemStacker.playerId).inventory };
    local items = getPlayerInventory(ItemStacker.playerId).inventory:getItems();
    ItemStacker.stackItems(items, destinationContainers);
end

-- Checks if item can be stacked to given container
ItemStacker.canStackItem = function(item, container)
    local itemName = ItemStacker.getGenericItemName(item:getType());
    local items = container:getItems();
    for i = 0, items:size()-1 do
        local itemFromContainer = items:get(i):getType();
        itemFromContainer = ItemStacker.getGenericItemName(itemFromContainer);
        if itemName == itemFromContainer then
            return true;
        end
    end
    
    return false;
end

-- Eliminates digits in the end of the item name 
ItemStacker.getGenericItemName = function(itemName)
    while tonumber(itemName:sub(-1, -1)) ~= nil do
        itemName = itemName:sub(1, -2);
    end
    
    return itemName;
end

Events.OnCreatePlayer.Add(ItemStacker.addContainerStackButton);