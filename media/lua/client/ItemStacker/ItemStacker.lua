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
    ItemStacker.stackItemsButton = ISButton:new(buttonX, -1, 50, 14, getText("UI_StackAll"), playerLoot, ItemStacker.stackItemsFromCurrentInventory);
    ItemStacker.stackItemsButton:initialise();
    ItemStacker.stackItemsButton.borderColor.a = 0.0;
    ItemStacker.stackItemsButton.backgroundColor.a = 0.0;
    ItemStacker.stackItemsButton.backgroundColorMouseOver.a = 0.7;
    playerLoot:addChild(ItemStacker.stackItemsButton);
    ItemStacker.stackItemsButton:setVisible(true);
    ItemStacker.stackItemsButton:setAnchorRight(true);
    ItemStacker.stackItemsButton:setAnchorLeft(false);
end

ItemStacker.stackItemsFromCurrentInventory = function()
    local items = getPlayerInventory(ItemStacker.playerId).inventory:getItems();
    for i = 0, items:size()-1 do
        local item = items:get(i);
        if not item:isEquipped() and item:getType() ~= "KeyRing" then
            local lootInv = getPlayerLoot(ItemStacker.playerId).inventory;
            local player = getPlayer();
            local container = item:getContainer();
            if lootInv:contains(item:getType()) then
                ISTimedActionQueue.add(ISInventoryTransferAction:new(player, item, container, lootInv));
            end
        end
    end
end

Events.OnCreatePlayer.Add(ItemStacker.addContainerStackButton);