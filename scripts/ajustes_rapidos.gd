extends Control
## Ajustes rapidos dentro do jogo (aberto pelo cadeado: segurar 3 s).
## So o essencial: como o personagem fala e a forca do sopro, com o medidor ao vivo.

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
	var fora := VBoxContainer.new()
	fora.add_theme_constant_override("separation", 14)
	painel.add_child(fora)
	fora.add_child(UI.rotulo("Ajustes", 34, UI.CORES.texto, HORIZONTAL_ALIGNMENT_LEFT))
	var v := UI.coluna_rolavel(fora)

	# ---- fala
	v.add_child(UI.titulo_secao("💬 Como o personagem fala"))
	_exemplo = _nota("")
	v.add_child(UI.seletor(["Só a palavra", "Com artigo", "Frase curta"], Perfil.config.nivel_apoio, func(i):
		Perfil.definir("nivel_apoio", i)
		_mostrar_exemplo()
		Fala.falar_texto(_frase_exemplo())))
	v.add_child(_exemplo)
	_mostrar_exemplo()

	# ---- sopro
	v.add_child(UI.titulo_secao("🎤 Sopro da criança"))
	if not Perfil.config.microfone:
		v.add_child(_nota("O microfone está desligado: a criança brinca tocando na tela. Para ligar, use \"Mais configurações\"."))
	else:
		v.add_child(UI.controle_sopro())
		_medidor = UI.medidor_sopro()
		v.add_child(_medidor)
		_estado_sopro = UI.rotulo("", 24, UI.CORES.texto, HORIZONTAL_ALIGNMENT_LEFT)
		v.add_child(_estado_sopro)
		var medir := UI.botao("Medir o barulho do ambiente", UI.CORES.superficie, 22, 72, UI.CORES.texto)
		medir.pressed.connect(func(): Microfone.calibrar())
		v.add_child(medir)

	# ---- torre
	if id_jogo == "torre":
		v.add_child(UI.titulo_secao("🏰 Torre"))
		var pequena := UI.botao("Voltar para a torre pequena", UI.CORES.superficie, 22, 72, UI.CORES.texto)
		pequena.pressed.connect(func():
			Perfil.definir("nivel_torre", 1)
			pequena.text = "✅ A torre vai voltar pequena")
		v.add_child(pequena)

	# ---- botoes (fora da rolagem, sempre visiveis)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	fora.add_child(h)
	var todos := UI.botao("Mais configurações", UI.CORES.superficie, 22, 84, UI.CORES.texto)
	todos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	todos.pressed.connect(func(): Jogo.ir_para("responsaveis", {"voltar_para": id_jogo}))
	h.add_child(todos)
	var fechar := UI.botao("Voltar ao jogo", UI.CORES.menta, 22, 84, UI.CORES.texto)
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
