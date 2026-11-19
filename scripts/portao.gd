extends Control
## Portao dos responsaveis (GDD 6.1): segurar o cadeado por 3 segundos.
## Evita que a crianca entre na configuracao ou saia do modo crianca por acidente.

signal aberto

const TEMPO := 3.0

var _segurando := false
var _progresso := 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(88, 88)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_STOP
	var l := Label.new()
	l.text = "🔒"
	l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 34)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	modulate.a = 0.85


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton:
		_segurando = e.pressed
		if not e.pressed:
			_progresso = 0.0
			queue_redraw()
		accept_event()


func _process(delta: float) -> void:
	if not _segurando:
		return
	_progresso += delta / TEMPO
	queue_redraw()
	if _progresso >= 1.0:
		_segurando = false
		_progresso = 0.0
		aberto.emit()


func _draw() -> void:
	var c := size / 2.0
	var r := minf(size.x, size.y) / 2.0 - 4
	draw_circle(c, r, Color(1, 1, 1, 0.8))
	if _progresso > 0.0:
		draw_arc(c, r - 3, -PI / 2.0, -PI / 2.0 + TAU * _progresso, 48, UI.CORES.primaria, 7.0, true)
