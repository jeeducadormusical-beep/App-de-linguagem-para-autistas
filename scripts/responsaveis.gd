extends Control
## Configuracoes do responsavel. Protegida pelo cadeado (segurar 3 s).
## Pensada para ser simples: so o essencial, com linguagem do dia a dia.

var _medidor: ProgressBar
var _estado_sopro: Label
var _status_mic: Label
var _caixa_sopro: VBoxContainer
var _exemplo: Label


func _ready() -> void:
	var v := UI.tela(self, 16)

	var topo := HBoxContainer.new()
	topo.add_theme_constant_override("separation", 12)
	v.add_child(topo)
	var titulo := UI.rotulo("Configurações", 36, UI.CORES.texto, HORIZONTAL_ALIGNMENT_LEFT)
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo.add_child(titulo)
	# se veio de dentro de um jogo, volta para o mesmo jogo
	var destino: String = Jogo.parametros.get("voltar_para", "hub")
	var voltar := UI.botao("▶ Jogar", UI.CORES.menta, 28, 88, UI.CORES.texto)
	voltar.pressed.connect(func(): Jogo.ir_para(destino))
	topo.add_child(voltar)

	var c := UI.coluna_rolavel(v)
	_secao_crianca(c)
	_secao_fala(c)
	_secao_sopro(c)
	_secao_torre(c)
	_secao_som(c)
	_secao_outros(c)
	var topo_btn := UI.botao("▲ Voltar ao topo", UI.CORES.superficie, 24, 80, UI.CORES.texto)
	topo_btn.pressed.connect(func():
		var r := c.get_parent() as ScrollContainer
		r.scroll_vertical = 0)
	c.add_child(topo_btn)
	c.add_child(UI.espacador(24))


func _nota(t: String) -> Label:
	return UI.rotulo(t, 22, UI.CORES.texto_suave, HORIZONTAL_ALIGNMENT_LEFT)


func _cartao(c: VBoxContainer, titulo: String) -> VBoxContainer:
	c.add_child(UI.titulo_secao(titulo))
	var p := UI.painel()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	p.add_child(v)
	c.add_child(p)
	return v


# ------------------------------------------------------------ secoes

func _secao_crianca(c: VBoxContainer) -> void:
	var v := _cartao(c, "🙂 Criança")
	v.add_child(_nota("Apelido (o personagem fala esse nome):"))
	var nome := UI.campo_texto(Perfil.config.nome, "Ex.: Bia")
	nome.text_changed.connect(func(t): Perfil.definir("nome", t.strip_edges()))
	v.add_child(nome)
	v.add_child(_nota("Do que a criança gosta? (aparece quando a torre cai e nas bolhas)"))
	v.add_child(UI.seletor_temas())


func _secao_fala(c: VBoxContainer) -> void:
	var v := _cartao(c, "💬 Como o personagem fala")
	_exemplo = _nota("")
	v.add_child(UI.seletor(["Só a palavra", "Com artigo", "Frase curta"], Perfil.config.nivel_apoio, func(i):
		Perfil.definir("nivel_apoio", i)
		_mostrar_exemplo()
		Fala.falar_texto(_frase_exemplo())))
	v.add_child(_exemplo)
	_mostrar_exemplo()


func _frase_exemplo() -> String:
	return Fala.frase("torre", "revelar", {"item": "banana", "artigo": "a"})


func _mostrar_exemplo() -> void:
	_exemplo.text = "Exemplo: \"%s\"" % _frase_exemplo()


func _secao_sopro(c: VBoxContainer) -> void:
	var v := _cartao(c, "🎤 Sopro")
	v.add_child(UI.interruptor("Usar o microfone para o sopro", Perfil.config.microfone, func(on):
		Perfil.definir("microfone", on)
		_caixa_sopro.visible = on
		if on:
			Microfone.pedir_permissao()
			Microfone.ligar()
		else:
			Microfone.desligar()))
	_status_mic = _nota("")
	v.add_child(_status_mic)

	_caixa_sopro = VBoxContainer.new()
	_caixa_sopro.add_theme_constant_override("separation", 14)
	_caixa_sopro.visible = Perfil.config.microfone
	v.add_child(_caixa_sopro)
	_caixa_sopro.add_child(_nota("Como é o sopro da criança? Comece no \"Fraco\" e vá para \"Forte\" conforme ela aprender."))
	_caixa_sopro.add_child(UI.controle_sopro())
	_medidor = UI.medidor_sopro()
	_caixa_sopro.add_child(_medidor)
	_estado_sopro = UI.rotulo("", 24, UI.CORES.texto, HORIZONTAL_ALIGNMENT_LEFT)
	_caixa_sopro.add_child(_estado_sopro)
	_caixa_sopro.add_child(UI.diagnostico_mic())
	var medir := UI.botao("Medir o barulho do ambiente", UI.CORES.superficie, 24, 80, UI.CORES.texto)
	medir.pressed.connect(func(): Microfone.calibrar())
	_caixa_sopro.add_child(medir)
	_caixa_sopro.add_child(_nota("Use quando mudar de lugar. Desligue ventilador e ar-condicionado e fique em silêncio por 1 segundo."))


