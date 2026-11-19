extends "res://scripts/base_jogo.gd"
## Jogo 1: Torre do Castelo.
## A torre ja comeca montada. A crianca SOPRA no celular:
##   - sopro fraco  -> a torre so balanca
##   - sopro forte  -> a torre cai devagar e aparece uma imagem dos temas de interesse
## QUALQUER sopro derruba a torre, do tamanho que ela estiver. A cada queda ela volta uma
## fileira maior (so pela diversao de ver crescer), ate chegar ao topo da tela.
## Enquanto a crianca sopra, o personagem fica quieto (a voz do app nao pode virar "sopro").
## Alternativa por toque (GDD: obrigatoria): segurar o dedo na torre funciona como soprar.
## Toque curto balanca, segurar derruba. Nada e erro: cair ou nao cair, tudo e brincadeira.

## Numero maximo de fileiras (a torre vai diminuindo de escala para caber ate o topo).
const NIVEL_MAX := 15
## Tempo seguido de sopro forte para derrubar (evita queda por um estalo de som).
const TEMPO_FORTE := 0.3
## Tamanho maximo da torre na tela (ela encolhe quando fica alta, para caber).
const ESCALA := 1.2
## Espaco livre no alto da tela (balao de fala e botoes).
const TOPO_LIVRE := 250.0

const COR_PEDRA := [Color("D5DDEA"), Color("C8D2E3")]
const COR_CONTORNO := Color("9FAEC6")
const COR_TELHADO := Color("F4A29B")
const COR_BANDEIRA := Color("8FD9C0")
const COR_JANELA := Color("5B6B85")


## Uma peca da torre, desenhada com codigo. Para usar arte propria, coloque
## assets/torre/fileira.png, ameias.png e telhado.png (mesmas proporcoes).
class Peca extends Control:
	var tipo := "fileira"   # fileira, ameias, telhado
	var linha := 0
	var janela := false

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		pivot_offset = size / 2.0
		var caminho := "res://assets/torre/%s.png" % tipo
		if ResourceLoader.exists(caminho):
			var t := TextureRect.new()
			t.texture = load(caminho)
			t.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			t.stretch_mode = TextureRect.STRETCH_SCALE
			t.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(t)

	func _draw() -> void:
		if get_child_count() > 0:
			return
		var w := size.x
		var h := size.y
		var pedra: Color = COR_PEDRA[linha % 2]
		match tipo:
			"fileira":
				_retangulo(Rect2(0, 0, w, h), pedra)
				# juntas dos tijolos, alternando a cada fileira
				var xs := [w / 3.0, w * 2.0 / 3.0] if linha % 2 == 0 else [w / 6.0, w / 2.0, w * 5.0 / 6.0]
				for x in xs:
					draw_line(Vector2(x, 6), Vector2(x, h - 6), COR_CONTORNO, 3.0, true)
				if janela:
					var jw := w * 0.22
					var jx := w / 2.0 - jw / 2.0
					draw_rect(Rect2(jx, h * 0.42, jw, h * 0.42), COR_JANELA)
					draw_circle(Vector2(w / 2.0, h * 0.42), jw / 2.0, COR_JANELA)
			"ameias":
				_retangulo(Rect2(0, h * 0.45, w, h * 0.55), pedra)
				var mw := w / 5.0
				for i in 3:
					_retangulo(Rect2(i * 2 * mw, 0, mw, h * 0.6), pedra)
			"telhado":
				var base_y := h
				var topo := Vector2(w / 2.0, h * 0.28)
				var pts := PackedVector2Array([Vector2(0, base_y), topo, Vector2(w, base_y)])
				draw_colored_polygon(pts, COR_TELHADO)
				draw_polyline(PackedVector2Array([Vector2(0, base_y), topo, Vector2(w, base_y), Vector2(0, base_y)]), COR_TELHADO.darkened(0.15), 4.0, true)
				# mastro e bandeira
				draw_line(topo, Vector2(w / 2.0, 0), COR_CONTORNO, 4.0, true)
				draw_colored_polygon(PackedVector2Array([Vector2(w / 2.0, 0), Vector2(w / 2.0 + 46, h * 0.08), Vector2(w / 2.0, h * 0.16)]), COR_BANDEIRA)

	func _retangulo(r: Rect2, cor: Color) -> void:
		var s := StyleBoxFlat.new()
		s.bg_color = cor
		s.set_corner_radius_all(10)
		s.set_border_width_all(3)
		s.border_color = COR_CONTORNO
		s.anti_aliasing = true
		draw_style_box(s, r)


