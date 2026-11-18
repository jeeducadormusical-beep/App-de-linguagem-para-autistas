extends Control
## Area dos responsaveis (GDD sec. 6, 13, 14 e 15). Protegida pelo portao no hub.
## Linguagem simples, sem termos tecnicos, alto contraste.

var _medidor: ProgressBar
var _status_mic: Label
var _sopro_ok: Label
var _ruido: Label


func _ready() -> void:
	var v := UI.tela(self, 16)

	var topo := HBoxContainer.new()
	topo.add_theme_constant_override("separation", 12)
	v.add_child(topo)
	var titulo := UI.rotulo("Área dos responsáveis", 34, UI.CORES.texto, HORIZONTAL_ALIGNMENT_LEFT)
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo.add_child(titulo)
	var voltar := UI.botao("▶ Jogar", UI.CORES.menta, 28, 88, UI.CORES.texto)
	voltar.pressed.connect(func(): Jogo.ir_para("hub"))
	topo.add_child(voltar)

	var rolagem := ScrollContainer.new()
	rolagem.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(rolagem)
	var c := VBoxContainer.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.add_theme_constant_override("separation", 14)
	rolagem.add_child(c)

	_secao_perfil(c)
	_secao_fala(c)
	_secao_conforto(c)
	_secao_jogos(c)
	_secao_microfone(c)
	_secao_diario(c)
	_secao_privacidade(c)

	c.add_child(UI.espacador(20))
	c.add_child(_nota("Este app é uma brincadeira de apoio à comunicação. Ele não diagnostica, não trata e não substitui o acompanhamento profissional."))


func _nota(t: String) -> Label:
	return UI.rotulo(t, 22, UI.CORES.texto_suave, HORIZONTAL_ALIGNMENT_LEFT)


func _rot(t: String) -> Label:
	return UI.rotulo(t, 24, UI.CORES.texto, HORIZONTAL_ALIGNMENT_LEFT)


func _cartao(c: VBoxContainer, titulo: String) -> VBoxContainer:
	c.add_child(UI.titulo_secao(titulo))
	var p := UI.painel()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	p.add_child(v)
	c.add_child(p)
	return v


func _toggle(v: VBoxContainer, texto: String, chave: String) -> void:
	v.add_child(UI.interruptor(texto, Perfil.config[chave], func(on): Perfil.definir(chave, on)))


# ------------------------------------------------------------ secoes

func _secao_perfil(c: VBoxContainer) -> void:
	var v := _cartao(c, "👤 Perfil")
	v.add_child(_rot("Nome ou apelido"))
	var nome := UI.campo_texto(Perfil.config.nome, "Ex.: Bia")
	nome.text_changed.connect(func(t): Perfil.definir("nome", t.strip_edges()))
	v.add_child(nome)
	v.add_child(_rot("Como a voz deve falar o nome"))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	var voz := UI.campo_texto(Perfil.config.nome_voz, "Igual ao nome")
	voz.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	voz.text_changed.connect(func(t): Perfil.definir("nome_voz", t.strip_edges()))
	h.add_child(voz)
	var ouvir := UI.botao("🔊", UI.CORES.menta, 34, 80, UI.CORES.texto)
	ouvir.pressed.connect(func(): Fala.falar_texto("Oi, %s!" % Perfil.nome_falado() if Perfil.nome() != "" else "Oi!"))
	h.add_child(ouvir)
	v.add_child(h)
	v.add_child(_rot("Temas de interesse"))
	v.add_child(UI.seletor_temas())
	v.add_child(_nota("Imagens próprias: coloque PNGs em assets/imagens/ com o nome do item (ex.: banana.png)."))


func _secao_fala(c: VBoxContainer) -> void:
	var v := _cartao(c, "💬 Fala do personagem")
	v.add_child(_rot("Nível de apoio"))
	var exemplo := _nota("")
	var mostrar_exemplo := func():
		exemplo.text = "Exemplo: \"%s\"" % Fala.frase("torre", "alta")
	v.add_child(UI.seletor(["Só a palavra", "Com artigo", "Frase curta"], Perfil.config.nivel_apoio, func(i):
		Perfil.definir("nivel_apoio", i)
		mostrar_exemplo.call()))
	mostrar_exemplo.call()
	v.add_child(exemplo)
	v.add_child(_rot("Tempo de pausa (espera pela resposta)"))
	v.add_child(UI.seletor(["Curta", "Média", "Longa"], Perfil.config.pausa, func(i): Perfil.definir("pausa", i)))
	_toggle(v, "Repetir a palavra uma vez se não houver resposta", "repetir_modelo")
	_toggle(v, "Mostrar texto na tela", "texto_ligado")
	_toggle(v, "Texto grande", "texto_grande")
	var testar := UI.botao("🔊 Ouvir a voz", UI.CORES.superficie, 26, 80, UI.CORES.texto)
	testar.pressed.connect(func(): Fala.falar_texto(Fala.frase("torre", "alta")))
	v.add_child(testar)


