extends Node
## Autoload "UI": paleta de cores e construtores de interface.
## Visual inspirado nos apps mais bem avaliados do segmento (Otsimo, Proloquo2Go, Livox,
## Matraquinha): fundo claro e calmo, cores pastel com bom contraste, cantos bem
## arredondados, botoes grandes, poucos elementos por tela e animacoes lentas (GDD sec. 13).

const CORES := {
	"fundo": Color("EEF5FB"),
	"fundo_calmo": Color("F3F4F6"),
	"superficie": Color("FFFFFF"),
	"texto": Color("2D3A4A"),
	"texto_suave": Color("6B7A8F"),
	"primaria": Color("5B8DEF"),
	"primaria_escura": Color("3F6FD1"),
	"menta": Color("8FD9C0"),
	"pessego": Color("FFC9A8"),
	"amarelo": Color("FFE29A"),
	"lilas": Color("CBB8F0"),
	"ceu": Color("BFDCF7"),
	"grama": Color("BFE6C8"),
	"borda": Color("D8E2EE"),
	"sombra": Color(0.17, 0.23, 0.33, 0.10),
	"alerta": Color("E58E8E"),
}

## Tamanho minimo de alvo de toque da crianca (GDD: minimo 64 px).
const ALVO_MIN := 96

## Fonte arredondada e legivel (Nunito) + emojis coloridos embutidos (Noto Color Emoji),
## para os emojis aparecerem iguais em qualquer celular enquanto a arte final nao chega.
const FONTE := "res://assets/fontes/Nunito-Bold.woff2"
const FONTE_FORTE := "res://assets/fontes/Nunito-ExtraBold.woff2"
const FONTE_EMOJI := "res://assets/fontes/NotoColorEmoji.ttf"

var tema: Theme


func _ready() -> void:
	var emoji: Font = load(FONTE_EMOJI)
	var normal: FontFile = load(FONTE)
	var forte: FontFile = load(FONTE_FORTE)
	normal.fallbacks = [emoji]
	forte.fallbacks = [emoji]
	tema = Theme.new()
	tema.default_font = normal
	tema.default_font_size = 28
	tema.set_font("bold_font", "RichTextLabel", forte)
	get_tree().root.theme = tema


## Escala do texto escolhida pelo responsavel (1.0 normal, 1.25 grande).
func escala() -> float:
	return 1.25 if Perfil.config.get("texto_grande", false) else 1.0


func fonte(base: int) -> int:
	return int(base * escala())


func caixa(cor: Color, raio := 28, sombra := 8, borda := 0, cor_borda := Color.TRANSPARENT) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = cor
	s.set_corner_radius_all(raio)
	s.corner_detail = 10
	s.anti_aliasing = true
	if sombra > 0:
		s.shadow_color = CORES.sombra
		s.shadow_size = sombra
		s.shadow_offset = Vector2(0, sombra * 0.5)
	if borda > 0:
		s.set_border_width_all(borda)
		s.border_color = cor_borda
	s.content_margin_left = 20
	s.content_margin_right = 20
	s.content_margin_top = 12
	s.content_margin_bottom = 12
	return s


func estilizar_botao(b: Button, cor: Color, raio := 28, cor_texto: Color = CORES.texto) -> void:
	b.add_theme_stylebox_override("normal", caixa(cor, raio, 8))
	b.add_theme_stylebox_override("hover", caixa(cor.lightened(0.06), raio, 8))
	b.add_theme_stylebox_override("pressed", caixa(cor.darkened(0.08), raio, 2))
	b.add_theme_stylebox_override("disabled", caixa(cor.lerp(Color.WHITE, 0.5), raio, 0))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for estado in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(estado, cor_texto)
	b.add_theme_color_override("font_disabled_color", cor_texto.lerp(Color.WHITE, 0.5))
	b.focus_mode = Control.FOCUS_NONE
	animar_toque(b)


