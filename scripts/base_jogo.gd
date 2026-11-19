extends Control
## Base de todo jogo (contrato do modulo - GDD 4 e 16.1). Cada jogo estende este script e
## ganha de graca: botao grande de casa, balao de fala, personagem, cadeado de ajustes
## rapidos e fim suave ("De novo?").
##
## O jogo filho implementa:
##   func _montar(area: Control) -> void   # cria os elementos do jogo
##   func _recomecar() -> void             # opcional: chamado ao escolher "De novo"

const PersonagemScript := preload("res://scripts/personagem.gd")
const BalaoScript := preload("res://scripts/balao.gd")
const PortaoScript := preload("res://scripts/portao.gd")
const AjustesScript := preload("res://scripts/ajustes_rapidos.gd")

var id_jogo := ""
var area: Control
var personagem: Control
var balao: PanelContainer
var tempo_sem_toque := 0.0
## true enquanto o painel de ajustes rapidos estiver aberto (o jogo fica parado).
var ajustes_abertos := false

var _tempo_sessao := 0.0
var _convite_aberto := false
var _sobreposicao: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var fundo := ColorRect.new()
	fundo.color = UI.cor_fundo()
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fundo)

	area = Control.new()
	area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	area.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(area)

	# barra de cima: casa (livre para a crianca) e cadeado (do responsavel)
	var casa := UI.botao_icone("🏠", UI.CORES.superficie, 104)
	casa.position = Vector2(24, 36)
	casa.pressed.connect(func(): Jogo.ir_para("hub"))
	add_child(casa)

	# cadeado do responsavel: segurar 3 s abre os ajustes rapidos sem sair do jogo
	var portao := Control.new()
	portao.set_script(PortaoScript)
	portao.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	portao.offset_left = -108
	portao.offset_right = -20
	portao.offset_top = 44
	portao.offset_bottom = 132
	portao.aberto.connect(_abrir_ajustes)
	add_child(portao)

	balao = PanelContainer.new()
	balao.set_script(BalaoScript)
	balao.set_anchors_preset(Control.PRESET_TOP_WIDE)
	balao.offset_left = 148
	balao.offset_right = -120
	balao.offset_top = 32
	add_child(balao)

	personagem = Control.new()
	personagem.set_script(PersonagemScript)
	personagem.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	personagem.offset_left = 12
	personagem.offset_right = 192
	personagem.offset_top = -196
	personagem.offset_bottom = -16
	add_child(personagem)

	_montar(area)
	Microfone.ligar()


func _montar(_area: Control) -> void:
	pass


func _recomecar() -> void:
	pass


func _exit_tree() -> void:
	Microfone.desligar()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_RESUMED and is_inside_tree():
		Microfone.ligar()


func _process(delta: float) -> void:
	if ajustes_abertos:
		return
	_tempo_sessao += delta
	tempo_sem_toque += delta
	if not _convite_aberto and _tempo_sessao > float(Perfil.config.minutos_sessao) * 60.0 and not Fala.ocupado():
		_abrir_convite()


