extends "res://scripts/base_jogo.gd"
## Jogo 2: Bolhas de Sabao (GDD sec. 11).
## Na tela aparece o brinquedo de fazer bolhas (aro com pelicula de sabao e cabo): a crianca
## ve e ja entende que e para soprar. Ao soprar, a pelicula estufa e as bolhas saem do aro.
## Tocar e segurar o aro tambem faz bolhas (alternativa por toque). Tocar numa bolha revela uma
## imagem dos temas e o personagem fala o nome. Nada e "errado": bolha que chega ao topo
## estoura sozinha, sem revelar nada.

const MAX_BOLHAS := 18
## Cada sopro (ou toque no brinquedo) solta logo uma rajada de bolhas para a crianca ter opcoes.
const RAJADA := 4
## Bolhas por segundo enquanto sopra: sopro fraquinho -> poucas, sopro forte -> muitas.
const TAXA_FRACA := 1.5
const TAXA_FORTE := 10.0
## Chance de uma bolha esconder uma imagem, e quantas bolhas "vazias" estourar antes de revelar.
const CHANCE_IMAGEM := 0.4
const POPS_ANTES_DE_REVELAR := 2
const CORES_BOLHA := ["BFDCF7", "CBB8F0", "BFE6C8", "FFE29A", "FFC9A8"]


class Bolha extends Control:
	signal tocada(b)
	var cor := Color.WHITE
	var item := {}
	var vel := 80.0
	var fase := 0.0
	var x_base := 0.0
	var vx := 0.0
	var estourando := false

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		pivot_offset = size / 2.0

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and not estourando:
			# so conta toque dentro do circulo
			if e.position.distance_to(size / 2.0) <= size.x / 2.0 + 10:
				tocada.emit(self)
				accept_event()

	func _draw() -> void:
		var c := size / 2.0
		var r := size.x / 2.0
		draw_circle(c, r, Color(cor, 0.28))
		draw_arc(c, r - 2, 0, TAU, 48, Color(cor.darkened(0.1), 0.75), 4.0, true)
		draw_arc(c, r * 0.68, -2.5, -1.7, 12, Color(1, 1, 1, 0.85), r * 0.1, true)
		draw_circle(c + Vector2(r * 0.42, -r * 0.42), r * 0.08, Color(1, 1, 1, 0.8))


## Brinquedo de bolha de sabao desenhado por codigo (aro + pelicula + cabo).
## Para usar arte propria, coloque assets/imagens/brinquedo_bolha.png (o aro no alto da imagem).
class Brinquedo extends Control:
	signal apertado
	const COR_ARO := Color("F4A29B")
	const COR_CABO := Color("B39DDB")
	var raio := 86.0
	var estufar := 0.0      # 0..1: a pelicula estufa enquanto a crianca sopra
	var _t := 0.0
	var _textura: Texture2D

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		var caminho := "res://assets/imagens/brinquedo_bolha.png"
		if ResourceLoader.exists(caminho):
			_textura = load(caminho)

	## Centro do aro, em coordenadas da tela.
	func centro_aro() -> Vector2:
		return global_position + Vector2(size.x / 2.0, raio + 20)

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			apertado.emit()
			accept_event()

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var c := Vector2(size.x / 2.0, raio + 20)
		if _textura:
			draw_texture_rect(_textura, Rect2(Vector2.ZERO, size), false)
			return
		# cabo
		var base := Vector2(size.x / 2.0 + 10, size.y - 10)
		draw_line(c + Vector2(0, raio), base, COR_CABO.darkened(0.15), 30.0, true)
		draw_line(c + Vector2(0, raio), base, COR_CABO, 22.0, true)
		draw_circle(base, 15, COR_CABO)
		# pelicula de sabao (brilho que muda devagar) e a bolha estufando
		var brilho := Color.from_hsv(fmod(_t * 0.05, 1.0), 0.25, 1.0, 0.35)
		draw_circle(c, raio - 6, brilho)
		if estufar > 0.02:
			var rb := raio * (0.6 + estufar * 0.6)
			var cb := c + Vector2(0, -estufar * raio * 0.9)
			draw_circle(cb, rb, Color(1, 1, 1, 0.18))
			draw_arc(cb, rb, 0, TAU, 48, Color(0.75, 0.85, 1.0, 0.6), 3.0, true)
		draw_arc(c, raio * 0.62, -2.6, -1.8, 12, Color(1, 1, 1, 0.8), 7.0, true)
		# aro
		draw_arc(c, raio, 0, TAU, 64, COR_ARO.darkened(0.15), 22.0, true)
		draw_arc(c, raio, 0, TAU, 64, COR_ARO, 15.0, true)
		draw_arc(c, raio + 2, -2.4, -1.4, 16, Color(1, 1, 1, 0.55), 4.0, true)


