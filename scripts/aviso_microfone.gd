extends Control
## Aviso (pop-up) sobre qual microfone usar. Alguns celulares tem microfone pouco sensivel:
## um fone com microfone ou um microfone de lapela perto da boca da crianca resolve.

signal fechado


## Icones desenhados por codigo: "fone", "lapela" ou "celular".
class IconeMic extends Control:
	var tipo := "fone"
	const AZUL := Color("5B8DEF")
	const AZUL_CLARO := Color("A9C7F7")
	const ESCURO := Color("2D3A4A")
	const CINZA := Color("C8D2E3")

	func _ready() -> void:
		custom_minimum_size = Vector2(130, 130)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var c := Vector2(w / 2.0, h / 2.0)
		draw_circle(c, minf(w, h) * 0.48, Color("EEF5FB"))
		match tipo:
			"fone":
				# arco da cabeca, conchas e a haste com o microfone ate a boca
				draw_arc(c + Vector2(0, 6), 42, PI, TAU, 32, AZUL_CLARO, 10.0, true)
				_ret(Rect2(c.x - 56, c.y - 2, 22, 40), AZUL)
				_ret(Rect2(c.x + 34, c.y - 2, 22, 40), AZUL)
				var pts := PackedVector2Array()
				for i in 13:
					var t := i / 12.0
					pts.append(Vector2(lerpf(c.x - 40, c.x + 2, t), c.y + 34 + sin(t * PI) * 16))
				draw_polyline(pts, ESCURO, 5.0, true)
				draw_circle(Vector2(c.x + 6, c.y + 36), 8, ESCURO)
			"lapela":
				# capsula com espuma, presilha e fio enrolado
				_ret(Rect2(c.x - 13, c.y - 44, 26, 40), ESCURO)
				draw_circle(Vector2(c.x, c.y - 44), 14, Color("4A5A70"))
				_ret(Rect2(c.x - 18, c.y - 6, 36, 14), CINZA)
				var fio := PackedVector2Array()
				for i in 25:
					var t := i / 24.0
					fio.append(Vector2(c.x + sin(t * TAU * 2.0) * 14, c.y + 10 + t * 42))
				draw_polyline(fio, ESCURO, 3.0, true)
			"celular":
				_ret(Rect2(c.x - 30, c.y - 50, 60, 100), ESCURO)
				draw_rect(Rect2(c.x - 24, c.y - 42, 48, 74), AZUL_CLARO)
				draw_circle(Vector2(c.x, c.y + 42), 3.5, Color.WHITE)  # furinho do microfone
				for i in 3:
					draw_arc(Vector2(c.x, c.y + 42), 10 + i * 8, PI * 0.25, PI * 0.75, 10, Color(AZUL, 0.8 - i * 0.2), 3.0, true)

	func _ret(r: Rect2, cor: Color) -> void:
		var s := StyleBoxFlat.new()
		s.bg_color = cor
		s.set_corner_radius_all(int(minf(r.size.x, r.size.y) * 0.4))
		s.anti_aliasing = true
		draw_style_box(s, r)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var veu := ColorRect.new()
	veu.color = Color(UI.CORES.texto, 0.45)
	veu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(veu)

	var m := MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "right"]:
		m.add_theme_constant_override("margin_" + lado, 18)
	m.add_theme_constant_override("margin_top", 36)
	m.add_theme_constant_override("margin_bottom", 36)
	add_child(m)
	var painel := UI.painel()
	m.add_child(painel)
	var fora := VBoxContainer.new()
	fora.add_theme_constant_override("separation", 14)
	painel.add_child(fora)

	fora.add_child(UI.rotulo("🎧 Qual microfone usar?", 34, UI.CORES.texto))
	var v := UI.coluna_rolavel(fora)
	v.add_child(_texto("Alguns celulares têm o microfone pouco sensível, e o sopro da criança pode não ser captado. Funciona muito melhor com um microfone pertinho da boca da criança:"))
	v.add_child(_cartao("fone", "Fone de ouvido com microfone", "O microfone fica perto da boca. Prefira fone com fio (P2 ou USB-C).", true))
	v.add_child(_cartao("lapela", "Microfone de lapela", "Prenda na roupa, perto do queixo da criança, e ligue no celular.", true))
	v.add_child(_cartao("celular", "Microfone do próprio celular", "Funciona, mas a criança precisa soprar bem perto da parte de baixo do celular.", false))

	var alerta := PanelContainer.new()
	alerta.add_theme_stylebox_override("panel", UI.caixa(UI.CORES.amarelo, 22, 0))
	var av := VBoxContainer.new()
	av.add_theme_constant_override("separation", 8)
	alerta.add_child(av)
	av.add_child(_texto("⚠️ Fone sem fio (Bluetooth) muitas vezes NÃO envia o microfone para jogos. Se o sopro não funcionar, use um fone com fio.", 22, UI.CORES.texto))
	av.add_child(_texto("Depois de conectar o fone ou a lapela, toque em \"Medir o barulho do ambiente\" e teste o sopro na barra.", 22, UI.CORES.texto))
	v.add_child(alerta)

	var ok := UI.botao("Entendi", UI.CORES.menta, 30, 96, UI.CORES.texto)
	ok.pressed.connect(func():
		Perfil.definir("aviso_mic_visto", true)
		fechado.emit()
		queue_free())
	fora.add_child(ok)


func _texto(t: String, tam := 24, cor: Color = UI.CORES.texto) -> Label:
	return UI.rotulo(t, tam, cor, HORIZONTAL_ALIGNMENT_LEFT)


func _cartao(tipo: String, titulo: String, texto: String, recomendado: bool) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UI.caixa(UI.CORES.superficie, 24, 0, 3, UI.CORES.menta if recomendado else UI.CORES.borda))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	p.add_child(h)
	var icone := IconeMic.new()
	icone.tipo = tipo
	icone.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(icone)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 4)
	h.add_child(v)
	var selo := UI.rotulo("✅ Recomendado" if recomendado else "⚠️ Pode ser fraco", 20, UI.CORES.primaria_escura if recomendado else Color("A06A00"), HORIZONTAL_ALIGNMENT_LEFT)
	v.add_child(selo)
	v.add_child(_texto(titulo, 26))
	v.add_child(_texto(texto, 21, UI.CORES.texto_suave))
	return p


## Atalho: abre o aviso por cima de qualquer tela.
static func abrir(pai: Node, ao_fechar := Callable()) -> Control:
	var a := Control.new()
	a.set_script(load("res://scripts/aviso_microfone.gd"))
	if ao_fechar.is_valid():
		a.fechado.connect(ao_fechar)
	pai.add_child(a)
	return a