## Imagem de interesse grande, num circulo branco, centralizada em `centro` (GDD 11.2).
func mostrar_revelacao(item: Dictionary, centro: Vector2) -> Control:
	var r := PanelContainer.new()
	r.add_theme_stylebox_override("panel", UI.caixa(UI.CORES.superficie, 200, 12))
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.add_child(UI.imagem_item(item, 300))
	area.add_child(r)
	r.size = Vector2(380, 380)
	r.position = centro - r.size / 2.0
	r.pivot_offset = r.size / 2.0
	r.scale = Vector2(0.4, 0.4)
	r.modulate.a = 0.0
	var t := create_tween().set_parallel()
	t.tween_property(r, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(r, "modulate:a", 1.0, 0.3)
	return r


## Some com a revelacao devagar.
func esconder_revelacao(r: Control) -> void:
	if r == null or not is_instance_valid(r):
		return
	var t := create_tween().set_parallel()
	t.tween_property(r, "modulate:a", 0.0, 0.6)
	t.tween_property(r, "scale", Vector2(0.8, 0.8), 0.6)
	t.chain().tween_callback(r.queue_free)


## Espera o ciclo de comunicacao atual terminar (minimo `minimo` segundos).
func esperar_ciclo(minimo := 3.0) -> void:
	await get_tree().create_timer(minimo).timeout
	while is_inside_tree() and Fala.ocupado() and Fala.estado != Fala.CONVIDANDO:
		await get_tree().create_timer(0.3).timeout


## Mostra de onde sai o sopro (microfone), so na primeira vez do dia (GDD 11.4).
func mostrar_guia_microfone() -> void:
	if not Microfone.ativo:
		return
	var hoje := Time.get_date_string_from_system()
	if Perfil.config.orientacao_sopro_dia == hoje:
		return
	Perfil.definir("orientacao_sopro_dia", hoje)
	var h := get_viewport_rect().size.y
	var guia := VBoxContainer.new()
	guia.mouse_filter = Control.MOUSE_FILTER_IGNORE
	guia.add_child(UI.rotulo("📱", 96))
	var seta := UI.rotulo("⬇️ 🎤", 56)
	guia.add_child(seta)
	guia.position = Vector2(24, h - 470)
	guia.size = Vector2(200, 240)
	area.add_child(guia)
	var t := create_tween().set_loops(4)
	t.tween_property(seta, "modulate:a", 0.3, 0.7)
	t.tween_property(seta, "modulate:a", 1.0, 0.7)
	var fim := create_tween()
	fim.tween_interval(6.0)
	fim.tween_property(guia, "modulate:a", 0.0, 0.8)
	fim.tween_callback(guia.queue_free)


## Os jogos chamam isto a cada toque da crianca.
func registrar_toque() -> void:
	tempo_sem_toque = 0.0
	Fala.resposta("respostas_toque")  # tocar no jogo durante a pausa tambem e resposta


# ------------------------------------------------------------ ajustes rapidos

func _abrir_ajustes() -> void:
	if ajustes_abertos:
		return
	ajustes_abertos = true
	Fala.parar()
	var painel := Control.new()
	painel.set_script(AjustesScript)
	painel.id_jogo = id_jogo
	painel.fechado.connect(func():
		ajustes_abertos = false
		_ao_fechar_ajustes())
	add_child(painel)


## Os jogos podem reagir quando os ajustes mudam (ex.: a torre muda de tamanho).
func _ao_fechar_ajustes() -> void:
	pass


# ------------------------------------------------------------ fim suave (GDD 5.1)

func _abrir_convite() -> void:
	_convite_aberto = true
	Fala.convidar(Fala.frase("geral", "convite_fim"))
	_sobreposicao = Control.new()
	_sobreposicao.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_sobreposicao)
	var veu := ColorRect.new()
	veu.color = Color(UI.cor_fundo(), 0.85)
	veu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sobreposicao.add_child(veu)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sobreposicao.add_child(centro)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 28)
	centro.add_child(v)
	var p := Control.new()
	p.set_script(PersonagemScript)
	p.custom_minimum_size = Vector2(240, 240)
	v.add_child(p)
	if Perfil.config.texto_ligado:
		v.add_child(UI.rotulo(Fala.frase("geral", "convite_fim"), 46))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 28)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(h)
	var de_novo := UI.botao("🔁", UI.CORES.menta, 64, 180, UI.CORES.texto)
	de_novo.pressed.connect(_fechar_convite)
	h.add_child(de_novo)
	var casa := UI.botao("🏠", UI.CORES.amarelo, 64, 180, UI.CORES.texto)
	casa.pressed.connect(func(): Jogo.ir_para("hub"))
	h.add_child(casa)
	_sobreposicao.modulate.a = 0.0
	create_tween().tween_property(_sobreposicao, "modulate:a", 1.0, 0.5)


func _fechar_convite() -> void:
	Fala.parar()
	_tempo_sessao = 0.0
	_convite_aberto = false
	_sobreposicao.queue_free()
	_recomecar()
