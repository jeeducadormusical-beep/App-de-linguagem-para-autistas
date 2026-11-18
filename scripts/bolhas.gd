extends "res://scripts/base_jogo.gd"
## Jogo 2: Bolhas de Sabao (GDD sec. 11).
## Soprar no microfone (ou segurar a varinha) cria bolhas. Tocar numa bolha revela uma
## imagem dos temas e o personagem fala o nome. Nada e "errado": bolha que chega ao topo
## estoura sozinha, sem revelar nada.

const MAX_BOLHAS := 14
const CORES_BOLHA := ["BFDCF7", "CBB8F0", "BFE6C8", "FFE29A", "FFC9A8"]


class Bolha extends Control:
	signal tocada(b)
	var cor := Color.WHITE
	var item := {}
	var vel := 80.0
	var fase := 0.0
	var x_base := 0.0
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


var bolhas: Array = []
var revelacao: Control = null
var varinha: Button
var _segurando := false
var _acumulado := 0.0
var _ultimo_surgem := -100.0
var _pops_vazios := 0
var _convidou_inativo := false
var _relogio := 0.0


func _ready() -> void:
	id_jogo = "bolhas"
	super._ready()


func _montar(a: Control) -> void:
	var w := get_viewport_rect().size.x
	var h := get_viewport_rect().size.y

	# varinha: alternativa por toque, sempre disponivel (GDD 11.2)
	varinha = UI.botao("✨", UI.CORES.lilas, 72, 170, UI.CORES.texto)
	varinha.position = Vector2(w - 194, h - 196)
	varinha.size = Vector2(170, 170)
	varinha.button_down.connect(func():
		_segurando = true
		registrar_toque()
		_criar_bolha(varinha.position + Vector2(85, 0)))
	varinha.button_up.connect(func(): _segurando = false)
	a.add_child(varinha)

	Microfone.sopro.connect(_ao_soprar)
	if Microfone.ligar():
		mostrar_guia_microfone()
	_recomecar()


func _recomecar() -> void:
	Fala.ciclo("bolhas", "convite")


func _ao_soprar(forca: float) -> void:
	tempo_sem_toque = 0.0
	# mais forca e mais tempo de sopro = mais bolhas (com limite)
	_acumulado += forca * get_process_delta_time() * 7.0
	if _relogio - _ultimo_surgem > 15.0 and not Fala.ocupado():
		_ultimo_surgem = _relogio
		Fala.dizer("bolhas", "surgem")


func _process(delta: float) -> void:
	super._process(delta)
	_relogio += delta
	var w := get_viewport_rect().size.x
	var h := get_viewport_rect().size.y

	if _segurando:
		_acumulado += delta * 3.0
	while _acumulado >= 1.0:
		_acumulado -= 1.0
		var origem := varinha.position + Vector2(85, 0) if _segurando else Vector2(w / 2.0 + randf_range(-120, 120), h - 120)
		_criar_bolha(origem)

	# quando ha muitas bolhas, todas ficam mais lentas (GDD 11.2)
	var lento := clampf(1.0 - bolhas.size() / 28.0, 0.5, 1.0)
	if Perfil.config.movimento_reduzido:
		lento *= 0.7
	for b in bolhas.duplicate():
		if b.estourando:
			continue
		b.fase += delta
		b.position.y -= b.vel * lento * delta
		b.position.x = b.x_base + sin(b.fase * 1.1) * 22.0
		if b.position.y < 150:
			_estourar(b, false)  # chegou ao topo: estoura sozinha, sem revelar

	if tempo_sem_toque > 20.0 and not _convidou_inativo and not Fala.ocupado():
		_convidou_inativo = true
		Fala.ciclo("bolhas", "convite")
	if tempo_sem_toque < 1.0:
		_convidou_inativo = false


func _criar_bolha(origem: Vector2) -> void:
	if bolhas.size() >= MAX_BOLHAS:
		return
	var b := Bolha.new()
	var d := randf_range(110, 180)
	b.size = Vector2(d, d)
	b.cor = Color(CORES_BOLHA.pick_random())
	b.vel = randf_range(55, 95)
	b.fase = randf() * TAU
	b.x_base = clampf(origem.x - d / 2.0 + randf_range(-60, 60), 10, get_viewport_rect().size.x - d - 10)
	b.position = Vector2(b.x_base, origem.y - d / 2.0)
	var itens := Perfil.itens_ativos()
	if randf() < 0.7 and itens.size() > 0:
		b.item = itens.pick_random()
	b.tocada.connect(_ao_tocar_bolha)
	area.add_child(b)
	bolhas.append(b)
	b.scale = Vector2(0.3, 0.3)
	create_tween().tween_property(b, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_SINE)
	Fala.som("bolha")


func _ao_tocar_bolha(b: Bolha) -> void:
	registrar_toque()
	var revelar := not b.item.is_empty() and revelacao == null
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
