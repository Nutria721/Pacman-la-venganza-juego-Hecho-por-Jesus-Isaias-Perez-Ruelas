extends Area2D

signal hit

@export var speed = 400               # Velocidad normal
@export var dash_speed = 900          # Velocidad durante el dash
@export var dash_duration = 0.2       # Tiempo que dura el dash
@export var dash_cooldown = 0.8       # Tiempo antes de poder volver a hacer dash

var screen_size                       # Tamaño de la ventana
var is_dashing = false
var dash_time_left = 0.0
var dash_cooldown_left = 0.0

func _ready():
	screen_size = get_viewport_rect().size
	hide()


func _process(delta):
	var velocity = Vector2.ZERO

	# === Movimiento normal ===
	if Input.is_action_pressed("move_right"):
		velocity.x += 1
	if Input.is_action_pressed("move_left"):
		velocity.x -= 1
	if Input.is_action_pressed("move_down"):
		velocity.y += 1
	if Input.is_action_pressed("move_up"):
		velocity.y -= 1

	# === Iniciar Dash ===
	if Input.is_action_just_pressed("dash") and not is_dashing and dash_cooldown_left <= 0 and velocity != Vector2.ZERO:
		is_dashing = true
		dash_time_left = dash_duration
		dash_cooldown_left = dash_cooldown
		velocity = velocity.normalized() * dash_speed

	# === Mantener Dash activo ===
	elif is_dashing:
		dash_time_left -= delta
		if dash_time_left <= 0:
			is_dashing = false
		velocity = velocity.normalized() * dash_speed

	# === Movimiento normal si no hay dash ===
	else:
		if velocity.length() > 0:
			velocity = velocity.normalized() * speed
		dash_cooldown_left = max(dash_cooldown_left - delta, 0)

	# === Animaciones ===
	if velocity.length() > 0:
		$AnimatedSprite2D.play()
	else:
		$AnimatedSprite2D.stop()

	position += velocity * delta
	position = position.clamp(Vector2.ZERO, screen_size)

	# Animación según dirección
	if velocity.x != 0:
		$AnimatedSprite2D.animation = "right"
		$AnimatedSprite2D.flip_v = false
		$Trail.rotation = 0
		$AnimatedSprite2D.flip_h = velocity.x < 0
	elif velocity.y != 0:
		$AnimatedSprite2D.animation = "up"
		rotation = PI if velocity.y > 0 else 0

	# Mostrar trail solo en dash
	if is_dashing:
		$Trail.show()
	else:
		$Trail.hide()


func start(pos):
	position = pos
	rotation = 0
	show()
	$CollisionShape2D.disabled = false


func _on_body_entered(_body):
	hide() # Player desaparece al ser golpeado
	hit.emit()
	$CollisionShape2D.set_deferred("disabled", true)
