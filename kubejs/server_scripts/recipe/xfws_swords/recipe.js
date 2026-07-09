ServerEvents.recipes(event => {
    // 移除 鸿蒙方舟 的配方
    event.remove({ id: 'xfws_swords:ark_of_the_cosmos' })
})
