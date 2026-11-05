extends CanvasLayer

@export var player: Player
@export var boss: Player

@onready var player_bar: ProgressBar = $PlayerBar
@onready var boss_bar: ProgressBar = $BossBar

func _ready() -> void:
	_setup_bar(player, player_bar)
	_setup_bar(boss, boss_bar)
	
func _setup_bar(fighter: Player, bar: ProgressBar) -> void:
	bar.max_value = fighter.max_health
	bar.value = fighter.max_health
	fighter.health_changed.connect(_on_health_changed.bind(bar))

func _on_health_changed(current: int, maximum: int, bar: ProgressBar) -> void:
	bar.max_value = maximum
	bar.value = current
