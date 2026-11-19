extends Node
## Autoload "Perfil": perfil da crianca, ajustes do responsavel, temas e diario.
## Tudo fica salvo SOMENTE no aparelho, em user:// (GDD sec. 15). Nada e enviado para fora.

const ARQ_PERFIL := "user://perfil.cfg"
const ARQ_DIARIO := "user://diario.json"
const ARQ_TEMAS := "res://data/temas.json"
const MAX_SESSOES := 300

const PADRAO := {
	"consentimento": false,
	"nome": "",
	"nome_voz": "",            # grafia usada so pela voz (GDD 7.3)
	"temas": ["frutas", "animais"],
	"nivel_apoio": 1,          # 0 = uma palavra, 1 = palavra com artigo, 2 = frase curta
	"pausa": 1,                # 0 = curta, 1 = media, 2 = longa
	"repetir_modelo": true,    # no silencio, repete o modelo uma vez
	"texto_ligado": true,
	"texto_grande": false,
	"volume": 0.7,
	"efeitos": true,
	"movimento_reduzido": false,
	"tema_calmo": false,
	"vibrar": false,
	"microfone": false,
	"sensibilidade": 7,        # 1 (pouco sensivel) ate 10 (muito sensivel)
	"detectar_voz": false,
	"torre_cai": true,
	"forca_derrubar": 1,       # sopro para derrubar a torre: 0 fraco, 1 medio, 2 forte
	"nivel_torre": 1,          # 1..5: a torre comeca pequena e cresce a cada queda
	"torre_sobe_nivel": true,  # se desligado, a torre fica sempre no mesmo nivel
	"jogos_visiveis": {"torre": true, "bolhas": true},
	"abrir_ultimo": false,
	"ultimo_jogo": "",
	"minutos_sessao": 6,
	"orientacao_sopro_dia": "",
}

const PAUSA_SEGUNDOS := [2.5, 4.0, 6.0]

var config := {}
var temas: Array = []
var cores: Array = []
var diario: Array = []
var _sessao := {}


func _ready() -> void:
	config = PADRAO.duplicate(true)
	_carregar_temas()
	_carregar()
	_carregar_diario()


# ------------------------------------------------------------ perfil

func _carregar() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(ARQ_PERFIL) != OK:
		return
	for k in PADRAO:
		config[k] = cfg.get_value("perfil", k, PADRAO[k])
	# versoes antigas guardavam a sensibilidade como 0, 1 ou 2
	if int(config.sensibilidade) <= 2:
		config.sensibilidade = PADRAO.sensibilidade


func salvar() -> void:
	var cfg := ConfigFile.new()
	for k in config:
		cfg.set_value("perfil", k, config[k])
	cfg.save(ARQ_PERFIL)


func definir(chave: String, valor) -> void:
	config[chave] = valor
	salvar()
	if chave == "volume" or chave == "efeitos":
		Fala.aplicar_volume()


func nome() -> String:
	return String(config.nome).strip_edges()


func nome_falado() -> String:
	var v := String(config.nome_voz).strip_edges()
	return v if v != "" else nome()


func pausa_segundos() -> float:
	return PAUSA_SEGUNDOS[clampi(int(config.pausa), 0, 2)]


## Apaga perfil e diario (GDD 15.3: "apagar tudo com um unico botao").
func apagar_tudo() -> void:
	config = PADRAO.duplicate(true)
	diario.clear()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(ARQ_PERFIL))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(ARQ_DIARIO))


# ------------------------------------------------------------ temas

func _carregar_temas() -> void:
	var dados = JSON.parse_string(FileAccess.get_file_as_string(ARQ_TEMAS))
	if typeof(dados) != TYPE_DICTIONARY:
		push_error("Nao consegui ler " + ARQ_TEMAS)
		return
	temas = dados.get("temas", [])
	cores = dados.get("cores", [])
	for c in cores:
		c["cor"] = Color(c.cor)


## Itens dos temas escolhidos (ou dos temas padrao, se nada foi escolhido).
func itens_ativos() -> Array:
	var escolhidos: Array = config.temas
	var lista := []
	for t in temas:
		var usar: bool = t.id in escolhidos if escolhidos.size() > 0 else t.get("padrao", false)
		if usar:
			lista.append_array(t.itens)
	if lista.is_empty() and temas.size() > 0:
		lista.append_array(temas[0].itens)
	return lista


# ------------------------------------------------------------ diario (GDD sec. 14)

func _carregar_diario() -> void:
	if not FileAccess.file_exists(ARQ_DIARIO):
		return
	var dados = JSON.parse_string(FileAccess.get_file_as_string(ARQ_DIARIO))
	if typeof(dados) == TYPE_ARRAY:
		diario = dados


func salvar_diario() -> void:
	while diario.size() > MAX_SESSOES:
		diario.pop_front()
	var f := FileAccess.open(ARQ_DIARIO, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(diario))


func iniciar_sessao(jogo: String) -> void:
	encerrar_sessao()
	_sessao = {
		"jogo": jogo,
		"inicio": Time.get_unix_time_from_system(),
		"data": Time.get_datetime_string_from_system(false, true),
		"duracao": 0,
		"palavras": {},
		"voz": 0,
		"respostas_toque": 0,
		"ele_respondeu": 0,
		"nota": "",
	}
	config.ultimo_jogo = jogo
	salvar()


func registrar_palavra(palavra: String) -> void:
	if _sessao.is_empty() or palavra == "":
		return
	_sessao.palavras[palavra] = int(_sessao.palavras.get(palavra, 0)) + 1


## tipo: "voz", "respostas_toque" ou "ele_respondeu"
func registrar_resposta(tipo: String) -> void:
	if _sessao.is_empty():
		return
	_sessao[tipo] = int(_sessao.get(tipo, 0)) + 1


func encerrar_sessao() -> void:
	if _sessao.is_empty():
		return
	_sessao.duracao = int(Time.get_unix_time_from_system() - float(_sessao.inicio))
	if _sessao.duracao >= 5:
		diario.append(_sessao)
		salvar_diario()
	_sessao = {}


## Palavras que mais apareceram em todas as sessoes.
func palavras_favoritas(qtd := 5) -> Array:
	var total := {}
	for s in diario:
		for p in s.get("palavras", {}):
			total[p] = int(total.get(p, 0)) + int(s.palavras[p])
	var lista := total.keys()
	lista.sort_custom(func(a, b): return total[a] > total[b])
	return lista.slice(0, qtd)


## Resumo em texto para o responsavel copiar e mostrar a equipe terapeutica (GDD 14.3).
func resumo_texto() -> String:
	var linhas := ["Diário de brincadeiras" + (" - " + nome() if nome() != "" else ""), ""]
	for s in diario:
		var pal: Array = s.get("palavras", {}).keys()
		linhas.append("%s | %s | %d min" % [String(s.data).replace("T", " "), nome_do_jogo(s.jogo), maxi(1, int(s.duracao) / 60)])
		if pal.size() > 0:
			linhas.append("  Palavras: " + ", ".join(pal))
		linhas.append("  Voz detectada: %d | \"Ele respondeu\": %d" % [int(s.get("voz", 0)), int(s.get("ele_respondeu", 0))])
		if String(s.get("nota", "")) != "":
			linhas.append("  Nota: " + s.nota)
	var fav := palavras_favoritas()
	if fav.size() > 0:
		linhas.append("")
		linhas.append("Palavras favoritas: " + ", ".join(fav))
	return "\n".join(linhas)


func nome_do_jogo(id: String) -> String:
	for j in Jogo.CATALOGO:
		if j.id == id:
			return j.nome
	return id