enum { MONTANDO, EM_PE, CAINDO }

var estado := MONTANDO
var torre: Node2D
var pecas: Array[Control] = []
var bases: Array[Vector2] = []
var revelacao: Control = null
var zona_toque: Control

var _ang := 0.0
var _vel := 0.0
var _sopro := 0.0
var _sopro_ultimo := 0.0
var _vento_toque := 0.0
var _segurando := false
var _forte_t := 0.0
var _relogio := 0.0
var _disse_bamba := false
var _convidou_inativo := false
var _primeira_vez := true
var _subiu := false
var _montagem: Tween
var _ultimo_item := ""


func _ready() -> void:
	id_jogo = "torre"
	super._ready()


func _montar(a: Control) -> void:
	var tela := get_viewport_rect().size
	var chao_y := tela.y - 210.0

	var chao := Panel.new()
	chao.add_theme_stylebox_override("panel", UI.caixa(UI.CORES.grama, 28, 0))
	chao.position = Vector2(24, chao_y - 6)
	chao.size = Vector2(tela.x - 48, 44)
	chao.mouse_filter = Control.MOUSE_FILTER_IGNORE
	a.add_child(chao)

	torre = Node2D.new()
	torre.position = Vector2(tela.x / 2.0 + 30, chao_y)
	a.add_child(torre)

	# area de toque generosa sobre a torre (segurar = soprar)
	zona_toque = Control.new()
	zona_toque.position = Vector2(torre.position.x - 220, TOPO_LIVRE)
	zona_toque.size = Vector2(440, chao_y - TOPO_LIVRE + 10)
	zona_toque.mouse_filter = Control.MOUSE_FILTER_STOP
	zona_toque.gui_input.connect(_ao_tocar_torre)
	a.add_child(zona_toque)

	Microfone.sopro.connect(func(f):
		_sopro = f
		_sopro_ultimo = _relogio)
	if Microfone.ligar():
		mostrar_guia_microfone()
	else:
		_dica_toque()
	_construir(true)


func _recomecar() -> void:
	if estado == EM_PE:
		Fala.ciclo("torre", "inicio" if Perfil.nome() != "" else "inicio_sem_nome")
	elif estado == CAINDO:
		_reconstruir()


## Sem microfone: mostra uma maozinha sobre a torre por alguns segundos.
func _dica_toque() -> void:
	var mao := UI.rotulo("👆", 80)
	mao.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mao.position = torre.position + Vector2(-50, -260)
	mao.size = Vector2(100, 100)
	area.add_child(mao)
	var t := create_tween().set_loops(4)
	t.tween_property(mao, "position:y", mao.position.y - 24, 0.6)
	t.tween_property(mao, "position:y", mao.position.y, 0.6)
	var fim := create_tween()
	fim.tween_interval(5.0)
	fim.tween_property(mao, "modulate:a", 0.0, 0.6)
	fim.tween_callback(mao.queue_free)


# ------------------------------------------------------------ construcao

