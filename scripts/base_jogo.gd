extends Control
## Base de todo jogo (contrato do modulo - GDD 4 e 16.1). Cada jogo estende este script e
## ganha de graca: botao grande de casa, balao de fala, personagem, botao "ele respondeu",
## fim suave ("De novo?") e registro no diario.
##
## O jogo filho implementa:
##   func _montar(area: Control) -> void   # cria os elementos do jogo
##   func _recomecar() -> void             # opcional: chamado ao escolher "De novo"

const PersonagemScript := preload("res://scripts/personagem.gd")
const BalaoScript := preload("res://scripts/balao.gd")

var id_jogo := ""
var area: Control
var personagem: Control
var balao: PanelContainer
var tempo_sem_toque := 0.0

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

	# barra de cima: casa (livre para a crianca) e "ele respondeu" (discreto, do responsavel)
	var casa := UI.botao_icone("🏠", UI.CORES.superficie, 104)
	casa.position = Vector2(24, 36)
	casa.pressed.connect(func(): Jogo.ir_para("hub"))
	add_child(casa)

	var respondeu := UI.botao_icone("👍", UI.CORES.superficie, 80)
	respondeu.modulate.a = 0.45
	respondeu.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	respondeu.offset_left = -104
	respondeu.offset_right = -24
	respondeu.offset_top = 48
	respondeu.offset_bottom = 128
	respondeu.tooltip_text = "Ele respondeu (registro do responsável)"
	respondeu.pressed.connect(func():
		Fala.ele_respondeu()
		respondeu.modulate.a = 0.9
		create_tween().tween_property(respondeu, "modulate:a", 0.45, 0.8))
	add_child(respondeu)

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
	Perfil.iniciar_sessao(id_jogo)
	Microfone.ligar()


func _montar(_area: Control) -> void:
	pass


func _recomecar() -> void:
	pass


func _exit_tree() -> void:
	Perfil.encerrar_sessao()
	Microfone.desligar()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_RESUMED and is_inside_tree():
		Perfil.iniciar_sessao(id_jogo)
		Microfone.ligar()


func _process(delta: float) -> void:
	_tempo_sessao += delta
	tempo_sem_toque += delta
	if not _convite_aberto and _tempo_sessao > float(Perfil.config.minutos_sessao) * 60.0 and not Fala.ocupado():
		_abrir_convite()


## Os jogos chamam isto a cada toque da crianca.
func registrar_toque() -> void:
	tempo_sem_toque = 0.0
	Fala.resposta("respostas_toque")  # tocar no jogo durante a pausa tambem e resposta


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
