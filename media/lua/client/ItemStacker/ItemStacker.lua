require("ISUI/ISInventoryPage");
require("ISUI/PlayerData/ISPlayerData");
require("ISUI/ISLayoutManager");
require("TimedActions/ISTimedActionQueue");

ItemStacker = {};
ItemStacker.playerId = {};

ItemStacker.addContainerStackButton = function(playerId)
    ItemStacker.playerId = playerId;
    local playerLoot = getPlayerLoot(playerId);
    -- Stack: stack only to selected container
    local textWidth = getTextManager():MeasureStringX(UIFont.Small, getText("UI_StackToSelected"))
    local buttonX = playerLoot.width * 0.6
    local stackToVisible = ISButton:new(buttonX, 1, textWidth, 14, getText("UI_StackToSelected"), playerLoot, ItemStacker.stackItemsFromCurrentToSelected);
    ItemStacker.initializeButton(stackToVisible, playerLoot)
    -- Stack To All: stack to all available to the player at the moment containers
    textWidth = getTextManager():MeasureStringX(UIFont.Small, getText("UI_StackToAll"))
    local buttonX = stackToVisible:getRight();
    local stackToAll = ISButton:new(buttonX, 1, textWidth, 14, getText("UI_StackToAll"), playerLoot, ItemStacker.stackItemsFromCurrentToNearby);
    ItemStacker.initializeButton(stackToAll, playerLoot)
end

ItemStacker.initializeButton = function(button, parent)
    button:initialise();
    button.borderColor.a = 0.0;
    button.backgroundColor.a = 0.0;
    button.backgroundColorMouseOver.a = 0.7;
    parent:addChild(button);
    button:setVisible(true);
    button:setAnchorRight(true);
    button:setAnchorLeft(false);
end

-- Stacks given items to destination containers, assuming that items are from one of the player's inventories
ItemStacker.stackItems = function(items, destinationContainers)
    local player = getPlayer();
    local hotBar = getPlayerHotbar(ItemStacker.playerId)
    for i = 0, items:size()-1 do
        local item = items:get(i);
        if not item:isEquipped() and item:getType() ~= "KeyRing" and not item:isFavorite() and not hotBar:isInHotbar(item) then
            for j = 1, #destinationContainers do
                local destinationContainer = destinationContainers[j];
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
    -- Check if container has room for the item
    local playerObj = getSpecificPlayer(ItemStacker.playerId)
    if container:hasRoomFor(playerObj, item:getUnequippedWeight()) == false then
        return false;
    end
    -- Check if item is present in the container
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