extends SceneTree
## Roteiro do trailer: o jogo joga sozinho enquanto legendas curtas explicam.
## Rodar com --write-movie para gravar os quadros.

const CAMINHO_PERSONAGEM := "res://scripts/personagem.gd"

var camada: CanvasLayer
var legenda_painel: PanelContainer
var legenda: Label
var _sopro_ativo := 0.0
var _mic_falso := false
var _t := 0.0


func _initialize() -> void:
	_r.call_deferred()


func _process(delta: float) -> bool:
	_t += delta
	var mic = root.get_node_or_null("Microfone")
	if mic:
		if _sopro_ativo > 0.0:
			mic.sopro.emit(_sopro_ativo)
		if _mic_falso:
			# medidor de sopro "ao vivo" para a cena das configuracoes
			mic._calibrando = 0.0
			mic.ativo = true
			mic.ruido = 0.01
			mic.nivel = 0.01 * pow(10.0, (6.0 + 16.0 * (0.5 + 0.5 * sin(_t * 2.2))) / 20.0)
	return false


func esperar(s: float) -> void:
	await create_timer(s).timeout


func soprar(forca: float, seg: float) -> void:
	_sopro_ativo = forca
	await esperar(seg)
	_sopro_ativo = 0.0


# ------------------------------------------------------------ legendas e cartelas

func _montar_camada() -> void:
	var UI = root.get_node("UI")
	camada = CanvasLayer.new()
	camada.layer = 90
	root.add_child(camada)
	legenda_painel = PanelContainer.new()
	var s: StyleBoxFlat = UI.caixa(Color(0.16, 0.21, 0.29, 0.88), 30, 0)
	s.content_margin_left = 30
	s.content_margin_right = 30
	s.content_margin_top = 22
	s.content_margin_bottom = 22
	legenda_painel.add_theme_stylebox_override("panel", s)
	legenda_painel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	legenda_painel.offset_left = 28
	legenda_painel.offset_right = -28
	legenda_painel.offset_top = -250
	legenda_painel.offset_bottom = -110
	legenda_painel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	legenda_painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	legenda = UI.rotulo("", 34, Color.WHITE)
	legenda_painel.add_child(legenda)
	legenda_painel.modulate.a = 0.0
	camada.add_child(legenda_painel)


func dizer(texto: String) -> void:
	var t := legenda_painel.create_tween()
	if legenda_painel.modulate.a > 0.0:
		t.tween_property(legenda_painel, "modulate:a", 0.0, 0.25)
	t.tween_callback(func(): legenda.text = texto)
	t.tween_property(legenda_painel, "modulate:a", 1.0, 0.35)


func calar() -> void:
	legenda_painel.create_tween().tween_property(legenda_painel, "modulate:a", 0.0, 0.3)


## Cartela de tela cheia (titulo, frase), com o personagem.
func cartela(titulo: String, frase: String, segundos: float, com_personagem := true) -> void:
	var UI = root.get_node("UI")
	var c := Control.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var fundo := ColorRect.new()
	fundo.color = UI.CORES.fundo
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.add_child(fundo)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.add_child(centro)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 26)
	v.custom_minimum_size.x = 620
	centro.add_child(v)
	if com_personagem:
		var p := Control.new()
		p.set_script(load(CAMINHO_PERSONAGEM))
		p.custom_minimum_size = Vector2(280, 280)
		p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(p)
	if titulo != "":
		v.add_child(UI.rotulo(titulo, 68, UI.CORES.texto))
	if frase != "":
		v.add_child(UI.rotulo(frase, 38, UI.CORES.texto_suave))
	c.modulate.a = 0.0
	camada.add_child(c)
	camada.move_child(c, 0)
	var t := c.create_tween()
	t.tween_property(c, "modulate:a", 1.0, 0.5)
	await esperar(segundos)
	var t2 := c.create_tween()
	t2.tween_property(c, "modulate:a", 0.0, 0.5)
	t2.tween_callback(c.queue_free)
	await esperar(0.5)


# ------------------------------------------------------------ roteiro