## Botao arredondado padrao.
func botao(texto: String, cor: Color = CORES.primaria, tamanho := 32, altura := ALVO_MIN, cor_texto := Color.WHITE) -> Button:
	var b := Button.new()
	b.text = texto
	b.custom_minimum_size = Vector2(altura, altura)
	b.add_theme_font_size_override("font_size", fonte(tamanho))
	estilizar_botao(b, cor, 28, cor_texto)
	return b


## Botao redondo so com icone (emoji), ex.: voltar para casa.
func botao_icone(icone: String, cor: Color = CORES.superficie, tamanho := ALVO_MIN) -> Button:
	var b := Button.new()
	b.text = icone
	b.custom_minimum_size = Vector2(tamanho, tamanho)
	b.add_theme_font_size_override("font_size", int(tamanho * 0.45))
	estilizar_botao(b, cor, int(tamanho / 2.0), CORES.texto)
	return b


## Pequena animacao de "aperto" (escala), suave e lenta.
func animar_toque(c: Control) -> void:
	c.resized.connect(func(): c.pivot_offset = c.size / 2.0)
	if c is BaseButton:
		c.button_down.connect(func(): _escala(c, 0.95))
		c.button_up.connect(func(): _escala(c, 1.0))


func _escala(c: Control, alvo: float) -> void:
	if not c.is_inside_tree():
		return
	c.create_tween().tween_property(c, "scale", Vector2.ONE * alvo, 0.1)


func rotulo(texto: String, tamanho := 32, cor: Color = CORES.texto, alinhar := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := Label.new()
	l.text = texto
	l.horizontal_alignment = alinhar
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", fonte(tamanho))
	l.add_theme_color_override("font_color", cor)
	return l


func painel(cor: Color = CORES.superficie, raio := 28) -> PanelContainer:
	var p := PanelContainer.new()
	var s := caixa(cor, raio, 6)
	s.content_margin_left = 28
	s.content_margin_right = 28
	s.content_margin_top = 24
	s.content_margin_bottom = 24
	p.add_theme_stylebox_override("panel", s)
	return p


## Estrutura padrao de tela: margens + coluna vertical. Retorna a coluna.
func tela(raiz: Control, separacao := 20) -> VBoxContainer:
	raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var fundo := ColorRect.new()
	fundo.color = cor_fundo()
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(fundo)
	var m := MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 28)
	m.add_theme_constant_override("margin_right", 28)
	m.add_theme_constant_override("margin_top", 44)
	m.add_theme_constant_override("margin_bottom", 28)
	raiz.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", separacao)
	m.add_child(v)
	return v


func cor_fundo() -> Color:
	return CORES.fundo_calmo if Perfil.config.get("tema_calmo", false) else CORES.fundo


func espacador(altura := 0) -> Control:
	var c := Control.new()
	c.custom_minimum_size.y = altura
	if altura == 0:
		c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


## Imagem de um item de tema: usa assets/imagens/<id>.png se existir; senao o emoji.
func imagem_item(item: Dictionary, tamanho := 200.0) -> Control:
	var caminho := "res://assets/imagens/%s.png" % item.get("id", "")
	if ResourceLoader.exists(caminho):
		var t := TextureRect.new()
		t.texture = load(caminho)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.custom_minimum_size = Vector2(tamanho, tamanho)
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return t
	var l := Label.new()
	l.text = item.get("emoji", "❓")
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.custom_minimum_size = Vector2(tamanho, tamanho)
	l.add_theme_font_size_override("font_size", int(tamanho * 0.62))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Linha de opcoes exclusivas (segmented control) para a area dos responsaveis.
func seletor(opcoes: Array, atual: int, ao_mudar: Callable) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	var grupo := ButtonGroup.new()
	for i in opcoes.size():
		var b := Button.new()
		b.text = opcoes[i]
		b.toggle_mode = true
		b.button_group = grupo
		b.button_pressed = i == atual
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size.y = 72
		b.add_theme_font_size_override("font_size", fonte(24))
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_stylebox_override("normal", caixa(CORES.superficie, 20, 0, 2, CORES.borda))
		b.add_theme_stylebox_override("hover", caixa(CORES.superficie, 20, 0, 2, CORES.borda))
		b.add_theme_stylebox_override("pressed", caixa(CORES.primaria, 20, 0))
		b.add_theme_stylebox_override("hover_pressed", caixa(CORES.primaria, 20, 0))
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		b.add_theme_color_override("font_color", CORES.texto)
		b.add_theme_color_override("font_hover_color", CORES.texto)
		b.add_theme_color_override("font_pressed_color", Color.WHITE)
		b.add_theme_color_override("font_hover_pressed_color", Color.WHITE)
		b.pressed.connect(ao_mudar.bind(i))
		h.add_child(b)
	return h


