extends Control
## Hub de jogos - tela da crianca (GDD 4.2 e 5.1).
## Poucos icones grandes, um por jogo, sempre na mesma posicao. Personagem cumprimenta.
## Sem texto longo. O cadeado (segurar 3 s) leva a area dos responsaveis.

const PersonagemScript := preload("res://scripts/personagem.gd")
const BalaoScript := preload("res://scripts/balao.gd")
const PortaoScript := preload("res://scripts/portao.gd")


func _ready() -> void:
	var v := UI.tela(self, 24)

	var topo := HBoxContainer.new()
	topo.alignment = BoxContainer.ALIGNMENT_END
	v.add_child(topo)
	var portao := Control.new()
	portao.set_script(PortaoScript)
	portao.aberto.connect(func(): Jogo.ir_para("responsaveis"))
	topo.add_child(portao)

	var balao := PanelContainer.new()
	balao.set_script(BalaoScript)
	v.add_child(balao)

	var p := Control.new()
	p.set_script(PersonagemScript)
	p.custom_minimum_size = Vector2(260, 260)
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(p)

	v.add_child(UI.espacador())

	var grade := GridContainer.new()
	grade.columns = 2
	grade.add_theme_constant_override("h_separation", 24)
	grade.add_theme_constant_override("v_separation", 24)
	v.add_child(grade)
	for j in Jogo.jogos_visiveis():
		grade.add_child(_cartao_jogo(j))

	v.add_child(UI.espacador())

	var saudacao := "saudacao" if Perfil.nome() != "" else "saudacao_sem_nome"
	get_tree().create_timer(0.6).timeout.connect(func():
		if is_inside_tree():
			Fala.dizer("geral", saudacao))


func _cartao_jogo(j: Dictionary) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(310, 330)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UI.estilizar_botao(b, Color(j.cor), 44)
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(v)
	var icone := _icone_jogo(j)
	v.add_child(icone)
	var nome := UI.rotulo(j.nome, 30)
	nome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(nome)
	b.pressed.connect(func():
		Fala.som("toque")
		Jogo.ir_para(j.id))
	return b


## Icone do jogo: assets/imagens/jogo_<id>.png se existir; senao o emoji.
func _icone_jogo(j: Dictionary) -> Control:
	return UI.imagem_item({"id": "jogo_" + j.id, "emoji": j.icone}, 170)