var bolhas: Array = []
var revelacao: Control = null
var brinquedo: Brinquedo
var _segurando := false
var _acumulado := 0.0
var _ultimo_surgem := -100.0
var _pops_vazios := 0
var _convidou_inativo := false
var _relogio := 0.0
var _ultimo_sopro := -100.0
var _pops_desde_revelar := 0


func _ready() -> void:
	id_jogo = "bolhas"
	super._ready()


func _montar(a: Control) -> void:
	var w := get_viewport_rect().size.x
	var h := get_viewport_rect().size.y

	# brinquedo de bolha no centro, perto da parte de baixo (onde fica o microfone)
	brinquedo = Brinquedo.new()
	brinquedo.size = Vector2(240, 430)
	brinquedo.position = Vector2(w / 2.0 - 120 + 40, h - 470)
	brinquedo.pivot_offset = Vector2(120, 430)
	brinquedo.rotation_degrees = 8
	brinquedo.apertado.connect(func():
		_segurando = true
		registrar_toque()
		_rajada())
	a.add_child(brinquedo)

	Microfone.sopro.connect(_ao_soprar)
	if Microfone.ligar():
		mostrar_guia_microfone()
	_recomecar()


func _recomecar() -> void:
	Fala.ciclo("bolhas", "convite")


func _input(e: InputEvent) -> void:
	if _segurando and e is InputEventMouseButton and not e.pressed:
		_segurando = false


func _ao_soprar(forca: float) -> void:
	tempo_sem_toque = 0.0
	# comecou a soprar agora: ja solta uma rajada de bolhas
	if _relogio - _ultimo_sopro > 0.4:
		_rajada()
	_ultimo_sopro = _relogio
	# enquanto sopra: mais forca = mais bolhas por segundo (com limite na tela)
	_acumulado += lerpf(TAXA_FRACA, TAXA_FORTE, forca) * get_process_delta_time()


func _process(delta: float) -> void:
	super._process(delta)
	if ajustes_abertos:
		return
	_relogio += delta
	var w := get_viewport_rect().size.x
	var h := get_viewport_rect().size.y

	if _segurando:
		_acumulado += delta * 4.0
	while _acumulado >= 1.0:
		_acumulado -= 1.0
		_criar_bolha()

	# a pelicula estufa enquanto sopra e volta quando para; parado, o brinquedo "respira"
	var soprando := _segurando or _relogio - _ultimo_sopro < 0.2
	brinquedo.estufar = move_toward(brinquedo.estufar, 1.0 if soprando else 0.0, delta * 3.0)
	if not soprando and not Perfil.config.movimento_reduzido:
		var s := 1.0 + 0.03 * sin(_relogio * 2.0)
		brinquedo.scale = Vector2(s, s)
	else:
		brinquedo.scale = Vector2.ONE

	# quando ha muitas bolhas, todas ficam mais lentas (GDD 11.2)
	var lento := clampf(1.0 - bolhas.size() / 28.0, 0.5, 1.0)
	if Perfil.config.movimento_reduzido:
		lento *= 0.7
	for b in bolhas.duplicate():
		if b.estourando:
			continue
		b.fase += delta
		b.position.y -= b.vel * lento * delta
		# saem do aro com um empurraozinho para os lados e vao freando
		b.x_base = clampf(b.x_base + b.vx * delta, 10, w - b.size.x - 10)
		b.vx *= pow(0.4, delta)
		b.position.x = b.x_base + sin(b.fase * 1.1) * 22.0
		if b.position.y < 150:
			_estourar(b, false)  # chegou ao topo: estoura sozinha, sem revelar

	# "Bolhas!" so depois que a crianca para de soprar (a voz do app nao pode cortar o sopro)
	var parou_ha := _relogio - _ultimo_sopro
	if parou_ha > 0.6 and parou_ha < 1.0 and _relogio - _ultimo_surgem > 15.0 and not Fala.ocupado():
		_ultimo_surgem = _relogio
		Fala.dizer("bolhas", "surgem")

	if tempo_sem_toque > 20.0 and not _convidou_inativo and not Fala.ocupado():
		_convidou_inativo = true
		Fala.ciclo("bolhas", "convite")
	if tempo_sem_toque < 1.0:
		_convidou_inativo = false