## Interruptor liga/desliga: texto que quebra linha + botao grande "Ligado"/"Desligado".
## Retorna a linha (HBox); o botao fica em linha.get_meta("botao").
func interruptor(texto: String, ligado: bool, ao_mudar: Callable, rotulos := ["Ligado", "Desligado"]) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	var l := rotulo(texto, 26, CORES.texto, HORIZONTAL_ALIGNMENT_LEFT)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	var b := Button.new()
	b.toggle_mode = true
	b.button_pressed = ligado
	b.custom_minimum_size = Vector2(170, 72)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", fonte(24))
	b.add_theme_stylebox_override("normal", caixa(CORES.borda, 36, 0))
	b.add_theme_stylebox_override("hover", caixa(CORES.borda, 36, 0))
	b.add_theme_stylebox_override("pressed", caixa(CORES.menta, 36, 0))
	b.add_theme_stylebox_override("hover_pressed", caixa(CORES.menta, 36, 0))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for estado in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(estado, CORES.texto)
	b.text = rotulos[0] if ligado else rotulos[1]
	b.toggled.connect(func(on):
		b.text = rotulos[0] if on else rotulos[1])
	b.toggled.connect(ao_mudar)
	h.add_child(b)
	h.set_meta("botao", b)
	return h


func campo_texto(valor: String, dica: String) -> LineEdit:
	var e := LineEdit.new()
	e.text = valor
	e.placeholder_text = dica
	e.custom_minimum_size.y = 80
	e.add_theme_font_size_override("font_size", fonte(28))
	e.add_theme_stylebox_override("normal", caixa(CORES.superficie, 20, 0, 2, CORES.borda))
	e.add_theme_stylebox_override("focus", caixa(CORES.superficie, 20, 0, 3, CORES.primaria))
	e.add_theme_color_override("font_color", CORES.texto)
	e.add_theme_color_override("font_placeholder_color", CORES.texto_suave)
	return e


func titulo_secao(texto: String) -> Label:
	var l := rotulo(texto, 30, CORES.primaria_escura, HORIZONTAL_ALIGNMENT_LEFT)
	l.custom_minimum_size.y = 56
	return l


## Grade de temas liga/desliga (usada tambem na area dos responsaveis).
func seletor_temas() -> GridContainer:
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 14)
	g.add_theme_constant_override("v_separation", 14)
	for t in Perfil.temas:
		var b := Button.new()
		b.text = "%s  %s" % [t.emoji, t.nome]
		b.toggle_mode = true
		b.button_pressed = t.id in Perfil.config.temas
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size.y = 88
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", fonte(26))
		b.add_theme_stylebox_override("normal", caixa(CORES.superficie, 24, 0, 2, CORES.borda))
		b.add_theme_stylebox_override("hover", caixa(CORES.superficie, 24, 0, 2, CORES.borda))
		b.add_theme_stylebox_override("pressed", caixa(CORES.menta, 24, 0, 3, CORES.menta.darkened(0.2)))
		b.add_theme_stylebox_override("hover_pressed", caixa(CORES.menta, 24, 0, 3, CORES.menta.darkened(0.2)))
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		for estado in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
			b.add_theme_color_override(estado, CORES.texto)
		var id: String = t.id
		b.toggled.connect(func(ligado):
			var lista: Array = Perfil.config.temas.duplicate()
			if ligado and not id in lista:
				lista.append(id)
			elif not ligado:
				lista.erase(id)
			Perfil.definir("temas", lista))
		g.add_child(b)
	return g


