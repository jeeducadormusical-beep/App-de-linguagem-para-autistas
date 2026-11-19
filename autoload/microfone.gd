extends Node
## Autoload "Microfone": mede o sopro EM TEMPO REAL, em decibeis. Nenhum audio e gravado
## ou guardado: so usamos a intensidade do som naquele instante (GDD 11 e 15).
##
## Pensado para criancas que ainda nao sabem soprar direito:
##  - o app mede o ruido do ambiente ao abrir o jogo (calibracao);
##  - qualquer som um pouco acima desse ruido ja conta como sopro (soprar perto do
##    microfone gera um "ronco" grave, entao NAO exigimos som de ar/chiado);
##  - a forca do sopro (0 a 1) cresce em decibeis acima do limiar, entao um sopro
##    fraquinho ja da uma forca pequena, e um sopro forte chega a 1.

signal sopro(forca: float)   # 0..1, emitido a cada quadro enquanto ha sopro

## Sensibilidade 1..10 -> quantos dB acima do ruido o som precisa estar para contar.
## 10 = muito sensivel (3 dB), 1 = pouco sensivel (16 dB).
const DB_MIN := 3.0
const DB_MAX := 16.0
## Faixa (em dB acima do limiar) que vai de forca 0 ate forca 1.
const FAIXA_DB := 20.0

var nivel := 0.0          # intensidade atual (RMS suavizado, 0..1)
var ruido := 0.005        # ruido ambiente calibrado (RMS)
var ativo := false

var _bus := -1
var _captura: AudioEffectCapture
var _player: AudioStreamPlayer
var _calibrando := 0.0
var _amostras_ruido: Array[float] = []
var _voz_ate := 0.0

# diagnostico e recuperacao (no Android a entrada de audio as vezes nao inicia de primeira)
var amostras_por_segundo := 0
var reinicios := 0
var _amostras_contadas := 0
var _janela := 0.0
var _sem_som := 0.0
const MAX_REINICIOS := 5


func _ready() -> void:
	_bus = AudioServer.bus_count
	AudioServer.add_bus()
	AudioServer.set_bus_name(_bus, "Microfone")
	# som do microfone praticamente zerado no alto-falante (o efeito de captura le antes do volume)
	AudioServer.set_bus_volume_db(_bus, -80.0)
	_captura = AudioEffectCapture.new()
	AudioServer.add_bus_effect(_bus, _captura)
	_player = AudioStreamPlayer.new()
	_player.bus = "Microfone"
	add_child(_player)
	# assim que o Android conceder a permissao, liga o microfone na hora
	get_tree().on_request_permissions_result.connect(_ao_responder_permissao)


func _ao_responder_permissao(permissao: String, concedida: bool) -> void:
	if concedida and permissao.contains("RECORD_AUDIO") and Perfil.config.microfone:
		reiniciar()


func tem_permissao() -> bool:
	if OS.get_name() != "Android":
		return true
	# aceita o nome completo ou curto da permissao
	for p in OS.get_granted_permissions():
		if String(p).contains("RECORD_AUDIO"):
			return true
	return false


## Pede a permissao (chamado so pela configuracao, em momento claro - GDD 11.5).
func pedir_permissao() -> void:
	if OS.get_name() == "Android" and not tem_permissao():
		OS.request_permission("android.permission.RECORD_AUDIO")


## Liga a escuta. Retorna false se nao for possivel (sem permissao ou desligado no perfil).
func ligar() -> bool:
	if not Perfil.config.microfone:
		desligar()
		return false
	if not tem_permissao():
		# pede a permissao; quando o Android responder, _ao_responder_permissao liga o microfone
		desligar()
		pedir_permissao()
		return false
	if not ativo:
		_iniciar_captura()
		ativo = true
		reinicios = 0
		calibrar()
	return true


func _iniciar_captura() -> void:
	_player.stop()
	_captura.clear_buffer()
	_player.stream = AudioStreamMicrophone.new()
	_player.play()
	_sem_som = 0.0


## Desliga e liga de novo a captura (usado quando nao chega som).
func reiniciar() -> void:
	desligar()
	ligar()


func desligar() -> void:
	if ativo:
		_player.stop()
	ativo = false
	nivel = 0.0


