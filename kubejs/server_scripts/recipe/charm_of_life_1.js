ServerEvents.recipes(event => {
    event.shaped(Item.of('twilightforest:charm_of_life_1', 1), [
        'ABA',
        ' C ',
        ' D '
    ],
        {
            A: 'twilightforest:steeleaf_ingot',
            B: 'twilightforest:naga_scale',
            C: 'minecraft:totem_of_undying',
            D: 'twilightforest:experiment_115'
        })
})
