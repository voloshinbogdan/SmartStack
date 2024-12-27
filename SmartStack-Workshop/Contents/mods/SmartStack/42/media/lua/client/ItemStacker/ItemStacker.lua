require("ISUI/ISInventoryPage");
require("ISUI/PlayerData/ISPlayerData");
require("ISUI/ISLayoutManager");
require("TimedActions/ISTimedActionQueue");

-- Fields

ItemStacker = {};
ItemStacker.playerId = {};
ItemStacker.KEY_STACK_TO_SELECTED = "SmartStack_StackToSelected";
ItemStacker.KEY_STACK_TO_ALL = "SmartStack_StackToAll";
ItemStacker.config = { showBarButtons = nil, showContextMenuButtons = nil }

-- Initialization

-- adding keybinds
ItemStacker.addKeybinds = function()
    local bind = {};
    bind.value = "[SmartStack]"
    table.insert(keyBinding, bind);
    bind = {};
    bind.value = ItemStacker.KEY_STACK_TO_SELECTED;
    bind.key = Keyboard.KEY_NONE
    table.insert(keyBinding, bind);
    bind = {};
    bind.value = ItemStacker.KEY_STACK_TO_ALL;
    bind.key = Keyboard.KEY_NONE
    table.insert(keyBinding, bind);
end

ItemStacker.addModOptions = function()
    local options = PZAPI.ModOptions:create("966221273", "SmartStack")
    ItemStacker.config.showBarButtons = options:addTickBox("enable_bar_buttons", getText("UI_options_966221273_showBarButtons"), true, getText("UI_options_966221273_showBarButtons_tooltip"))
    ItemStacker.config.showContextMenuButtons = options:addTickBox("enable_context_menu_buttons", getText("UI_options_966221273_showContextMenuButtons"), true, getText("UI_options_966221273_showContextMenuButtons_tooltip"))
end

-- adding destination inventory bar buttons
ItemStacker.addContainerStackButton = function(playerId)
    ItemStacker.playerId = playerId;
    if ItemStacker.config.showBarButtons:getValue() == false then
        return
    end
    local playerLoot = getPlayerLoot(playerId);
    -- Stack: stack only to selected container
    local textWidth = getTextManager():MeasureStringX(UIFont.Small, getText("UI_StackToSelected"))
    local buttonX = playerLoot.toggleStove:getRight();
    local titleBarHeight = playerLoot:titleBarHeight()
    local stackToVisible = ISButton:new(buttonX, 1, textWidth, titleBarHeight, getText("UI_StackToSelected"), playerLoot, ItemStacker.stackItemsFromCurrentToSelected);
    ItemStacker.initializeButton(stackToVisible, playerLoot)
    -- Stack To All: stack to all available to the player at the moment containers
    textWidth = getTextManager():MeasureStringX(UIFont.Small, getText("UI_StackToAll"))
    local buttonX = stackToVisible:getRight();
    local stackToAll = ISButton:new(buttonX, 1, textWidth, titleBarHeight, getText("UI_StackToAll"), playerLoot, ItemStacker.stackItemsFromCurrentToNearby);
    ItemStacker.initializeButton(stackToAll, playerLoot)
end

-- adding context menus
ItemStacker.addStackContextMenuItems = function(player, context, items)
    if ItemStacker.config.showContextMenuButtons:getValue() == false then
        return
    end
    context:addOption(getText('UI_ContextMenu_StackToSelected'), getSpecificPlayer(player), ItemStacker.stackItemsFromCurrentToSelected)
    context:addOption(getText('UI_ContextMenu_StackToAll'), getSpecificPlayer(player), ItemStacker.stackItemsFromCurrentToNearby)
end

-- button helper
ItemStacker.initializeButton = function(button, parent)
    button:initialise();
    button.borderColor.a = 0.0;
    button.backgroundColor.a = 0.0;
    button.backgroundColorMouseOver.a = 0.7;
    parent:addChild(button);
    button:setVisible(true);
    button:setAnchorRight(false);
    button:setAnchorLeft(true);
end

-- hotkey listener

ItemStacker.onKeyPressed = function(key)
	if getSpecificPlayer(0) and getGameSpeed() > 0 and getPlayerInventory(0) and getCore():getGameMode() ~= "Tutorial" then
        if key == getCore():getKey(ItemStacker.KEY_STACK_TO_SELECTED) then
            ItemStacker.stackItemsFromCurrentToSelected()
        elseif key == getCore():getKey(ItemStacker.KEY_STACK_TO_ALL) then
            ItemStacker.stackItemsFromCurrentToNearby()
        end
    end
end

-- item stacking functionality

-- Stacks given items to destination containers, assuming that items are from one of the player's inventories
ItemStacker.stackItems = function(items, destinationContainers)
    local player = getPlayer();
    local hotBar = getPlayerHotbar(ItemStacker.playerId)
    -- fill added weights for each container with zero weight
    local addedWeight = {}
    for j = 1, #destinationContainers do
        addedWeight[destinationContainers[j]] = 0.0
    end

    for i = 0, items:size()-1 do
        local item = items:get(i);
        if not item:isEquipped() and item:getType() ~= "KeyRing" and not item:isFavorite() and not hotBar:isInHotbar(item) then
            for j = 1, #destinationContainers do
                local destinationContainer = destinationContainers[j];
                local sourceContainer = item:getContainer();
                if ItemStacker.canStackItem(item, destinationContainer, addedWeight[destinationContainer]) then
                    ISTimedActionQueue.add(ISInventoryTransferAction:new(player, item, sourceContainer, destinationContainer));
                    -- since queue fills synchronously and items transfer over time, we remember weight for
                    -- each added container to prevent container overflow
                    addedWeight[destinationContainer] = addedWeight[destinationContainer] + item:getUnequippedWeight();
                    break;
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
ItemStacker.canStackItem = function(item, container, addedWeight)
    -- Check if container has room for the item
    local playerObj = getSpecificPlayer(ItemStacker.playerId)
    if container:hasRoomFor(playerObj, item:getUnequippedWeight() + addedWeight) == false then
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

-- Subscribing to events

ItemStacker.addModOptions()
Events.OnGameBoot.Add(ItemStacker.addKeybinds);
Events.OnKeyPressed.Add(ItemStacker.onKeyPressed);
Events.OnCreatePlayer.Add(ItemStacker.addContainerStackButton);
Events.OnFillInventoryObjectContextMenu.Add(ItemStacker.addStackContextMenuItems);
