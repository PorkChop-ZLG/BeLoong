ServerEvents.recipes(event => {
    // 移除所有天顶剑配方
    event.remove({ id: 'zenith:zenith' })
    event.remove({ id: 'zenith:true_wooden_sword' })
    event.remove({ id: 'zenith:zenith_from_true_wooden_sword' })
})
