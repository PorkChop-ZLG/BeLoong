// 该脚本用于 添加 护符 饰品兼容
ServerEvents.tags('item', event => {
  event.add('curios:charm', 'artifacts:charm_of_sinking')
  event.add('curios:charm', 'artifacts:charm_of_shrinking')
  event.add('curios:charm', 'irons_spellbooks:conjurers_talisman')
  event.add('curios:charm', 'irons_spellbooks:amethyst_resonance_charm')
  event.add('curios:charm', 'gametechbcs_spellbooks:amulet_of_spectral_shift')
  event.add('curios:charm', 'cataclysm:unbreakable_skull')
})