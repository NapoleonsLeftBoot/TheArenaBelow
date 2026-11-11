extends CanvasLayer

@export var player: Player
@export var boss: Player

@onready var player_bar: TextureProgressBar = $BetterPlayerBar
@onready var boss_bar: TextureProgressBar = $BetterBossBar
@onready var result_label: Label = $Result

@export var drain_time: float = 0.25

var match_over: bool = false

func _ready() -> void:

	_setup_bar(player, player_bar)
	_setup_bar(boss, boss_bar)

	var vp: Vector2 = get_viewport().get_visible_rect().size
	result_label.size = Vector2(700, 100)
	result_label.position = Vector2((vp.x - 700) / 2.0, vp.y / 2.0 - 50.0)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.visible = false

	player.ko.connect(_on_ko.bind(player))
	boss.ko.connect(_on_ko.bind(boss))

func _on_ko(fighter: Player) -> void:
	if match_over:
		return
	match_over = true

	if fighter == player:
		result_label.text = "YOU LOSE"
	else:
		result_label.text = "YOU WIN"
	result_label.visible = true
	await get_tree().create_timer(2.5).timeout
	get_tree().reload_current_scene()

func _setup_bar(fighter: Player, bar: TextureProgressBar) -> void:
	bar.max_value = fighter.max_health
	bar.value = fighter.max_health
	fighter.health_changed.connect(_on_health_changed.bind(bar))

func _on_health_changed(current: int, maximum: int, bar: TextureProgressBar) -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(bar, "value", current, drain_time)

	#bar.max_value = maximum
	#bar.value = current