func _r() -> void:
	var perfil = root.get_node("Perfil")
	var jogo = root.get_node("Jogo")
	var fala = root.get_node("Fala")
	perfil.config.consentimento = true
	perfil.config.nome = "Bia"
	perfil.config.temas = ["animais", "frutas"]
	perfil.config.microfone = true
	perfil.config.nivel_torre = 1
	perfil.config.nivel_apoio = 1
	perfil.config.pausa = 0
	perfil.config.repetir_modelo = false
	perfil.config.orientacao_sopro_dia = ""
	perfil.config.minutos_sessao = 60
	fala._sons.erase("neutro")  # sem voz sintetica aqui: nao toca o som substituto
	_montar_camada()

	# 1. abertura
	change_scene_to_file("res://scenes/hub.tscn")
	await cartela("Fala Brincando", "Brincar de soprar,\nouvir e falar", 4.0)
	await cartela("", "Um jogo calmo para crianças autistas que estão começando a se comunicar.", 3.6, false)

	# 2. hub
	fala.dizer("geral", "saudacao")
	dizer("O personagem cumprimenta a criança pelo nome.")
	await esperar(3.4)

	# 3. torre
	jogo.ir_para("torre")
	await esperar(0.8)
	dizer("Torre do Castelo: a criança sopra no celular.")
	await esperar(3.0)
	dizer("Sopro fraquinho: a torre balança.")
	await soprar(0.05, 2.2)
	await esperar(0.6)
	dizer("Um pouco mais forte: ela cai…")
	await soprar(0.25, 0.6)
	await esperar(1.6)
	dizer("…e aparece algo que a criança adora.")
	await esperar(4.2)
	var torre = current_scene
	while torre.estado != torre.EM_PE:
		await esperar(0.2)
	dizer("A cada queda, a torre cresce e pede um sopro um pouco mais forte.")
	await esperar(2.0)
	perfil.config.nivel_torre = 7
	torre._subiu = true
	torre._construir()
	await esperar(2.6)
	await soprar(0.55, 1.0)
	await esperar(3.4)
	calar()
	await esperar(0.5)

	# 4. bolhas
	jogo.ir_para("bolhas")
	await esperar(0.8)
	var bol = current_scene
	dizer("Bolhas de Sabão: cada sopro solta várias bolhas.")
	await esperar(1.0)
	await soprar(0.35, 1.6)
	await esperar(1.4)
	dizer("A criança toca e estoura…")
	for i in 2:
		var vazia = null
		for b in bol.bolhas:
			if b.item.is_empty() and b.position.y < 900:
				vazia = b
				break
		if vazia == null and bol.bolhas.size() > 0:
			vazia = bol.bolhas[0]
			vazia.item = {}
		if vazia:
			bol._ao_tocar_bolha(vazia)
		await esperar(0.9)
	var alvo = null
	for b in bol.bolhas:
		if b.position.y < 950:
			alvo = b
			break
	if alvo:
		alvo.item = perfil.itens_ativos()[2]
		bol._ao_tocar_bolha(alvo)
	await esperar(0.4)
	dizer("…e o personagem fala o nome do que apareceu.")
	await esperar(3.2)
	dizer("Ele fala, espera com calma e comemora qualquer resposta. Sem erro, sem pontos.")
	await esperar(4.2)
	calar()
	await esperar(0.4)

	# 5. configuracoes
	jogo.ir_para("responsaveis")
	await esperar(0.9)
	var rol: ScrollContainer = current_scene.find_children("*", "ScrollContainer", true, false)[0]
	_mic_falso = true
	var tr := rol.create_tween()
	tr.tween_property(rol, "scroll_vertical", 900, 1.4).set_trans(Tween.TRANS_SINE)
	dizer("Para os pais: o sopro se ajusta do fraco ao forte, no ritmo da criança.")
	await esperar(4.6)
	_mic_falso = false
	calar()
	await esperar(0.3)

	# 6. encerramento
	await cartela("", "Sem anúncios. Sem internet.\nNenhum áudio é gravado.", 3.4, false)
	await cartela("Fala Brincando", "Brincar de soprar,\nouvir e falar", 4.0)
	quit()