## Monta a torre: 5 fileiras de pedra (uma com janela), ameias e telhado com bandeira.
func _construir(inicio := false) -> void:
	estado = MONTANDO
	for p in pecas:
		p.queue_free()
	pecas.clear()
	bases.clear()
	_ang = 0.0
	_vel = 0.0
	_forte_t = 0.0
	_disse_bamba = false
	torre.rotation = 0.0
	# nivel 1 = 1 fileira de pedras; nivel 5 = 5 fileiras
	var fileiras := nivel()
	var defs := []
	for i in fileiras:
		defs.append({"tipo": "fileira", "tam": Vector2(230, 70), "janela": i == mini(1, fileiras - 1) and fileiras > 1})
	defs.append({"tipo": "ameias", "tam": Vector2(262, 62), "janela": false})
	defs.append({"tipo": "telhado", "tam": Vector2(290, 190), "janela": false})
	# altura total; se nao couber entre o chao e o topo livre, a torre encolhe
	var altura := 0.0
	for d in defs:
		altura += d.tam.y - 6.0
	var livre := torre.position.y - TOPO_LIVRE
	torre.scale = Vector2.ONE * minf(ESCALA, livre / altura)
	var y := 0.0
	if _montagem and _montagem.is_valid():
		_montagem.kill()
	var t := create_tween()
	_montagem = t
	# torre alta monta mais rapido: no maximo ~1,5 s no total
	var passo := minf(0.28, 1.5 / defs.size())
	for i in defs.size():
		var d: Dictionary = defs[i]
		var p := Peca.new()
		p.tipo = d.tipo
		p.linha = i
		p.janela = d.janela
		p.size = d.tam
		y += d.tam.y - (6.0 if i > 0 else 0.0)
		var base := Vector2(-d.tam.x / 2.0, -y)
		torre.add_child(p)
		pecas.append(p)
		bases.append(base)
		# cada peca desce suavemente do alto, de baixo para cima
		p.position = base + Vector2(0, -320)
		p.modulate.a = 0.0
		t.tween_property(p, "position", base, passo).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		t.parallel().tween_property(p, "modulate:a", 1.0, passo * 0.8)
	t.tween_callback(func():
		Fala.som("encaixe")
		estado = EM_PE
		if inicio or _primeira_vez:
			_primeira_vez = false
			Fala.ciclo("torre", "inicio" if Perfil.nome() != "" else "inicio_sem_nome")
		elif _subiu:
			Fala.ciclo("torre", "subiu")
		else:
			Fala.ciclo("torre", "de_novo"))


## Se o responsavel mudou o tamanho da torre nos ajustes, remonta no novo tamanho.
func _ao_fechar_ajustes() -> void:
	if estado == EM_PE and pecas.size() != nivel() + 2:
		_subiu = false
		_construir()


func nivel() -> int:
	return clampi(int(Perfil.config.nivel_torre), 1, NIVEL_MAX)


## Forca (0..1) que o sopro precisa ter para derrubar a torre neste nivel.
func limiar_queda() -> float:
	return 0.0  # qualquer sopro confirmado pelo microfone derruba


# ------------------------------------------------------------ sopro, toque e balanco

