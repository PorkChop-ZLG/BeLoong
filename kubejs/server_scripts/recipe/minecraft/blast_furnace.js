// 该脚本用于魔改合成类型 高炉

ServerEvents.recipes(event => {
    event.blasting('irons_spellbooks:mithril_scrap', '#c:ingots/silver', 40.0, 600)
    event.blasting('irons_spellbooks:mithril_scrap', 'eternal_starlight:deepsilver_ingot', 60.0, 600)
})