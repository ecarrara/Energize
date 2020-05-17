extends Node

onready var title_ui = preload("res://ui/title.tscn")
onready var pause_ui = preload("res://ui/pause.tscn")
onready var win_ui = preload("res://ui/win.tscn")
onready var gameover_ui = preload("res://ui/gameover.tscn")

onready var gray_shader = preload("res://assets/gray.shader")
var gray_material = ShaderMaterial.new()

const levels = [
	preload("res://levels/level_1.tscn"),
	preload("res://levels/level_2.tscn"),
	preload("res://levels/level_3.tscn"),
	preload("res://levels/level_4.tscn"),
	preload("res://levels/level_5.tscn"),
	preload("res://levels/level_6.tscn"),
	preload("res://levels/level_7.tscn"),
	preload("res://levels/level_8.tscn"),
	preload("res://levels/level_9.tscn"),
	preload("res://levels/level_10.tscn"),
]

onready var camera_target = null
export var camera_speed = 10

export var current_level_index = 0
var current_level_instance = null

export var initial_timeleft = 30
export var extra_time_per_level = 10
var timeleft = null

var is_muted = false
var is_paused = false


func _create_level():
	var container = VBoxContainer.new()
	var label = Label.new()
	
	var level = levels[current_level_index].instance()
	label.set_text(str('Level ', current_level_index + 1))
	label.set_align(label.ALIGN_CENTER)
	
	container.alignment = BoxContainer.ALIGN_CENTER
	container.add_child(label)
	container.add_child(level)	

	$Container/Scenes.add_child(container)
	
	current_level_instance = container
	camera_target = container


func _create_title_ui():
	var Title = title_ui.instance()
	$Container/Scenes.add_child(Title)
	camera_target = Title


func _create_pause_ui():
	var Pause = pause_ui.instance()
	$Container/Scenes.add_child(Pause)
	$Canvas/PauseButton.visible = false
	camera_target = Pause
	
	
func _create_win_ui():
	var Win = win_ui.instance()
	$Container/Scenes.add_child(Win)
	$Canvas/PauseButton.visible = false
	camera_target = Win


func _create_gameover_ui():
	var Gameover = gameover_ui.instance()
	$Container/Scenes.add_child(Gameover)
	$Canvas/PauseButton.visible = false
	camera_target = Gameover


func _ready() -> void:
	_create_title_ui()
	gray_material.set_shader(gray_shader)

	
func _process(delta):
	if camera_target:
		$Camera2D.set_global_position(lerp($Camera2D.get_global_position(), camera_target.get_global_position() + camera_target.get_size() / 2, delta * camera_speed))


func _apply_grayscale(scene):
	scene.set_material(gray_material)
	

func _remove_grayscale(scene):
	scene.set_material(null)
	
	
func _disable_level(level):
	set_pause_scene(level, true)
	_apply_grayscale(level)
	

func _enable_level(level):
	set_pause_scene(level, false)
	_remove_grayscale(level)


func next_level():
	if current_level_index < len(levels):
		if current_level_instance:
			_disable_level(current_level_instance)
			
		_create_level()
		
		if current_level_index > 0:
			$Sounds/NextLevel.play()
			timeleft += extra_time_per_level
		
		current_level_index += 1
		
	else:
		win()

	
	#(Un)pauses a single node
func set_pause_node(node : Node, pause : bool) -> void:
	node.set_process(!pause)
	node.set_process_input(!pause)
	node.set_process_internal(!pause)
	node.set_process_unhandled_input(!pause)
	node.set_process_unhandled_key_input(!pause)

#(Un)pauses a scene
#Ignored childs is an optional argument, that contains the path of nodes whose state must not be altered by the function
func set_pause_scene(rootNode : Node, pause : bool, ignoredChilds : PoolStringArray = [null]):
	set_pause_node(rootNode, pause)
	for node in rootNode.get_children():
		if not (String(node.get_path()) in ignoredChilds):
			set_pause_scene(node, pause, ignoredChilds)


func _update_timer_label():
	$Canvas/Time.text = str(timeleft)
	
	
func _timer_tick():
	timeleft -= 1
	_update_timer_label()
	
	$Sounds/Tick.play()
	
	if timeleft == 0:
		gameover()


func _start_timer() -> void:
	$Canvas/Time.visible = true
	timeleft = initial_timeleft
	_update_timer_label()
	$Timer.start()
	

	
func _pause_timer() -> void:
	$Timer.paused = true


func _resume_timer() -> void:
	$Timer.paused = false


func _stop_timer() -> void:
	$Canvas/Time.visible = false
	$Timer.stop()

		
func start() -> void:
	_play_gui_sound()
	current_level_index = 0
	$Canvas/PauseButton.visible = true
	_start_timer()
	next_level()


func pause() -> void:
	_play_gui_sound()
	is_paused = true
	_disable_level(current_level_instance)
	_pause_timer()
	_create_pause_ui()
	

func resume() -> void:
	_play_gui_sound()
	is_paused = false
	var pause_scene = $Container/Scenes.get_node('Pause')
	$Container/Scenes.remove_child(pause_scene)
	pause_scene.queue_free()
	
	_enable_level(current_level_instance)
	var last_scene = $Container/Scenes.get_child($Container/Scenes.get_child_count() - 1)
	camera_target = last_scene
		
	_resume_timer()
	$Canvas/PauseButton.visible = true


func win() -> void:
	$Sounds/Win.play()
	_disable_level(current_level_instance)
	_stop_timer()
	_create_win_ui()


func gameover() -> void:
	$Sounds/Gameover.play()
	_disable_level(current_level_instance)
	_stop_timer()
	_create_gameover_ui()


func restart() -> void:
	_play_gui_sound()
	_resume_timer()
	start()


func toggle_mute() -> void:
	_play_gui_sound()
	if is_muted:
		$Sounds/Music.play()
		is_muted = false
	else:
		$Sounds/Music.stop()
		is_muted = true


func exit() -> void:
	get_tree().quit()


func _play_gui_sound() -> void:
	$Sounds/GUI.play()
