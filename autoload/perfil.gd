extends Node
## Autoload "Perfil": perfil da crianca, ajustes do responsavel e temas.
## Tudo fica salvo SOMENTE no aparelho, em user:// (GDD sec. 15). Nada e enviado para fora.

const ARQ_PERFIL := "user://perfil.cfg"
const ARQ_TEMAS := "res://data/temas.json"

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
	"nivel_torre": 1,          # fileiras da torre: comeca com 1 e cresce a cada queda
	"jogos_visiveis": {"torre": true, "bolhas": true},
	"abrir_ultimo": false,
	"ultimo_jogo": "",
	"minutos_sessao": 6,
	"orientacao_sopro_dia": "",
	"aviso_mic_visto": false,  # o aviso "qual microfone usar" ja foi mostrado
}

const PAUSA_SEGUNDOS := [2.5, 4.0, 6.0]

var config := {}
var temas: Array = []
var cores: Array = []


func _ready() -> void:
	config = PADRAO.duplicate(true)
	_carregar_temas()
	_carregar()
	# versoes antigas tinham um diario: apaga o arquivo, ele nao e mais usado
	if FileAccess.file_exists("user://diario.json"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://diario.json"))


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


## Apaga o perfil e os ajustes (GDD 15.3: "apagar tudo com um unico botao").
func apagar_tudo() -> void:
	config = PADRAO.duplicate(true)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(ARQ_PERFIL))


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