func _ao_tocar_torre(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed:
		_segurando = true
		registrar_toque()
		_vel += 0.35  # empurraozinho: toque curto ja balanca


func _input(e: InputEvent) -> void:
	if _segurando and e is InputEventMouseButton and not e.pressed:
		_segurando = false


func _process(delta: float) -> void:
	super._process(delta)
	if ajustes_abertos:
		return
	_relogio += delta
	if _relogio - _sopro_ultimo > 0.12:
		_sopro = 0.0
	if _sopro > 0.0:
		tempo_sem_toque = 0.0

	# segurar o dedo = soprar cada vez mais forte (ate 1.0 em ~1,6 s)
	if _segurando:
		_vento_toque = minf(1.0, _vento_toque + delta / 1.6)
	else:
		_vento_toque = maxf(0.0, _vento_toque - delta * 3.0)

	if estado == EM_PE:
		_balancar(delta, maxf(_sopro, _vento_toque))

	if tempo_sem_toque > 20.0 and not _convidou_inativo and not Fala.ocupado() and estado == EM_PE:
		_convidou_inativo = true  # convida UMA vez e depois so observa (GDD 10.5)
		Fala.ciclo("torre", "convite_inativo")
	if tempo_sem_toque < 1.0:
		_convidou_inativo = false


## Mola amortecida: o vento empurra, a torre volta. Fisica de mentirinha, previsivel.
func _balancar(delta: float, vento: float) -> void:
	var reduzido: bool = Perfil.config.movimento_reduzido
	var forca := 7.0 * (0.6 if reduzido else 1.0)
	# raiz: ate um sopro bem fraquinho faz a torre balancar de um jeito visivel
	var acel := -20.0 * _ang - 3.2 * _vel + forca * sqrt(vento)
	_vel += acel * delta
	_ang = clampf(_ang + _vel * delta, -0.4, 0.4)
	torre.rotation = _ang
	var n := pecas.size()
	for i in n:
		var frac := float(i + 1) / n
		pecas[i].rotation = _ang * 0.3 * frac          # torre "dobra" um pouco no alto
		pecas[i].position = bases[i] + Vector2(_ang * 60.0 * frac * frac, 0)

	if Perfil.config.torre_cai and vento > limiar_queda():
		_forte_t += delta
		if _forte_t >= TEMPO_FORTE:
			_derrubar()
	else:
		_forte_t = maxf(0.0, _forte_t - delta * 2.0)


# ------------------------------------------------------------ queda e revelacao

func _derrubar() -> void:
	estado = CAINDO
	_segurando = false
	var reduzido: bool = Perfil.config.movimento_reduzido
	var lado := 1.0 if _ang >= 0.0 else -1.0
	var dur := 0.9 if reduzido else 1.6
	Fala.som("queda")
	Fala.parar()  # a queda ja e a resposta da crianca: encerra a pausa e fala logo
	Fala.dizer("torre", "caiu")
	# o Node2D volta ao prumo e cada peca cai "em camera lenta" para o lado do vento
	var global_pecas := []
	for p in pecas:
		global_pecas.append(p.position.rotated(torre.rotation))
	torre.rotation = 0.0
	for i in pecas.size():
		var p := pecas[i]
		p.position = global_pecas[i]
		p.rotation = _ang
		# monte de pedras deitadas perto da base, sem sair da tela
		var destino := Vector2(lado * (i * 22.0) - p.size.x / 2.0 + randf_range(-30, 30), -p.size.y - randf_range(0, 40))
		var giro := lado * (0.3 if p.tipo == "telhado" else randf_range(-0.25, 0.25))
		var tb := create_tween().set_parallel()
		tb.tween_property(p, "position", destino, dur).set_delay(i * 0.07).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		tb.tween_property(p, "rotation", giro, dur).set_delay(i * 0.07)
	if not reduzido:
		_confetes()
	await get_tree().create_timer(dur * 0.6).timeout
	if not is_inside_tree():
		return
	_revelar()


## Aparece um elemento de interesse escolhido pelo responsavel (temas do perfil).
func _revelar() -> void:
	var itens := Perfil.itens_ativos().filter(func(i): return i.id != _ultimo_item)
	if itens.is_empty():
		itens = Perfil.itens_ativos()
	var item: Dictionary = itens.pick_random()
	_ultimo_item = item.id
	var centro := torre.position + Vector2(0, -420)
	revelacao = mostrar_revelacao(item, centro)
	Fala.ciclo("torre", "revelar", {"item": item.texto, "artigo": item.get("artigo", "")}, item)
	await esperar_ciclo(3.5)
	if not is_inside_tree() or estado != CAINDO:
		return
	_reconstruir()


func _reconstruir() -> void:
	# depois de cada queda, a torre volta um nivel maior (ate o nivel 5)
	_subiu = false
	if estado == CAINDO and nivel() < NIVEL_MAX:
		Perfil.definir("nivel_torre", nivel() + 1)
		_subiu = true
	esconder_revelacao(revelacao)
	revelacao = null
	var t := create_tween().set_parallel()
	for p in pecas:
		t.tween_property(p, "modulate:a", 0.0, 0.5)
	t.chain().tween_interval(0.3)
	t.chain().tween_callback(_construir)


func _confetes() -> void:
	var topo := torre.position + Vector2(0, -500)
	var cores := [UI.CORES.menta, UI.CORES.amarelo, UI.CORES.pessego, UI.CORES.lilas, UI.CORES.ceu]
	for i in 14:
		var c := ColorRect.new()
		c.size = Vector2(14, 14)
		c.color = cores.pick_random()
		c.position = topo
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		area.add_child(c)
		var fim := topo + Vector2(randf_range(-280, 280), randf_range(150, 520))
		var t := create_tween().set_parallel()
		t.tween_property(c, "position", fim, 2.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		t.tween_property(c, "modulate:a", 0.0, 2.2)
		t.chain().tween_callback(c.queue_free)
