extends Control
## Primeira abertura e sessao guiada (GDD 5.2):
##  0. aviso + consentimento  1. apelido e temas  2. sopro ou toque
##  3. medir o barulho do ambiente  4. ajustar a forca do sopro  5. entregar o celular
## Depois de configurado, o app abre direto no hub (ou no ultimo jogo, se o responsavel quiser).

var _coluna: VBoxContainer
var _passo := 0
var _medidor: ProgressBar
var _estado: Label
var _medindo := false
var _seguir_medir: Button


func _ready() -> void:
	var refazer: bool = Jogo.parametros.get("refazer", false)
	if Perfil.config.consentimento and not refazer:
		var destino := "hub"
		if Perfil.config.abrir_ultimo and Perfil.config.ultimo_jogo != "":
			destino = Perfil.config.ultimo_jogo
		get_tree().change_scene_to_file.call_deferred("res://scenes/%s.tscn" % destino)
		return
	var v := UI.tela(self)
	_coluna = UI.coluna_rolavel(v)
	_coluna.add_theme_constant_override("separation", 22)
	_mostrar_passo(1 if refazer else 0)


func _limpar() -> void:
	_medidor = null
	_estado = null
	_medindo = false
	for f in _coluna.get_children():
		f.queue_free()


func _mostrar_passo(p: int) -> void:
	_passo = p
	_limpar()
	match p:
		0: _passo_aviso()
		1: _passo_perfil()
		2: _passo_sopro()
		3: _passo_ambiente()
		4: _passo_forca()
		5: _passo_pronto()


func _texto(t: String, tam := 26) -> Label:
	return UI.rotulo(t, tam, UI.CORES.texto, HORIZONTAL_ALIGNMENT_LEFT)


func _passo_aviso() -> void:
	_coluna.add_child(UI.rotulo("👋", 96))
	_coluna.add_child(UI.rotulo("Boas-vindas!", 44))
	var p := UI.painel()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	p.add_child(v)
	v.add_child(_texto("Este app é uma brincadeira para estimular a comunicação. A criança brinca com um personagem amigo que fala palavras e espera, sem cobrar e sem corrigir."))
	v.add_child(_texto("⚠️ Não é terapia nem diagnóstico, e não substitui o acompanhamento profissional."))
	v.add_child(_texto("🔒 Tudo fica neste aparelho: nome e temas. Sem conta, sem anúncios, nada é enviado para fora. Nenhum áudio é gravado."))
	_coluna.add_child(p)
	var linha_aceito := UI.interruptor("Li e concordo", false, func(_v): pass, ["✓ Concordo", "Concordo?"])
	var aceito: BaseButton = linha_aceito.get_meta("botao")
	_coluna.add_child(linha_aceito)
	var seguir := UI.botao("Continuar", UI.CORES.primaria, 32)
	seguir.disabled = true
	aceito.toggled.connect(func(v): seguir.disabled = not v)
	seguir.pressed.connect(func():
		Perfil.definir("consentimento", true)
		_mostrar_passo(1))
	_coluna.add_child(seguir)


func _passo_perfil() -> void:
	_coluna.add_child(UI.rotulo("Perfil da criança", 40))
	_coluna.add_child(_texto("Como a criança é chamada? Use um apelido, não o nome completo. (opcional)", 24))
	var nome := UI.campo_texto(Perfil.config.nome, "Ex.: Bia")
	nome.text_changed.connect(func(t): Perfil.definir("nome", t.strip_edges()))
	_coluna.add_child(nome)

	_coluna.add_child(_texto("Do que a criança gosta? Escolha dois ou três temas:", 24))
	_coluna.add_child(UI.seletor_temas())

	var seguir := UI.botao("Continuar", UI.CORES.primaria, 32)
	seguir.pressed.connect(func(): _mostrar_passo(2))
	_coluna.add_child(seguir)


func _passo_sopro() -> void:
	_coluna.add_child(UI.rotulo("🎤", 96))
	_coluna.add_child(UI.rotulo("Sopro ou toque?", 40))
	_coluna.add_child(_texto("Nos jogos a criança sopra no microfone do celular para derrubar a torre e fazer bolhas. O áudio não é gravado: o app só mede o sopro na hora. Também dá para brincar só tocando na tela."))
	var sopro := UI.botao("🎤 Usar o sopro", UI.CORES.primaria, 30)
	sopro.pressed.connect(func():
		Perfil.definir("microfone", true)
		Microfone.pedir_permissao()
		_mostrar_passo(3))  # medir o ambiente e ajustar o sopro
	_coluna.add_child(sopro)
	var toque := UI.botao("👆 Só toque", UI.CORES.superficie, 30, 96, UI.CORES.texto)
	toque.pressed.connect(func():
		Perfil.definir("microfone", false)
		_mostrar_passo(5))
	_coluna.add_child(toque)
	_coluna.add_child(_texto("Dá para mudar depois nas configurações.", 22))


