extends Node
## Autoload "Fala": voz unica do app, texto na tela e o CICLO DE COMUNICACAO (GDD sec. 9),
## igual para todos os jogos:
##   1. Acontece algo no jogo  ->  2. MODELO (fala + texto)  ->  3. PAUSA (silencio, sem contador)
##   ->  4. ACEITACAO (qualquer resposta, ou nenhuma, recebe a mesma celebracao calorosa).
## Nao existe "certo" ou "errado" em nenhum ponto deste ciclo.

signal estado_mudou(estado: int, texto: String, item: Dictionary)

enum { OBSERVANDO, FALANDO, ESPERANDO, CELEBRANDO, CONVIDANDO }

const ARQ_FRASES := "res://data/frases.json"

var estado := OBSERVANDO
var frases := {}

var _voz_id := ""
var _player_voz: AudioStreamPlayer
var _player_sfx: AudioStreamPlayer
var _sons := {}
var _bus_efeitos := -1

# estado interno do ciclo
var _ciclo := {}          # {texto, item, grupo, evento, vars, com_pausa, repetiu}
var _pendente := {}       # so guardamos o evento mais recente (fila descarta antigos)
var _tempo := 0.0
var _falando_desde := 0.0


func _ready() -> void:
	frases = _ler_json(ARQ_FRASES)
	_preparar_audio()
	_preparar_voz()


func _ler_json(caminho: String) -> Dictionary:
	var d = JSON.parse_string(FileAccess.get_file_as_string(caminho))
	return d if typeof(d) == TYPE_DICTIONARY else {}


# ============================================================ frases

## Monta a frase de um evento conforme o nivel de apoio do perfil.
func frase(grupo: String, evento: String, vars := {}) -> String:
	var ev: Dictionary = frases.get(grupo, {}).get(evento, {})
	if ev.is_empty() or not ev.get("ativo", true):
		return ""
	var niveis: Array = ev.get("niveis", [])
	if niveis.is_empty():
		return ""
	var forma = niveis[clampi(int(Perfil.config.nivel_apoio), 0, niveis.size() - 1)]
	if typeof(forma) == TYPE_ARRAY:
		forma = forma.pick_random()
	var t := String(forma)
	var nome := Perfil.nome()
	t = t.replace("{nome}", nome)
	for k in vars:
		t = t.replace("{%s}" % k, String(vars[k]))
	# limpa sobras quando nao ha nome: ", vamos?" -> "Vamos?"
	t = t.replace(" , ", " ").replace(", !", "!").strip_edges()
	if t.begins_with(","):
		t = t.substr(1).strip_edges()
		t = t.left(1).to_upper() + t.substr(1)
	return t


# ============================================================ API usada pelos jogos

## Evento com ciclo completo: modelo + pausa + aceitacao.
func ciclo(grupo: String, evento: String, vars := {}, item := {}) -> void:
	_agendar({"grupo": grupo, "evento": evento, "vars": vars, "item": item, "com_pausa": true})


## So fala (modelo sem pausa). Usado para eventos curtos como "Pop!".
func dizer(grupo: String, evento: String, vars := {}, item := {}) -> void:
	_agendar({"grupo": grupo, "evento": evento, "vars": vars, "item": item, "com_pausa": false})


## Fala um texto livre (ex.: previa do nome na configuracao), fora do ciclo.
func falar_texto(texto: String) -> void:
	_falar(texto, "")


## Toque da crianca no personagem ou em objetos durante a pausa = resposta.
func resposta(tipo := "respostas_toque") -> void:
	if estado != ESPERANDO:
		return
	_celebrar()


func ocupado() -> bool:
	return estado != OBSERVANDO


## Para tudo (ao sair do jogo).
func parar() -> void:
	_ciclo = {}
	_pendente = {}
	calar()
	_mudar(OBSERVANDO)


## Estado "convidando" (fim suave). O jogo mostra as opcoes visuais.
func convidar(texto: String) -> void:
	parar()
	_falar(texto, "")
	_mudar(CONVIDANDO, texto)


func _agendar(ev: Dictionary) -> void:
	ev["texto"] = frase(ev.grupo, ev.evento, ev.vars)
	if ev.texto == "":
		return
	if estado == OBSERVANDO:
		_iniciar(ev)
	elif estado != CONVIDANDO:
		_pendente = ev  # o jogo nao fala por cima de si mesmo


func _iniciar(ev: Dictionary) -> void:
	_ciclo = ev
	_ciclo["repetiu"] = false
	_modelo()


func _modelo() -> void:
	var nome_audio := "%s_%s_%d" % [_ciclo.grupo, _ciclo.evento, int(Perfil.config.nivel_apoio)]
	_falar(_ciclo.texto, nome_audio)
	_mudar(FALANDO, _ciclo.texto, _ciclo.item)


func _celebrar() -> void:
	som("celebrar")
	# sorteia a frase UMA vez, para o texto e a voz serem iguais
	var texto := frase("geral", "celebrar")
	_falar(texto, "geral_celebrar")
	_mudar(CELEBRANDO, texto)


func _mudar(novo: int, texto := "", item := {}) -> void:
	estado = novo
	_tempo = 0.0
	if novo == FALANDO:
		_falando_desde = 0.0
	estado_mudou.emit(novo, texto, item)


func _process(delta: float) -> void:
	_tempo += delta
	match estado:
		FALANDO:
			if _terminou_de_falar():
				if _ciclo.get("com_pausa", false):
					_mudar(ESPERANDO, _ciclo.texto, _ciclo.item)
				else:
					_fim_do_ciclo()
		ESPERANDO:
			if Microfone.voz_agora():
				resposta("voz")
			elif _tempo >= Perfil.pausa_segundos():
				if Perfil.config.repetir_modelo and not _ciclo.get("repetiu", false):
					_ciclo.repetiu = true
					_modelo()  # no maximo UMA repeticao por evento
				else:
					_celebrar()  # silencio tambem e aceito, com a mesma alegria
		CELEBRANDO:
			if _tempo >= 1.1 and _terminou_de_falar():
				_fim_do_ciclo()