## Controle do sopro: "Fraco" (celular bem sensivel) ate "Forte" (menos sensivel).
## Guarda em Perfil.config.sensibilidade (10 = mais sensivel).
func controle_sopro() -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	v.add_child(h)
	var fraco := rotulo("Fraco", 24, CORES.texto)
	fraco.autowrap_mode = TextServer.AUTOWRAP_OFF
	h.add_child(fraco)
	var s := HSlider.new()
	s.min_value = 1
	s.max_value = 10
	s.step = 1
	s.value = 11 - int(Perfil.config.sensibilidade)
	s.custom_minimum_size.y = 72
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.focus_mode = Control.FOCUS_NONE
	h.add_child(s)
	var forte := rotulo("Forte", 24, CORES.texto)
	forte.autowrap_mode = TextServer.AUTOWRAP_OFF
	h.add_child(forte)
	s.value_changed.connect(func(x): Perfil.definir("sensibilidade", 11 - int(x)))
	var aviso := rotulo("⚠️ No \"fraco\" o celular fica bem sensível e pode captar ventilador, ar-condicionado e outros barulhos. Faça a atividade com eles desligados.", 21, CORES.texto_suave, HORIZONTAL_ALIGNMENT_LEFT)
	v.add_child(aviso)
	return v


## Barra que mostra o sopro ao vivo (azul = ainda nao conta, verde = conta como sopro).
func medidor_sopro() -> ProgressBar:
	var m := ProgressBar.new()
	m.max_value = 1.0
	m.show_percentage = false
	m.custom_minimum_size.y = 44
	m.add_theme_stylebox_override("background", caixa(CORES.borda, 22, 0))
	m.set_meta("fill_azul", caixa(CORES.ceu, 22, 0))
	m.set_meta("fill_verde", caixa(CORES.menta.darkened(0.1), 22, 0))
	m.add_theme_stylebox_override("fill", m.get_meta("fill_azul"))
	m.set_meta("verde", false)
	return m


func atualizar_medidor(m: ProgressBar, estado: Label) -> void:
	var texto := ""
	var valor := 0.0
	var f := 0.0
	if not Microfone.ativo:
		texto = "Microfone desligado ou sem permissão."
	elif Microfone.calibrando():
		texto = "Medindo o barulho do ambiente… silêncio, por favor."
	else:
		var total := Microfone.db_necessarios() + Microfone.FAIXA_DB
		valor = clampf(Microfone.db_acima_do_ruido() / total, 0.0, 1.0)
		f = Microfone.forca_sopro()
		texto = "🫧 Sopro!" if f > 0.0 else "Peça para a criança soprar no celular."
	# so troca o que mudou: mexer no estilo a cada quadro atrapalha a rolagem da tela
	if absf(m.value - valor) > 0.01:
		m.value = valor
	var verde := f > 0.0
	if verde != m.get_meta("verde"):
		m.set_meta("verde", verde)
		m.add_theme_stylebox_override("fill", m.get_meta("fill_verde" if verde else "fill_azul"))
	if estado.text != texto:
		estado.text = texto


## Coluna com rolagem vertical, ajustada para o dedo no celular:
## - so rola na vertical; - uma pequena "zona morta" para um toque nao virar rolagem;
## - nao pula sozinha para o campo de texto quando o teclado abre.
func coluna_rolavel(pai: Control) -> VBoxContainer:
	var r := ScrollContainer.new()
	r.size_flags_vertical = Control.SIZE_EXPAND_FILL
	r.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	r.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	r.follow_focus = false
	r.scroll_deadzone = 12
	pai.add_child(r)
	var c := VBoxContainer.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.add_theme_constant_override("separation", 14)
	r.add_child(c)
	return c


## Linha de diagnostico do microfone (atualiza sozinha 2 vezes por segundo).
func diagnostico_mic() -> Label:
	var l := rotulo("", 20, CORES.texto_suave, HORIZONTAL_ALIGNMENT_LEFT)
	var t := Timer.new()
	t.wait_time = 0.5
	t.autostart = true
	t.timeout.connect(func():
		var txt := Microfone.diagnostico()
		if l.text != txt:
			l.text = txt)
	l.add_child(t)
	return l