func _secao_torre(c: VBoxContainer) -> void:
	var v := _cartao(c, "🏰 Torre do Castelo")
	v.add_child(_nota("A torre começa pequena e cresce a cada queda. Qualquer sopro derruba, de qualquer tamanho."))
	var tamanho := _nota("Tamanho agora: %d" % int(Perfil.config.nivel_torre))
	v.add_child(tamanho)
	var recomecar := UI.botao("Voltar para a torre pequena", UI.CORES.superficie, 24, 80, UI.CORES.texto)
	recomecar.pressed.connect(func():
		Perfil.definir("nivel_torre", 1)
		tamanho.text = "Tamanho agora: 1")
	v.add_child(recomecar)


func _secao_som(c: VBoxContainer) -> void:
	var v := _cartao(c, "🔊 Som")
	v.add_child(_nota("Volume"))
	var vol := HSlider.new()
	vol.min_value = 0.1
	vol.max_value = 1.0
	vol.step = 0.05
	vol.value = Perfil.config.volume
	vol.custom_minimum_size.y = 64
	vol.focus_mode = Control.FOCUS_NONE
	vol.value_changed.connect(func(x): Perfil.definir("volume", x))
	vol.drag_ended.connect(func(_c): Fala.som("encaixe"))
	v.add_child(vol)
	v.add_child(UI.interruptor("Sons do jogo (bolhas, pedras)", Perfil.config.efeitos, func(on): Perfil.definir("efeitos", on)))


func _secao_outros(c: VBoxContainer) -> void:
	var v := _cartao(c, "⚙️ Outros")
	var refazer := UI.botao("Refazer a configuração inicial", UI.CORES.superficie, 24, 80, UI.CORES.texto)
	refazer.pressed.connect(func(): Jogo.ir_para("inicio", {"refazer": true}))
	v.add_child(refazer)

	# apagar com confirmacao na propria tela (sem janela extra)
	var apagar := UI.botao("Apagar todos os dados", UI.CORES.alerta, 24, 80, Color.WHITE)
	var confirmar := HBoxContainer.new()
	confirmar.add_theme_constant_override("separation", 12)
	confirmar.visible = false
	var sim := UI.botao("Sim, apagar", UI.CORES.alerta, 24, 80, Color.WHITE)
	sim.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sim.pressed.connect(func():
		Perfil.apagar_tudo()
		Jogo.ir_para("inicio"))
	var nao := UI.botao("Cancelar", UI.CORES.superficie, 24, 80, UI.CORES.texto)
	nao.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nao.pressed.connect(func():
		confirmar.visible = false
		apagar.visible = true)
	confirmar.add_child(nao)
	confirmar.add_child(sim)
	apagar.pressed.connect(func():
		apagar.visible = false
		confirmar.visible = true)
	v.add_child(apagar)
	v.add_child(confirmar)

	v.add_child(_nota("Tudo fica só neste celular. Nenhum áudio é gravado. Este app é uma brincadeira de apoio à comunicação e não substitui o acompanhamento profissional."))
	v.add_child(_nota("Créditos: pictogramas de Sergio Palao, ARASAAC (arasaac.org), Governo de Aragão, licença CC BY-NC-SA. Animais: Kenney (kenney.nl), CC0. Fontes: Nunito e Noto Color Emoji (SIL OFL)."))


# ------------------------------------------------------------ medidor ao vivo

func _process(_d: float) -> void:
	if Perfil.config.microfone and not Microfone.ativo and Microfone.tem_permissao():
		Microfone.ligar()
	var status := ""
	if not Perfil.config.microfone:
		status = "Desligado: a criança brinca tocando na tela."
	elif not Microfone.tem_permissao():
		status = "Falta permitir o microfone. Sem ele, a criança brinca tocando na tela."
	if _status_mic.text != status:
		_status_mic.text = status
		_status_mic.visible = status != ""
	if _caixa_sopro.visible:
		UI.atualizar_medidor(_medidor, _estado_sopro)


func _exit_tree() -> void:
	Microfone.desligar()
