extends Area2D

var tile_size = 32 * scale
var character_pos = Vector2(0,0)
var is_moving = false	

var tilemap_layer = {
	"BASE":0,
	"COLLISION":1,
	"SPECIAL":2
	}

var tile_type = {
	"WALKABLE":0,
	"COLLISION":1,
	"DIRECTIONAL":2,
	"ICE":3,
	"TELEPORT":4
	}

var direction_tile = {
	"RIGHT": 0,
	"LEFT": 5,
	"DOWN": 6,	
	"UP": 7
	}

#Set initial position of character
func _ready():
	$Timer.start()
	character_pos=Vector2(-1,-1)
	position = Vector2(character_pos[0]*tile_size.x + tile_size.x/2,character_pos[1]*tile_size.y + tile_size.y/2)
	
	
func move(position_delta):
	var tween = create_tween()
	var target_pos = position + position_delta * tile_size
	tween.tween_property(self,"position", target_pos, 0.4)
	is_moving = true
	$AnimatedSprite2D.play()
	
	character_pos += position_delta
	
	await tween.finished
	is_moving = false
	$AnimatedSprite2D.stop()

func teleport():
	is_moving = true
	
	var link = {
		Vector2(1,2):Vector2(5,-3),
		Vector2(5,-3):Vector2(1,2),
		Vector2(1,-2):Vector2(-2,-3),
		Vector2(-2,-3):Vector2(1,-2),
		Vector2(-2,2):Vector2(-7,7),
		Vector2(-7,7):Vector2(-2,2)
	}
	
	var tween = create_tween()
	tween.tween_property(self,"modulate", Color(1,1,1,0.0), 0.7)
	await tween.finished
	
	
	character_pos = link[character_pos]
	position = character_pos * tile_size + Vector2(tile_size.x/2,tile_size.y/2)
	modulate = Color(1,1,1,1)
	
	is_moving = false

func process_collision(position_delta, tilemap):
	#If next tile is not a collision tile
	if not is_instance_valid(tilemap):
		await move(position_delta)
	
	elif tilemap.get_class() == "Area2D":
		return
	#Colliding
	else:
		if is_instance_valid(tilemap.get_cell_tile_data(tilemap_layer["COLLISION"],character_pos + position_delta)):
			return
		
		#If next tile is a forced movement tile
		elif is_instance_valid(tilemap.get_cell_tile_data(tilemap_layer["SPECIAL"],character_pos + position_delta)):	
			#move to the special tile
			await move(position_delta)
			
			#get the data of the forced movement tile
			var tile_data = tilemap.get_cell_tile_data(tilemap_layer["SPECIAL"],character_pos)
			
			#If it's a directional tile, change the direction
			if tile_data.get_custom_data("tile_type") == tile_type["DIRECTIONAL"]:
				if tilemap.get_cell_alternative_tile(tilemap_layer["SPECIAL"],character_pos) == direction_tile["RIGHT"]:
					position_delta = Vector2.RIGHT
				elif tilemap.get_cell_alternative_tile(tilemap_layer["SPECIAL"],character_pos) == direction_tile["LEFT"]:
					position_delta = Vector2.LEFT
				elif tilemap.get_cell_alternative_tile(tilemap_layer["SPECIAL"],character_pos) == direction_tile["DOWN"]:
					position_delta = Vector2.DOWN
				elif tilemap.get_cell_alternative_tile(tilemap_layer["SPECIAL"],character_pos) == direction_tile["UP"]:
					position_delta = Vector2.UP
					
			
				
				#process the collision of the next tile
				$AnimatedSprite2D.animation = "spin"
				process_collision(position_delta,tilemap)
				return
			elif tile_data.get_custom_data("tile_type") == tile_type["ICE"]:
				
				if position_delta == Vector2.RIGHT:
					$AnimatedSprite2D.animation = "slide_side"
				if position_delta == Vector2.LEFT:
					$AnimatedSprite2D.animation = "slide_side"
					$AnimatedSprite2D.flip_h = true
				if position_delta == Vector2.UP:
					$AnimatedSprite2D.animation = "slide_back"
				if position_delta == Vector2.DOWN:
					$AnimatedSprite2D.animation = "slide_front"
				process_collision(position_delta, tilemap)
				return
				
			elif tile_data.get_custom_data("tile_type") == tile_type["TELEPORT"]:
				teleport()
				
			else:
				print("This Should Not Happen")
				
		else:
			if $RayCast2D.is_colliding():
				return
			await move(position_delta)
		


func _on_timer_timeout():
	
	if is_moving:
		return
	
	var rng = RandomNumberGenerator.new()
	
	var mob_direction = rng.randi_range(0, 3)
	var position_delta = Vector2.ZERO
	if mob_direction==0:
		position_delta = Vector2.RIGHT
		$AnimatedSprite2D.animation = "side"
		$AnimatedSprite2D.flip_h = false
	elif mob_direction==1:
		position_delta = Vector2.LEFT
		$AnimatedSprite2D.animation = "side"
		$AnimatedSprite2D.flip_h = true
	elif mob_direction==2:
		position_delta = Vector2.UP
		$AnimatedSprite2D.animation = "back"
	elif mob_direction==3:
		position_delta = Vector2.DOWN
		$AnimatedSprite2D.animation = "front"
	else:
		return
	
		
	# The following code block casts a ray one tile in the direction of
	# position delta
	$RayCast2D.target_position = position_delta * tile_size / scale
	$RayCast2D.force_raycast_update()
			
	# Processes if there is a collision in the direction the user wants to go to and acts
	# accordingly
	process_collision(position_delta, $RayCast2D.get_collider())
	
	$RayCast2D.target_position = Vector2(0,0)
