// 禁用物品列表
let bannedItems = [
    'touhou_little_maid_spell:chaos_book',
    'touhou_little_maid_spell:soul_book'
];

// 移除禁用物品的所有合成配方
ServerEvents.recipes(event => {
    bannedItems.forEach(itemId => {
        event.remove({ output: itemId });
    });
});

// 物品变化监听
PlayerEvents.inventoryChanged(event => {
    const player = event.player;
    const changedItem = event.item;
    const inventory = player.inventory.items;
    // 处理禁用物品
    if (bannedItems.includes(changedItem.id)) {
        event.server.tell([
            Text.darkRed("[警告] ").bold(),
            Text.gold(changedItem.id).bold(),
            Text.gray("这件物品已被禁用")
        ]);
        // 移除物品
        for (let i = 0; i < inventory.length; i++) {
            if (inventory[i]?.id === changedItem.id) {
                inventory[i].count = 0;
            }
        }
        return;
    }
});

// 世界掉落物监听
EntityEvents.spawned(event => {
    const entity = event.entity;
    if (entity.type !== 'minecraft:item') return;
    const item = entity.item;
    if (!item) return;
    if (bannedItems.includes(item.id)) {
        entity.discard();
    }
});