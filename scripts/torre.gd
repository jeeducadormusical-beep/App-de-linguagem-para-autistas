extends "res://scripts/base_jogo.gd"
## Jogo 1: Torre de Blocos (GDD sec. 10).
## A crianca toca OU arrasta blocos para empilhar. A torre cresce, balanca e cai devagar.
## A queda nunca e erro: e parte da diversao. Fisica "de mentirinha", previsivel.

const ALT_COR := 76.0
const ALT_FIG := 112.0
const LARG := 168.0

var torre: Node2D
var blocos: Array[Control] = []
var bandeja: Array = []           # [{no, dados}]
var alvo := 8                     # altura em que a torre cai
var _proximo_evento := 3          # ciclo de comunicacao a cada 3-5 acoes (GDD 9.2)
var _acoes := 0
var _ocupado := false
var _arrastando: Control = null
var _arraste_dados := {}
var _arraste_slot := -1
var _caida := false
var _convidou_inativo := false
var _disse_bamba := false
var _disse_alta := false
var _t := 0.0


func _ready() -> void:
	id_jogo = "torre"
	super._ready()


func _altura_bloco() -> float:
	return ALT_FIG if Perfil.config.torre_blocos == 1 else ALT_COR


func _montar(a: Control) -> void:
	var w := get_viewport_rect().size.x
	var h := get_viewport_rect().size.y
	# chao firme
	var chao := Panel.new()
	var s := UI.caixa(UI.CORES.grama, 24, 0)
	chao.add_theme_stylebox_override("panel", s)
	chao.size = Vector2(w - 48, 36)
	chao.position = Vector2(24, h - 268)
	chao.mouse_filter = Control.MOUSE_FILTER_IGNORE
	a.add_child(chao)

	torre = Node2D.new()
	torre.position = Vector2(w / 2.0 + 60, h - 268)
	a.add_child(torre)

	# bandeja de blocos disponiveis (a direita do personagem)
	var fundo_bandeja := Panel.new()
	fundo_bandeja.add_theme_stylebox_override("panel", UI.caixa(Color(1, 1, 1, 0.6), 32, 0))
	fundo_bandeja.position = Vector2(204, h - 212)
	fundo_bandeja.size = Vector2(w - 228, 188)
	fundo_bandeja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	a.add_child(fundo_bandeja)
	for i in 3:
		bandeja.append({"no": null, "dados": {}})
		_repor_slot(i)

	personagem.tocado.connect(func():
		if _caida or blocos.is_empty():
			_reconstruir())
	_recomecar()


func _recomecar() -> void:
	_novo_alvo()
	var inicio := "inicio" if Perfil.nome() != "" else "inicio_sem_nome"
	Fala.ciclo("torre", inicio)


func _novo_alvo() -> void:
	var maximo := 6 if Perfil.config.torre_blocos == 1 else 9
	alvo = randi_range(maximo - 2, maximo)
	_disse_alta = false
	_disse_bamba = false


# ------------------------------------------------------------ bandeja

func _pos_slot(i: int) -> Vector2:
	var w := get_viewport_rect().size.x
	var h := get_viewport_rect().size.y
	var passo := (w - 228.0) / 3.0
	return Vector2(204.0 + passo * i + (passo - LARG) / 2.0, h - 212.0 + (188.0 - _altura_bloco()) / 2.0)


