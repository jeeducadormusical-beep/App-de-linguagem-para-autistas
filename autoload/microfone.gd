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
## Protecoes contra "sopro falso":
##  - o microfone fica surdo enquanto o personagem fala (e um pouquinho depois), para a
##    voz do proprio app no alto-falante nao contar como sopro;
##  - o som precisa durar um pouco (TEMPO_CONFIRMAR) para contar: tosse, porta e estalo nao;
##  - o ruido do ambiente e reaprendido devagar (ventilador ligado depois da medicao).

signal sopro(forca: float)   # 0..1, emitido a cada quadro enquanto ha sopro

## Sensibilidade 1..10 -> quantos dB acima do ruido o som precisa estar para contar.
## 10 = muito sensivel (3 dB), 1 = pouco sensivel (16 dB).
const DB_MIN := 6.0
const DB_MAX := 20.0
## Quanto tempo seguido (s) o som precisa durar para contar como sopro.
const TEMPO_CONFIRMAR := 0.25
## Pequenas falhas dentro do sopro (s) que ainda contam como o mesmo sopro.
const FOLGA := 0.15
## Quanto tempo (s) o microfone continua surdo depois que o personagem para de falar.
const SURDO_DEPOIS_DA_FALA := 0.7
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
var _tempo_soprando := 0.0
var _folga := 0.0
var _surdo_ate := 0.0
var _relogio := 0.0
## Um "sopro" que dura mais que isso sem parar e barulho continuo (ventilador, TV).
const SOPRO_MAXIMO := 4.0

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


## O app esta falando agora (ou acabou de falar)? Nesse tempo o microfone nao escuta.
func surdo() -> bool:
	return _relogio < _surdo_ate


func _app_falando() -> bool:
	if Fala.estado == Fala.FALANDO or Fala.estado == Fala.CELEBRANDO or Fala.estado == Fala.CONVIDANDO:
		return true
	return Fala.falando_agora()


## Forca do som agora (nivel suavizado, para o medidor): 0 (nada) ate 1 (sopro forte).
func forca_sopro() -> float:
	return _forca_de(nivel)


func _forca_de(rms: float) -> float:
	if not ativo or _calibrando > 0.0 or surdo():
		return 0.0
	var acima := para_db(rms) - para_db(maxf(ruido, 0.0015)) - db_necessarios()
	if acima <= 0.0:
		return 0.0
	return clampf(0.05 + acima / FAIXA_DB, 0.05, 1.0)


## Houve som da crianca recentemente? (so presenca de som, nunca julga a palavra)
func voz_agora() -> bool:
	return ativo and Perfil.config.detectar_voz and _relogio < _voz_ate


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
	_analisar(rms, delta)


## Analisa um pedaco de som (intensidade RMS) que durou `delta` segundos.
func _analisar(rms: float, delta: float) -> void:
	_relogio += delta
	# medidor: sobe rapido e desce um pouco mais devagar
	nivel = lerpf(nivel, rms, 0.6 if rms > nivel else 0.35)

	if _calibrando > 0.0:
		_calibrando -= delta
		_amostras_ruido.append(rms)
		if _calibrando <= 0.0 and _amostras_ruido.size() > 0:
			_amostras_ruido.sort()
			# mediana: um barulho isolado durante a calibracao nao estraga a medida
			ruido = maxf(_amostras_ruido[_amostras_ruido.size() / 2], 0.0015)
		return

	if _app_falando():
		_surdo_ate = _relogio + SURDO_DEPOIS_DA_FALA

	# a duracao e medida com o som instantaneo (estalo curto nao "arrasta" o medidor)
	var f := _forca_de(rms)
	if f > 0.0:
		_tempo_soprando += delta
		_folga = FOLGA
		if _tempo_soprando > SOPRO_MAXIMO:
			# som que nao para e barulho do ambiente: reaprende o ruido rapido
			ruido = lerpf(ruido, rms, 0.05)
	else:
		_folga -= delta
		if _folga <= 0.0:
			_tempo_soprando = 0.0
		# sem sopro e sem o app falando: reaprende o ruido do ambiente devagar
		if not surdo():
			var rapido := 0.02 if rms < ruido else 0.003
			ruido = maxf(lerpf(ruido, rms, rapido), 0.0015)
	# so conta como sopro depois de durar um pouquinho
	if f > 0.0 and _tempo_soprando >= TEMPO_CONFIRMAR:
		sopro.emit(f)
		_voz_ate = _relogio + 0.4


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
