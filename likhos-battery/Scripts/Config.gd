extends RefCounted

# VANILLA draws no power: every sight looks and works as the game ships it.
# LIGHT_SENSOR lights scope reticles from sunset to sunrise.
enum ReticlePowerDraw { VANILLA, MANUAL, LIGHT_SENSOR }

@export var reticle_power_draw: ReticlePowerDraw = ReticlePowerDraw.MANUAL
