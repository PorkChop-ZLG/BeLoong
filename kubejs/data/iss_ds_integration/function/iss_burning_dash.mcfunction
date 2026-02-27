# 该方程用于施展 地火斩

# 施展 烈焰冲锋
cast @a[tag=iss_fire3] burning_dash 5
# 延迟施展 炽焰斩击 ，防止连招被覆盖
schedule function iss_ds_integration:iss_flaming_strike 0.1s