func _repor_slot(i: int) -> void:
	var dados := _sortear_bloco()
	var b := _criar_bloco(dados)
	b.position = _pos_slot(i)
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.gui_input.connect(_ao_tocar_slot.bind(i))
	area.add_child(b)
	bandeja[i] = {"no": b, "dados": dados}
	b.scale = Vector2.ZERO
	create_tween().tween_property(b, "scale", Vector2.ONE * 0.8, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _sortear_bloco() -> Dictionary:
	if Perfil.config.torre_blocos == 1:
		var itens := Perfil.itens_ativos()
		if itens.size() > 0:
			return {"item": itens.pick_random()}
	var cores: Array = Perfil.cores
	if Perfil.config.tema_calmo:
		cores = cores.filter(func(c): return c.id in ["azul", "verde"])
	return {"cor": cores.pick_random()} if cores.size() > 0 else {"cor": {"id": "azul", "texto": "azul", "cor": UI.CORES.primaria}}


func _criar_bloco(dados: Dictionary) -> Control:
	var b := Panel.new()
	var alt := _altura_bloco()
	b.size = Vector2(LARG, alt)
	b.pivot_offset = b.size / 2.0
	var s: StyleBoxFlat
	if dados.has("cor"):
		var c: Color = dados.cor.cor
		s = UI.caixa(c, 18, 0)
		s.border_width_bottom = 8
		s.border_color = c.darkened(0.15)
	else:
		s = UI.caixa(UI.CORES.superficie, 18, 0, 4, UI.CORES.lilas)
		s.border_width_bottom = 10
		var img := UI.imagem_item(dados.item, alt * 0.8)
		img.position = (b.size - img.custom_minimum_size) / 2.0
		b.add_child(img)
	b.add_theme_stylebox_override("panel", s)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b


# ------------------------------------------------------------ toque e arraste (GDD 10.2)

func _ao_tocar_slot(e: InputEvent, i: int) -> void:
	var pressionou: bool = e is InputEventMouseButton and e.pressed
	if not pressionou or _ocupado or _caida or _arrastando != null:
		return
	registrar_toque()
	var slot: Control = bandeja[i].no
	if slot == null:
		return
	if blocos.size() >= alvo and not Perfil.config.torre_cai:
		_esvaziar_suave()
		return
	_arrastando = slot
	_arraste_dados = bandeja[i].dados
	_arraste_slot = i
	bandeja[i].no = null
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.move_to_front()
	create_tween().tween_property(slot, "scale", Vector2(1.08, 1.08), 0.12)
	Fala.som("toque")


func _input(e: InputEvent) -> void:
	if _arrastando == null:
		return
	if e is InputEventMouseMotion:
		_arrastando.global_position = e.position - _arrastando.size / 2.0
	elif e is InputEventMouseButton and not e.pressed:
		# soltou em qualquer lugar: encaixe assistido no topo da torre
		var b := _arrastando
		_arrastando = null
		_colocar(b, _arraste_dados, _arraste_slot)


func _colocar(b: Control, dados: Dictionary, slot: int) -> void:
	_ocupado = true
	var alt := _altura_bloco()
	var local := Vector2(-LARG / 2.0, -alt * (blocos.size() + 1))
	var destino := torre.get_global_transform() * local
	var t := create_tween().set_parallel()
	t.tween_property(b, "global_position", destino, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(b, "scale", Vector2.ONE, 0.35)
	t.chain().tween_callback(func():
		b.reparent(torre, false)
		b.scale = Vector2.ONE
		b.position = local
		blocos.append(b)
		_ao_encaixar(b, dados)
		_repor_slot(slot)
		_ocupado = false)


func _ao_encaixar(b: Control, dados: Dictionary) -> void:
	Fala.som("encaixe")
	# brilho leve
	b.modulate = Color(1.15, 1.15, 1.15)
	create_tween().tween_property(b, "modulate", Color.WHITE, 0.5)
	_acoes += 1
	var n := blocos.size()

	if n >= alvo and Perfil.config.torre_cai:
		_derrubar()
		return
	if n == alvo - 2 and not _disse_alta:
		_disse_alta = true
		Fala.ciclo("torre", "alta")
		return
	if n == 5 and not _disse_bamba:
		_disse_bamba = true
		Fala.ciclo("torre", "bamba")
		return
	if _acoes >= _proximo_evento:
		_acoes = 0
		_proximo_evento = randi_range(3, 5)
		if dados.has("item"):
			var it: Dictionary = dados.item
			Fala.ciclo("torre", "item", {"item": it.texto, "artigo": it.artigo}, it)
		elif randf() < 0.5:
			Fala.ciclo("torre", "cor", {"cor": dados.cor.texto})
		else:
			Fala.ciclo("torre", "colocar")


# ------------------------------------------------------------ balanco e queda

func _process(delta: float) -> void:
	super._process(delta)
	_t += delta
	if torre and not _caida:
		var n := blocos.size()
		var amp := clampf((n - 3) * 0.9, 0.0, 5.0)
		if Perfil.config.movimento_reduzido:
			amp *= 0.4
		torre.rotation_degrees = sin(_t * 1.3) * amp
	if tempo_sem_toque > 20.0 and not _convidou_inativo and not Fala.ocupado():
		_convidou_inativo = true  # convida UMA vez e depois so observa (GDD 10.5)
		Fala.ciclo("torre", "convite_inativo")
	if tempo_sem_toque < 1.0:
		_convidou_inativo = false


func _derrubar() -> void:
	_caida = true
	var reduzido: bool = Perfil.config.movimento_reduzido
	var alt := _altura_bloco()
	var t := create_tween()
	t.tween_interval(0.6)
	t.tween_property(torre, "rotation_degrees", 0.0, 0.3)
	t.tween_callback(func():
		Fala.som("queda")
		Fala.ciclo("torre", "caiu")
		var lado := -1.0 if randf() < 0.5 else 1.0
		for i in blocos.size():
			var b := blocos[i]
			var destino := Vector2(lado * randf_range(40, 230) - LARG / 2.0, -alt + randf_range(-6, 0))
			var tb := create_tween().set_parallel()
			var dur := 1.6 if not reduzido else 0.9
			tb.tween_property(b, "position", destino, dur).set_delay(i * 0.06).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			tb.tween_property(b, "rotation_degrees", randf_range(-50, 50), dur).set_delay(i * 0.06)
		if not reduzido:
			_confetes())
	t.tween_interval(3.2)
	t.tween_callback(_reconstruir)


func _confetes() -> void:
	var topo := torre.get_global_transform() * Vector2(0, -_altura_bloco() * blocos.size())
	for i in 14:
		var c := ColorRect.new()
		c.size = Vector2(14, 14)
		c.color = (Perfil.cores.pick_random().cor as Color) if Perfil.cores.size() > 0 else UI.CORES.amarelo
		c.global_position = topo
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		area.add_child(c)
		var fim := topo + Vector2(randf_range(-260, 260), randf_range(200, 600))
		var t := create_tween().set_parallel()
		t.tween_property(c, "global_position", fim, 2.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		t.tween_property(c, "modulate:a", 0.0, 2.2)
		t.chain().tween_callback(c.queue_free)


## Torre reaparece sozinha, pronta para recomecar (GDD 10.2).
func _reconstruir() -> void:
	for b in blocos:
		var t := create_tween()
		t.tween_property(b, "modulate:a", 0.0, 0.5)
		t.tween_callback(b.queue_free)
	blocos.clear()
	_caida = false
	_novo_alvo()
	Fala.ciclo("torre", "de_novo")


## Quando a torre nao pode cair: no topo, os blocos somem devagar e recomeca.
func _esvaziar_suave() -> void:
	_caida = true
	var t := create_tween()
	t.tween_interval(0.2)
	t.tween_callback(_reconstruir)
