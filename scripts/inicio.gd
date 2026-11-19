extends Control
## Primeira abertura e sessao guiada (GDD 5.2):
##  1. aviso + consentimento  2. perfil minimo (apelido e temas)  3. sopro ou toque  4. entregar
## Depois de configurado, o app abre direto no hub (ou no ultimo jogo, se o responsavel quiser).

var _coluna: VBoxContainer
var _passo := 0


func _ready() -> void:
	var refazer: bool = Jogo.parametros.get("refazer", false)
	if Perfil.config.consentimento and not refazer:
		var destino := "hub"
		if Perfil.config.abrir_ultimo and Perfil.config.ultimo_jogo != "":
			destino = Perfil.config.ultimo_jogo
		get_tree().change_scene_to_file.call_deferred("res://scenes/%s.tscn" % destino)
		return
	var v := UI.tela(self)
	var rolagem := ScrollContainer.new()
	rolagem.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(rolagem)
	_coluna = VBoxContainer.new()
	_coluna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_coluna.add_theme_constant_override("separation", 22)
	rolagem.add_child(_coluna)
	_mostrar_passo(1 if refazer else 0)


func _limpar() -> void:
	for f in _coluna.get_children():
		f.queue_free()


func _mostrar_passo(p: int) -> void:
	_passo = p
	_limpar()
	match p:
		0: _passo_aviso()
		1: _passo_perfil()
		2: _passo_sopro()
		3: _passo_pronto()


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
	v.add_child(_texto("🔒 Tudo fica neste aparelho: nome, temas e diário. Sem conta, sem anúncios, nada é enviado para fora. Nenhum áudio é gravado."))
	_coluna.add_child(p)
	var linha_aceito := UI.interruptor("Li e concordo", false, func(_v): pass)
	var aceito: CheckButton = linha_aceito.get_meta("botao")
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

	_coluna.add_child(_texto("Se a voz falar o nome de um jeito estranho, escreva como deve soar:", 24))
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 12)
	var voz := UI.campo_texto(Perfil.config.nome_voz, "Ex.: Sofia (para \"Sophia\")")
	voz.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	voz.text_changed.connect(func(t): Perfil.definir("nome_voz", t.strip_edges()))
	linha.add_child(voz)
	var ouvir := UI.botao("🔊", UI.CORES.menta, 34, 80, UI.CORES.texto)
	ouvir.pressed.connect(func(): Fala.falar_texto("Oi, %s!" % Perfil.nome_falado() if Perfil.nome() != "" else "Oi!"))
	linha.add_child(ouvir)
	_coluna.add_child(linha)
	if not Fala.tem_voz():
		_coluna.add_child(_texto("ℹ️ Nenhuma voz em português foi encontrada. Instale uma voz em Configurações > Acessibilidade > Saída de texto para fala.", 22))

	_coluna.add_child(_texto("Do que a criança gosta? Escolha dois ou três temas:", 24))
	_coluna.add_child(UI.seletor_temas())

	var seguir := UI.botao("Continuar", UI.CORES.primaria, 32)
	seguir.pressed.connect(func(): _mostrar_passo(2))
	_coluna.add_child(seguir)


func _passo_sopro() -> void:
	_coluna.add_child(UI.rotulo("🧼", 96))
	_coluna.add_child(UI.rotulo("Bolhas de Sabão", 40))
	_coluna.add_child(_texto("Nesse jogo a criança pode soprar no microfone do celular para fazer bolhas. O áudio não é gravado: o app só mede o sopro na hora. Também dá para brincar só com toque."))
	var sopro := UI.botao("🎤 Usar o sopro", UI.CORES.primaria, 30)
	sopro.pressed.connect(func():
		Perfil.definir("microfone", true)
		Microfone.pedir_permissao()
		_mostrar_passo(3))
	_coluna.add_child(sopro)
	var toque := UI.botao("👆 Só toque", UI.CORES.superficie, 30, 96, UI.CORES.texto)
	toque.pressed.connect(func():
		Perfil.definir("microfone", false)
		_mostrar_passo(3))
	_coluna.add_child(toque)
	_coluna.add_child(_texto("Dá para mudar e testar a sensibilidade depois, na área dos responsáveis.", 22))


func _passo_pronto() -> void:
	_coluna.add_child(UI.rotulo("✅", 96))
	_coluna.add_child(UI.rotulo("Tudo pronto!", 44))
	var p := UI.painel()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	p.add_child(v)
	v.add_child(_texto("• Para voltar à configuração, segure o cadeado 🔒 no canto da tela por 3 segundos."))
	v.add_child(_texto("• Dica: ative a \"fixação de tela\" do Android para a criança não sair do app sem querer."))
	v.add_child(_texto("• Brinquem juntos! O botão 👍 discreto nos jogos serve para você marcar quando a criança respondeu de um jeito que o app não percebe (gesto, olhar)."))
	_coluna.add_child(p)
	var ir := UI.botao("Entregar o celular ▶", UI.CORES.menta, 32, 110, UI.CORES.texto)
	ir.pressed.connect(func(): Jogo.ir_para("hub"))
	_coluna.add_child(ir)
