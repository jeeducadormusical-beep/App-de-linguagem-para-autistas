extends Control
## Personagem amigo (GDD sec. 8). Desenhado com codigo simples enquanto a arte nao chega.
## Para usar a sua arte: coloque PNGs em assets/personagem/ com os nomes
##   observando.png, falando.png, esperando.png, celebrando.png, convidando.png
## Nao tem boca animada: expressa o estado com poses (pular, inclinar, bater palmas).

signal tocado

const COR_CORPO := Color("7FB2F0")
const COR_BARRIGA := Color("D6E7FB")
const COR_BOCHECHA := Color("F7B6C2")
const COR_OLHO := Color("2D3A4A")

var estado := 0
var _t := 0.0
var _textura: TextureRect
var _base_y := 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(180, 180)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_textura = TextureRect.new()
	_textura.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_textura.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_textura.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_textura.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_textura)
	resized.connect(func(): pivot_offset = Vector2(size.x / 2.0, size.y))
	Fala.estado_mudou.connect(_ao_mudar_estado)
	_ao_mudar_estado(Fala.estado, "", {})


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed:
		tocado.emit()
		Fala.resposta("respostas_toque")
		accept_event()


func _ao_mudar_estado(novo: int, _texto: String, _item: Dictionary) -> void:
	estado = novo
	var nomes := ["observando", "falando", "esperando", "celebrando", "convidando"]
	var caminho := "res://assets/personagem/%s.png" % nomes[novo]
	_textura.texture = load(caminho) if ResourceLoader.exists(caminho) else null
	var reduzido: bool = Perfil.config.movimento_reduzido
	var t := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	match novo:
		Fala.ESPERANDO:
			t.tween_property(self, "rotation_degrees", 7.0, 0.5)  # inclina a cabeca, atento
		Fala.CELEBRANDO:
			rotation_degrees = 0.0
			if not reduzido:
				t.tween_property(self, "position:y", position.y - 36, 0.22)
				t.tween_property(self, "position:y", position.y, 0.3).set_ease(Tween.EASE_IN)
			else:
				t.tween_property(self, "scale", Vector2(1.06, 1.06), 0.3)
				t.tween_property(self, "scale", Vector2.ONE, 0.3)
		_:
			t.tween_property(self, "rotation_degrees", 0.0, 0.4)
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	if _textura.texture == null:
		queue_redraw()


func _draw() -> void:
	if _textura.texture != null:
		return
	var reduzido: bool = Perfil.config.movimento_reduzido
	var respira := 0.0 if reduzido else sin(_t * 1.6) * 0.02
	var c := Vector2(size.x / 2.0, size.y * 0.58)
	var r := minf(size.x, size.y) * 0.38
	var ry := r * (1.0 + respira)
	# sombra no chao
	draw_set_transform(Vector2(c.x, size.y - 8), 0.0, Vector2(1.0, 0.22))
	draw_circle(Vector2.ZERO, r * 0.8, Color(0, 0, 0, 0.08))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# orelhinhas
	draw_circle(c + Vector2(-r * 0.62, -ry * 0.82), r * 0.24, COR_CORPO)
	draw_circle(c + Vector2(r * 0.62, -ry * 0.82), r * 0.24, COR_CORPO)
	# corpo (oval)
	draw_set_transform(c, 0.0, Vector2(1.0, ry / r))
	draw_circle(Vector2.ZERO, r, COR_CORPO)
	draw_circle(Vector2(0, r * 0.32), r * 0.58, COR_BARRIGA)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# bracinhos: para cima quando celebra ou convida (acenando)
	var cima := estado == Fala.CELEBRANDO or estado == Fala.CONVIDANDO
	var aceno := sin(_t * 5.0) * 0.25 if estado == Fala.CONVIDANDO and not reduzido else 0.0
	for lado in [-1.0, 1.0]:
		var ombro := c + Vector2(lado * r * 0.85, r * 0.05)
		var ang := (-2.2 + aceno if lado > 0 else -0.94 - aceno) if cima else (0.6 if lado > 0 else 2.54)
		var mao := ombro + Vector2(cos(ang), sin(ang)) * r * 0.5
		draw_line(ombro, mao, COR_CORPO, r * 0.22, true)
		draw_circle(mao, r * 0.13, COR_CORPO)
	# olhos (olham para cima quando esperam)
	var olhar := Vector2(0, -r * 0.05) if estado == Fala.ESPERANDO else Vector2.ZERO
	for lado in [-1.0, 1.0]:
		var o := c + Vector2(lado * r * 0.34, -ry * 0.28)
		draw_circle(o, r * 0.17, Color.WHITE)
		draw_circle(o + olhar + Vector2(0, r * 0.02), r * 0.1, COR_OLHO)
		draw_circle(o + olhar + Vector2(r * 0.03, -r * 0.02), r * 0.035, Color.WHITE)
	# bochechas
	draw_circle(c + Vector2(-r * 0.58, ry * 0.02), r * 0.11, COR_BOCHECHA)
	draw_circle(c + Vector2(r * 0.58, ry * 0.02), r * 0.11, COR_BOCHECHA)
	# sorriso fixo (sem boca animada - GDD sec. 8)
	var abre := 0.35 if estado == Fala.CELEBRANDO else 0.22
	draw_arc(c + Vector2(0, -ry * 0.02), r * abre, 0.35, PI - 0.35, 16, COR_OLHO, r * 0.06, true)
	# "estou falando": pulso suave ao lado
	if estado == Fala.FALANDO:
		var a := 0.35 + 0.25 * sin(_t * 4.0)
		for i in 3:
			draw_arc(c + Vector2(r * 1.05, -ry * 0.6), r * (0.18 + i * 0.14), -0.7, 0.7, 10, Color(COR_CORPO, a), r * 0.05, true)
