// 该脚本用于魔改合成类型 切石机

ServerEvents.recipes(event => {
    // 腾炎鞘翅胸甲 切成 腾炎胸甲
    event.stonecutting('cataclysm:ignitium_chestplate', 'cataclysm:ignitium_elytra_chestplate')
})