func _secao_conforto(c: VBoxContainer) -> void:
	var v := _cartao(c, "🌙 Conforto sensorial")
	v.add_child(_rot("Volume"))
	var vol := HSlider.new()
	vol.min_value = 0.1
	vol.max_value = 1.0
	vol.step = 0.05
	vol.value = Perfil.config.volume
	vol.custom_minimum_size.y = 64
	vol.value_changed.connect(func(x): Perfil.definir("volume", x))
	vol.drag_ended.connect(func(_c): Fala.som("encaixe"))
	v.add_child(vol)
	_toggle(v, "Efeitos sonoros", "efeitos")
	_toggle(v, "Reduzir movimento", "movimento_reduzido")
	_toggle(v, "Tema calmo (menos cores)", "tema_calmo")
	_toggle(v, "Vibração leve", "vibrar")


func _secao_jogos(c: VBoxContainer) -> void:
	var v := _cartao(c, "🎮 Jogos")
	var vis: Dictionary = Perfil.config.jogos_visiveis
	for j in Jogo.CATALOGO:
		var id: String = j.id
		v.add_child(UI.interruptor("Mostrar %s %s" % [j.icone, j.nome], vis.get(id, true), func(on):
			var d: Dictionary = Perfil.config.jogos_visiveis.duplicate()
			d[id] = on
			Perfil.definir("jogos_visiveis", d)))
	_toggle(v, "Abrir direto no último jogo usado", "abrir_ultimo")
	v.add_child(_rot("Convite suave para parar depois de"))
	var minutos := [3, 6, 10]
	v.add_child(UI.seletor(["3 min", "6 min", "10 min"], maxi(0, minutos.find(int(Perfil.config.minutos_sessao))), func(i): Perfil.definir("minutos_sessao", minutos[i])))
	v.add_child(UI.titulo_secao("🧱 Torre de Blocos"))
	_toggle(v, "A torre pode cair", "torre_cai")
	v.add_child(_rot("Blocos"))
	v.add_child(UI.seletor(["Cores", "Figuras dos temas"], Perfil.config.torre_blocos, func(i): Perfil.definir("torre_blocos", i)))


func _secao_microfone(c: VBoxContainer) -> void:
	var v := _cartao(c, "🎤 Microfone (sopro e voz)")
	v.add_child(_nota("O áudio nunca é gravado. O app só mede o som na hora."))
	v.add_child(UI.interruptor("Usar o microfone", Perfil.config.microfone, func(on):
		Perfil.definir("microfone", on)
		if on:
			Microfone.pedir_permissao()
			Microfone.ligar()
		else:
			Microfone.desligar()))
	_status_mic = _nota("")
	v.add_child(_status_mic)
	v.add_child(_rot("Sensibilidade do sopro"))
	v.add_child(UI.seletor(["Baixa", "Média", "Alta"], Perfil.config.sensibilidade, func(i): Perfil.definir("sensibilidade", i)))
	v.add_child(_rot("Teste: sopre agora"))
	_medidor = ProgressBar.new()
	_medidor.max_value = 1.0
	_medidor.show_percentage = false
	_medidor.custom_minimum_size.y = 36
	_medidor.add_theme_stylebox_override("background", UI.caixa(UI.CORES.borda, 18, 0))
	_medidor.add_theme_stylebox_override("fill", UI.caixa(UI.CORES.menta, 18, 0))
	v.add_child(_medidor)
	_sopro_ok = _rot("")
	v.add_child(_sopro_ok)
	_ruido = _nota("")
	v.add_child(_ruido)
	var recal := UI.botao("Recalibrar ruído do ambiente", UI.CORES.superficie, 24, 80, UI.CORES.texto)
	recal.pressed.connect(func(): Microfone.calibrar())
	v.add_child(recal)
	_toggle(v, "Contar voz da criança como resposta (só detecta som, não entende palavras)", "detectar_voz")