## Rajada: varias bolhas saem do aro de uma vez, para a crianca ter opcoes para tocar.
func _rajada() -> void:
	for i in RAJADA:
		_criar_bolha(lerpf(-1.0, 1.0, (i + 0.5) / RAJADA))


## Cria uma bolha saindo do aro. `lado` (-1..1) escolhe para onde ela vai (aleatorio se nada).
func _criar_bolha(lado := 2.0) -> void:
	if bolhas.size() >= MAX_BOLHAS:
		return
	if lado > 1.5:
		lado = randf_range(-1.0, 1.0)
	var origem := brinquedo.centro_aro() + Vector2(0, -40)
	var b := Bolha.new()
	var d := randf_range(105, 165)
	b.size = Vector2(d, d)
	b.cor = Color(CORES_BOLHA.pick_random())
	b.vel = randf_range(45, 80)  # sobem devagar, para dar tempo de tocar
	b.fase = randf() * TAU
	b.x_base = clampf(origem.x - d / 2.0, 10, get_viewport_rect().size.x - d - 10)
	b.vx = lado * randf_range(260, 420)
	b.position = Vector2(b.x_base, origem.y - d / 2.0)
	var itens := Perfil.itens_ativos()
	if randf() < CHANCE_IMAGEM and itens.size() > 0:
		b.item = itens.pick_random()
	b.tocada.connect(_ao_tocar_bolha)
	area.add_child(b)
	bolhas.append(b)
	# nasce pequena no aro e cresce enquanto se solta
	b.scale = Vector2(0.25, 0.25)
	create_tween().tween_property(b, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_SINE)
	Fala.som("bolha")


func _ao_tocar_bolha(b: Bolha) -> void:
	registrar_toque()
	# a crianca experimenta alguns estouros antes de aparecer uma imagem
	var revelar := not b.item.is_empty() and revelacao == null and _pops_desde_revelar >= POPS_ANTES_DE_REVELAR
	_pops_desde_revelar = 0 if revelar else _pops_desde_revelar + 1
	_estourar(b, revelar)
	if not revelar:
		_pops_vazios += 1
		if _pops_vazios % 3 == 0:
			Fala.dizer("bolhas", "estourar")


func _estourar(b: Bolha, revelar: bool) -> void:
	b.estourando = true
	bolhas.erase(b)
	Fala.som("pop")
	var t := create_tween().set_parallel()
	t.tween_property(b, "scale", Vector2(1.3, 1.3), 0.25)
	t.tween_property(b, "modulate:a", 0.0, 0.25)
	t.chain().tween_callback(b.queue_free)
	if revelar:
		_revelar(b.item)


## A imagem aparece grande no centro (GDD 11.2), o personagem fala o nome.
func _revelar(item: Dictionary) -> void:
	var tela := get_viewport_rect().size
	revelacao = mostrar_revelacao(item, Vector2(tela.x / 2.0, tela.y / 2.0 - 70))
	Fala.ciclo("bolhas", "revelar", {"item": item.texto, "artigo": item.get("artigo", "")}, item)
	await esperar_ciclo(3.0)
	if not is_inside_tree() or revelacao == null:
		return
	esconder_revelacao(revelacao)
	revelacao = null
	if Fala.estado != Fala.CONVIDANDO:
		Fala.dizer("bolhas", "fim_revelar")
