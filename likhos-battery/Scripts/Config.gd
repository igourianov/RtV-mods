extends RefCounted

# DISABLED draws no power: the beam, the dot or the reticle looks and works as the game ships it, whatever the charge.
enum LaserPowerDraw { DISABLED, ENABLED }
enum RedDotPowerDraw { DISABLED, ALWAYS_ON }
# LIGHT_SENSOR lights scope reticles from sunset to sunrise.
enum ScopePowerDraw { DISABLED, MANUAL, LIGHT_SENSOR }

static var instance := new()

@export_group("Lasers")
@export var laser_power_draw: LaserPowerDraw = LaserPowerDraw.ENABLED

@export_group("Sights")
@export var red_dot_power_draw: RedDotPowerDraw = RedDotPowerDraw.ALWAYS_ON
@export var scope_power_draw: ScopePowerDraw = ScopePowerDraw.MANUAL