func _fim_do_ciclo() -> void:
	_ciclo = {}
	_mudar(OBSERVANDO)
	if not _pendente.is_empty():
		var p := _pendente
		_pendente = {}
		_iniciar(p)


func _terminou_de_falar() -> bool:
	if _tempo < 0.6:
		return false
	if _tempo > 7.0:
		return true
	if _player_voz.playing:
		return false
	if _voz_id != "" and DisplayServer.tts_is_speaking():
		return false
	return true


# ============================================================ voz (TTS)

func _preparar_voz() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var vozes := DisplayServer.tts_get_voices()
	for v in vozes:
		var lang := String(v.get("language", "")).to_lower()
		if (lang.begins_with("pt") or lang.begins_with("por")) and lang.contains("br"):
			_voz_id = v.id
			return
	var pt := DisplayServer.tts_get_voices_for_language("pt")
	if pt.size() > 0:
		_voz_id = pt[0]


func tem_voz() -> bool:
	return _voz_id != ""


## Toca audio pre-gravado de assets/falas/<arquivo>.ogg|.wav se existir; senao usa sintese.
func _falar(texto: String, arquivo: String) -> void:
	calar()
	if texto == "":
		return
	if arquivo != "":
		for ext in ["ogg", "wav", "mp3"]:
			var caminho := "res://assets/falas/%s.%s" % [arquivo, ext]
			if ResourceLoader.exists(caminho):
				_player_voz.stream = load(caminho)
				_player_voz.play()
				_abaixar_efeitos()
				return
	if _voz_id == "":
		som("neutro")  # sem voz no aparelho: mostra o texto e usa um som neutro (GDD 7.2)
		return
	var falado := texto.replace(Perfil.nome(), Perfil.nome_falado()) if Perfil.nome() != "" else texto
	# Voz calma e um pouco lenta (GDD 7.4).
	DisplayServer.tts_speak(falado, _voz_id, int(Perfil.config.volume * 100), 1.0, 0.85, 0, true)
	_abaixar_efeitos()


## A voz do app (gravada ou sintetica) esta tocando agora?
func falando_agora() -> bool:
	if _player_voz and _player_voz.playing:
		return true
	return _voz_id != "" and DisplayServer.tts_is_speaking()


func calar() -> void:
	if _player_voz:
		_player_voz.stop()
	if _voz_id != "":
		DisplayServer.tts_stop()


# ============================================================ efeitos sonoros

func _preparar_audio() -> void:
	_bus_efeitos = AudioServer.bus_count
	AudioServer.add_bus()
	AudioServer.set_bus_name(_bus_efeitos, "Efeitos")
	_player_voz = AudioStreamPlayer.new()
	_player_sfx = AudioStreamPlayer.new()
	_player_sfx.bus = "Efeitos"
	add_child(_player_voz)
	add_child(_player_sfx)
	# Sons curtos, graves/medios e com volume baixo: sem estalos, sem agudos (GDD 13).
	_sons["toque"] = _tom([520.0], 0.08, 0.16)
	_sons["encaixe"] = _tom([392.0, 523.25], 0.09, 0.22)
	_sons["queda"] = _tom([523.25, 440.0, 392.0, 329.63], 0.18, 0.2)
	_sons["bolha"] = _tom([440.0, 587.33], 0.08, 0.14)
	_sons["pop"] = _tom([698.46], 0.07, 0.18)
	_sons["celebrar"] = _tom([523.25, 659.25, 783.99], 0.14, 0.22)
	_sons["neutro"] = _tom([440.0], 0.18, 0.16)
	aplicar_volume()


## Gera um AudioStreamWAV com notas suaves (seno com envelope sem estalo).
func _tom(notas: Array, duracao: float, volume: float) -> AudioStreamWAV:
	var taxa := 22050
	var por_nota := int(taxa * duracao)
	var dados := PackedByteArray()
	dados.resize(por_nota * notas.size() * 2)
	var i := 0
	for freq in notas:
		for n in por_nota:
			var t := float(n) / taxa
			var ataque := minf(1.0, n / (taxa * 0.012))
			var env := ataque * exp(-3.5 * float(n) / por_nota)
			var v := sin(TAU * freq * t) + 0.2 * sin(TAU * freq * 2.0 * t)
			dados.encode_s16(i * 2, int(clampf(v * env * volume, -1.0, 1.0) * 32767.0))
			i += 1
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = taxa
	wav.data = dados
	return wav


func som(nome: String) -> void:
	if not Perfil.config.efeitos or not _sons.has(nome):
		return
	_player_sfx.stream = _sons[nome]
	_player_sfx.play()
	if Perfil.config.vibrar and nome in ["encaixe", "pop"]:
		Input.vibrate_handheld(25)


func aplicar_volume() -> void:
	# teto de volume do app: no maximo 0 dB, padrao medio
	var db := linear_to_db(clampf(Perfil.config.volume, 0.05, 1.0))
	AudioServer.set_bus_volume_db(0, db)
	AudioServer.set_bus_mute(_bus_efeitos, not Perfil.config.efeitos)


## O som do jogo nao cobre a fala: efeitos baixam enquanto o personagem fala.
func _abaixar_efeitos() -> void:
	AudioServer.set_bus_volume_db(_bus_efeitos, -12.0)
	var t := create_tween()
	t.tween_interval(2.0)
	t.tween_callback(func(): AudioServer.set_bus_volume_db(_bus_efeitos, 0.0))