func _secao_diario(c: VBoxContainer) -> void:
	var v := _cartao(c, "📔 Diário")
	v.add_child(_nota("O diário não dá notas e não compara. Serve para conversar com a criança e com a equipe."))
	var fav := Perfil.palavras_favoritas()
	if fav.size() > 0:
		v.add_child(_rot("⭐ Palavras favoritas: " + ", ".join(fav)))
	if Perfil.diario.is_empty():
		v.add_child(_nota("Ainda não há brincadeiras registradas."))
	var ultimas := Perfil.diario.slice(maxi(0, Perfil.diario.size() - 15))
	ultimas.reverse()
	for s in ultimas:
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", UI.caixa(UI.CORES.fundo, 20, 0))
		var linha := VBoxContainer.new()
		p.add_child(linha)
		var minutos := maxi(1, int(s.get("duracao", 0)) / 60)
		linha.add_child(_rot("%s · %s · %d min" % [String(s.data).replace("T", " ").left(16), Perfil.nome_do_jogo(s.jogo), minutos]))
		var pal: Array = s.get("palavras", {}).keys()
		if pal.size() > 0:
			linha.add_child(_nota("Palavras: " + ", ".join(pal)))
		linha.add_child(_nota("Voz detectada: %d · Ele respondeu: %d" % [int(s.get("voz", 0)), int(s.get("ele_respondeu", 0))]))
		var nota := UI.campo_texto(s.get("nota", ""), "Nota (ex.: falou \"ba\" para banana)")
		nota.text_changed.connect(func(t):
			s["nota"] = t
			Perfil.salvar_diario())
		linha.add_child(nota)
		v.add_child(p)
	var copiar := UI.botao("📋 Copiar resumo em texto", UI.CORES.superficie, 24, 80, UI.CORES.texto)
	copiar.pressed.connect(func():
		DisplayServer.clipboard_set(Perfil.resumo_texto())
		copiar.text = "✅ Copiado! Cole onde quiser enviar")
	v.add_child(copiar)


func _secao_privacidade(c: VBoxContainer) -> void:
	var v := _cartao(c, "🔒 Privacidade")
	v.add_child(_nota("Tudo fica guardado só neste aparelho, na área privada do app. Sem conta, sem nuvem, sem anúncios. Nada é enviado para fora sem você copiar e enviar."))
	v.add_child(_nota("Permissões: microfone (só para o sopro e para detectar voz, sem gravar)."))
	var apagar := UI.botao("Apagar todos os dados", UI.CORES.alerta, 26, 88, Color.WHITE)
	var confirmar := ConfirmationDialog.new()
	confirmar.dialog_text = "Apagar perfil, ajustes e diário?\nIsso não pode ser desfeito."
	confirmar.ok_button_text = "Apagar"
	confirmar.cancel_button_text = "Cancelar"
	confirmar.confirmed.connect(func():
		Perfil.apagar_tudo()
		Jogo.ir_para("inicio"))
	add_child(confirmar)
	apagar.pressed.connect(func(): confirmar.popup_centered())
	v.add_child(apagar)


# ------------------------------------------------------------ teste do microfone ao vivo

func _process(_d: float) -> void:
	if _medidor == null:
		return
	if Perfil.config.microfone and not Microfone.ativo and Microfone.tem_permissao():
		Microfone.ligar()
	if not Perfil.config.microfone:
		_status_mic.text = "Desligado: as Bolhas funcionam por toque."
	elif not Microfone.tem_permissao():
		_status_mic.text = "Aguardando permissão do microfone. Sem ela, o jogo funciona por toque."
	else:
		_status_mic.text = "Ligado."
	var lim := Microfone.limiar()
	_medidor.value = clampf(Microfone.nivel / (lim * 2.0), 0.0, 1.0)
	if Microfone.forca_sopro() > 0.0:
		_sopro_ok.text = "🫧 Sopro detectado!"
	elif Microfone.voz_agora():
		_sopro_ok.text = "🗣️ Voz detectada"
	else:
		_sopro_ok.text = ""
	_ruido.text = "Ambiente barulhento: se o sopro falhar, use o toque." if Microfone.ambiente_barulhento() else ""


func _exit_tree() -> void:
	Microfone.desligar()