func _passo_ambiente() -> void:
	_coluna.add_child(UI.rotulo("🤫", 96))
	_coluna.add_child(UI.rotulo("Medir o barulho do lugar", 38))
	var p := UI.painel()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	p.add_child(v)
	v.add_child(_texto("1. Desligue ventilador, ar-condicionado e TV."))
	v.add_child(_texto("2. Fiquem em silêncio."))
	v.add_child(_texto("3. Toque em \"Medir agora\"."))
	_coluna.add_child(p)
	_estado = _texto("", 26)
	_coluna.add_child(_estado)
	var medir := UI.botao("Medir agora", UI.CORES.primaria, 30)
	medir.pressed.connect(func():
		_medindo = true
		Microfone.pedir_permissao()
		if Microfone.ligar():
			Microfone.calibrar())
	_coluna.add_child(medir)
	_seguir_medir = UI.botao("Continuar", UI.CORES.menta, 30, 96, UI.CORES.texto)
	_seguir_medir.disabled = true
	_seguir_medir.pressed.connect(func(): _mostrar_passo(4))
	_coluna.add_child(_seguir_medir)
	var pular := UI.botao("Pular esta etapa", UI.CORES.superficie, 22, 72, UI.CORES.texto_suave)
	pular.pressed.connect(func(): _mostrar_passo(5))
	_coluna.add_child(pular)


func _passo_forca() -> void:
	_coluna.add_child(UI.rotulo("🌬️", 96))
	_coluna.add_child(UI.rotulo("Ajustar o sopro", 38))
	_coluna.add_child(_texto("Peça para a criança soprar na parte de baixo do celular. Ajuste até a barra ficar verde quando ela sopra."))
	_coluna.add_child(UI.controle_sopro())
	_medidor = UI.medidor_sopro()
	_coluna.add_child(_medidor)
	_estado = UI.rotulo("", 26, UI.CORES.texto, HORIZONTAL_ALIGNMENT_LEFT)
	_coluna.add_child(_estado)
	var seguir := UI.botao("Continuar", UI.CORES.primaria, 32)
	seguir.pressed.connect(func(): _mostrar_passo(5))
	_coluna.add_child(seguir)
	_coluna.add_child(_texto("Dá para mudar a qualquer momento: segure o cadeado 🔒 por 3 segundos.", 22))


func _process(_d: float) -> void:
	if _passo == 3 and _estado:
		# a permissao do microfone chega depois: comeca a medir assim que ela for dada
		if _medindo and not Microfone.ativo and Microfone.tem_permissao():
			Microfone.ligar()
		var t := ""
		if not _medindo:
			t = ""
		elif not Microfone.tem_permissao():
			t = "Permita o uso do microfone na mensagem do celular."
		elif Microfone.calibrando():
			t = "Medindo… silêncio, por favor."
		elif Microfone.ativo:
			t = "✅ Pronto! Barulho do lugar medido."
			_seguir_medir.disabled = false
			if Microfone.ambiente_barulhento():
				t += " O lugar está barulhento: se o sopro não funcionar, desligue o que faz barulho e meça de novo."
		if _estado.text != t:
			_estado.text = t
	elif _passo == 4 and _medidor:
		if not Microfone.ativo and Microfone.tem_permissao():
			Microfone.ligar()
		UI.atualizar_medidor(_medidor, _estado)


func _exit_tree() -> void:
	Microfone.desligar()


func _passo_pronto() -> void:
	_coluna.add_child(UI.rotulo("✅", 96))
	_coluna.add_child(UI.rotulo("Tudo pronto!", 44))
	var p := UI.painel()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	p.add_child(v)
	v.add_child(_texto("• Para mudar a fala ou o sopro, segure o cadeado 🔒 no canto da tela por 3 segundos."))
	v.add_child(_texto("• Dica: ative a \"fixação de tela\" do Android para a criança não sair do app sem querer."))
	v.add_child(_texto("• Brinquem juntos! Comemore qualquer resposta: fala, som, gesto ou olhar."))
	_coluna.add_child(p)
	var ir := UI.botao("Entregar o celular ▶", UI.CORES.menta, 32, 110, UI.CORES.texto)
	ir.pressed.connect(func(): Jogo.ir_para("hub"))
	_coluna.add_child(ir)
