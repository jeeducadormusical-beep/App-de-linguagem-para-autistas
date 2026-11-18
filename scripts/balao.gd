extends PanelContainer
## Balao de fala: texto grande e legivel, sempre na mesma posicao (GDD 8 e 13).
## Mostra a imagem do objeto quando a fala se refere a ele (apoio visual).
## Fica visivel durante a fala e a pausa; some devagar depois.

var _texto: RichTextLabel
var _imagem_box: Control


func _ready() -> void:
	var s := UI.caixa(UI.CORES.superficie, 32, 10)
	s.content_margin_left = 28
	s.content_margin_right = 28
	s.content_margin_top = 18
	s.content_margin_bottom = 18
	add_theme_stylebox_override("panel", s)
	custom_minimum_size.y = 120
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 18)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(h)
	_imagem_box = CenterContainer.new()
	_imagem_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(_imagem_box)
	_texto = RichTextLabel.new()
	_texto.bbcode_enabled = true
	_texto.fit_content = true
	_texto.scroll_active = false
	_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_texto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_texto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_texto.add_theme_font_size_override("normal_font_size", UI.fonte(46))
	_texto.add_theme_font_size_override("bold_font_size", UI.fonte(46))
	_texto.add_theme_color_override("default_color", UI.CORES.texto)
	h.add_child(_texto)
	modulate.a = 0.0
	Fala.estado_mudou.connect(_ao_mudar)


func _ao_mudar(estado: int, texto: String, item: Dictionary) -> void:
	if estado == Fala.OBSERVANDO:
		_sumir()
		return
	if estado == Fala.ESPERANDO:
		return  # o texto permanece enquanto a pausa estiver ativa
	for f in _imagem_box.get_children():
		f.queue_free()
	if not item.is_empty():
		_imagem_box.add_child(UI.imagem_item(item, 96))
	var mostrar_texto: bool = Perfil.config.texto_ligado
	_texto.visible = mostrar_texto
	if mostrar_texto:
		var palavra: String = item.get("texto", "")
		var bb := texto
		if palavra != "" and bb.containsn(palavra):
			# destaca a palavra-chave
			var i := bb.findn(palavra)
			bb = bb.substr(0, i) + "[color=#3F6FD1][b]" + bb.substr(i, palavra.length()) + "[/b][/color]" + bb.substr(i + palavra.length())
		_texto.text = "[center]" + bb + "[/center]"
	if not mostrar_texto and item.is_empty():
		_sumir()
		return
	var t := create_tween()
	t.tween_property(self, "modulate:a", 1.0, 0.25)


func _sumir() -> void:
	var t := create_tween()
	t.tween_interval(0.5)
	t.tween_property(self, "modulate:a", 0.0, 0.6)