## Mede o ruido do ambiente durante ~1 segundo (pedir silencio nesse momento).
func calibrar() -> void:
	_calibrando = 1.0
	_amostras_ruido.clear()


func calibrando() -> bool:
	return _calibrando > 0.0


static func para_db(rms: float) -> float:
	return 20.0 * log(maxf(rms, 0.00001)) / log(10.0)


## Quantos dB acima do ruido o som precisa chegar, conforme a sensibilidade (1..10).
func db_necessarios() -> float:
	var s := clampf(float(Perfil.config.sensibilidade), 1.0, 10.0)
	return lerpf(DB_MAX, DB_MIN, (s - 1.0) / 9.0)


## Limiar em RMS (para o medidor).
func limiar() -> float:
	return maxf(ruido, 0.0015) * pow(10.0, db_necessarios() / 20.0)


## Intensidade atual em dB acima do ruido ambiente (pode ser negativa).
func db_acima_do_ruido() -> float:
	return para_db(nivel) - para_db(maxf(ruido, 0.0015))


## Forca do sopro agora: 0 (nada) ate 1 (sopro forte).
func forca_sopro() -> float:
	if not ativo or _calibrando > 0.0:
		return 0.0
	var acima := db_acima_do_ruido() - db_necessarios()
	if acima <= 0.0:
		return 0.0
	return clampf(0.05 + acima / FAIXA_DB, 0.05, 1.0)


## Houve som da crianca recentemente? (so presenca de som, nunca julga a palavra)
func voz_agora() -> bool:
	return ativo and Perfil.config.detectar_voz and Time.get_ticks_msec() / 1000.0 < _voz_ate


func _process(delta: float) -> void:
	if not ativo:
		amostras_por_segundo = 0
		return
	_janela += delta
	if _janela >= 1.0:
		amostras_por_segundo = int(_amostras_contadas / _janela)
		_amostras_contadas = 0
		_janela = 0.0
	var n := _captura.get_frames_available()
	if n <= 0:
		_vigiar(delta, false)
		return
	var buf := _captura.get_buffer(n)
	_amostras_contadas += n
	var soma := 0.0
	for f in buf:
		var s := (f.x + f.y) * 0.5
		soma += s * s
	var rms := sqrt(soma / buf.size())
	_vigiar(delta, rms > 0.0)
	# sobe rapido e desce devagar: o sopro fraco e irregular nao "pisca"
	nivel = lerpf(nivel, rms, 0.6 if rms > nivel else 0.2)

	if _calibrando > 0.0:
		_calibrando -= delta
		_amostras_ruido.append(rms)
		if _calibrando <= 0.0 and _amostras_ruido.size() > 0:
			_amostras_ruido.sort()
			# mediana: um barulho isolado durante a calibracao nao estraga a medida
			ruido = maxf(_amostras_ruido[_amostras_ruido.size() / 2], 0.0015)
		return

	var f := forca_sopro()
	if f > 0.0:
		sopro.emit(f)
		_voz_ate = Time.get_ticks_msec() / 1000.0 + 0.4


## Se o microfone fica 1,5 s sem mandar som nenhum (nem o chiado minimo do ambiente),
## a entrada provavelmente nao iniciou: tenta de novo algumas vezes.
func _vigiar(delta: float, chegou_som: bool) -> void:
	if chegou_som:
		_sem_som = 0.0
		return
	_sem_som += delta
	if _sem_som > 1.5 and reinicios < MAX_REINICIOS:
		reinicios += 1
		_iniciar_captura()
		calibrar()


## Texto simples para o responsavel ver se o microfone esta funcionando.
func diagnostico() -> String:
	var perm := "sim" if tem_permissao() else "NÃO"
	var recebendo := "sim" if ativo and _sem_som < 1.0 and amostras_por_segundo > 0 else "não"
	var t := "Permissão: %s · Recebendo som: %s" % [perm, recebendo]
	if ativo and recebendo == "sim":
		t += " · Som agora: %+d dB" % int(round(db_acima_do_ruido()))
	if reinicios >= MAX_REINICIOS and recebendo == "não":
		t += "\nO celular não está mandando som. Feche o app, abra de novo e permita o microfone."
	return t


## Ruido continuo alto? (para sugerir ao responsavel usar o toque - GDD 11.5)
func ambiente_barulhento() -> bool:
	return ruido > 0.08
