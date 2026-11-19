extends Control
## Ajustes rapidos dentro do jogo (aberto pelo cadeado: segurar 3 s).
## O responsavel muda o tipo de fala e a sensibilidade do microfone sem sair do jogo.

signal fechado

var id_jogo := ""
var _medidor: ProgressBar
var _estado_sopro: Label
var _exemplo: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var veu := ColorRect.new()
	veu.color = Color(UI.CORES.texto, 0.35)
	veu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(veu)

	var m := MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "right"]:
		m.add_theme_constant_override("margin_" + lado, 20)
	m.add_theme_constant_override("margin_top", 40)
	m.add_theme_constant_override("margin_bottom", 40)
	add_child(m)
	var painel := UI.painel()
	m.add_child(painel)
	var rol := ScrollContainer.new()
	rol.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	painel.add_child(rol)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 14)
	rol.add_child(v)

	v.add_child(UI.rotulo("Ajustes rápidos", 34, UI.CORES.texto, HORIZONTAL_ALIGNMENT_LEFT))

	# ---- fala
	v.add_child(UI.titulo_secao("💬 Como o personagem fala"))
	_exemplo = _nota("")
	v.add_child(UI.seletor(["Só a palavra", "Com artigo", "Frase curta"], Perfil.config.nivel_apoio, func(i):
		Perfil.definir("nivel_apoio", i)
		_mostrar_exemplo()
		Fala.falar_texto(_frase_exemplo())))
	v.add_child(_exemplo)
	_mostrar_exemplo()

	# ---- microfone
	v.add_child(UI.titulo_secao("🎤 Sensibilidade do sopro"))
	if not Perfil.config.microfone:
		v.add_child(_nota("O microfone está desligado: a criança brinca pelo toque. Ligue em \"Todos os ajustes\"."))
	else:
		v.add_child(_nota("Mais para a direita = sopro mais fraquinho já funciona. Peça para a criança soprar e veja a barra."))
		v.add_child(UI.controle_sensibilidade())
		_medidor = UI.medidor_sopro()
		v.add_child(_medidor)
		_estado_sopro = _nota("")
		v.add_child(_estado_sopro)
		var recal := UI.botao("Medir o barulho do ambiente de novo", UI.CORES.superficie, 22, 72, UI.CORES.texto)
		recal.pressed.connect(func(): Microfone.calibrar())
		v.add_child(recal)

	# ---- torre
	if id_jogo == "torre":
		v.add_child(UI.titulo_secao("🏰 Torre"))
		v.add_child(_nota("Tamanho da torre agora (1 = pequena, cai com sopro fraquinho):"))
		v.add_child(UI.seletor(["1", "2", "3", "4", "5"], int(Perfil.config.nivel_torre) - 1, func(i):
			Perfil.definir("nivel_torre", i + 1)))
		v.add_child(_nota("Força para derrubar a torre maior:"))
		v.add_child(UI.seletor(["Fraca", "Média", "Forte"], Perfil.config.forca_derrubar, func(i):
			Perfil.definir("forca_derrubar", i)))

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	v.add_child(UI.espacador(8))
	v.add_child(h)
	var todos := UI.botao("Todos os ajustes", UI.CORES.superficie, 24, 84, UI.CORES.texto)
	todos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	todos.pressed.connect(func(): Jogo.ir_para("responsaveis", {"voltar_para": id_jogo}))
	h.add_child(todos)
	var fechar := UI.botao("Voltar ao jogo", UI.CORES.menta, 24, 84, UI.CORES.texto)
	fechar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fechar.pressed.connect(func():
		fechado.emit()
		queue_free())
	h.add_child(fechar)


func _nota(t: String) -> Label:
	return UI.rotulo(t, 22, UI.CORES.texto_suave, HORIZONTAL_ALIGNMENT_LEFT)


func _frase_exemplo() -> String:
	return Fala.frase("torre", "revelar", {"item": "banana", "artigo": "a"})


func _mostrar_exemplo() -> void:
	_exemplo.text = "Exemplo: \"%s\"" % _frase_exemplo()


func _process(_d: float) -> void:
	if _medidor:
		UI.atualizar_medidor(_medidor, _estado_sopro)
