extends Node
## Autoload "Microfone": mede sopro e presenca de voz EM TEMPO REAL. Nenhum audio e gravado
## ou guardado: so usamos medidas momentaneas (intensidade e formato do som) - GDD 11 e 15.
##
## Como diferencia sopro de voz (versao simples):
##  - sopro = som de ar, parecido com ruido -> muitas "passagens por zero" (ZCR alto)
##  - voz   = som periodico (tem tom)       -> poucas passagens por zero (ZCR baixo)

signal sopro(forca: float)   # 0..1, emitido a cada quadro enquanto ha sopro

const LIMIAR_ZCR := 0.16
## Multiplicador sobre o ruido ambiente, por sensibilidade (baixa, media, alta).
const FATOR := [5.0, 3.2, 2.0]

var nivel := 0.0          # intensidade atual (RMS suavizado)
var zcr := 0.0            # taxa de passagens por zero atual
var ruido := 0.01         # ruido ambiente calibrado
var ativo := false

var _bus := -1
var _captura: AudioEffectCapture
var _player: AudioStreamPlayer
var _calibrando := 0.0
var _amostras_ruido: Array[float] = []
var _voz_ate := 0.0


func _ready() -> void:
	_bus = AudioServer.bus_count
	AudioServer.add_bus()
	AudioServer.set_bus_name(_bus, "Microfone")
	AudioServer.set_bus_mute(_bus, true)  # nunca toca o som do microfone no alto-falante
	_captura = AudioEffectCapture.new()
	AudioServer.add_bus_effect(_bus, _captura)
	_player = AudioStreamPlayer.new()
	_player.bus = "Microfone"
	add_child(_player)


func tem_permissao() -> bool:
	if OS.get_name() != "Android":
		return true
	return "android.permission.RECORD_AUDIO" in OS.get_granted_permissions()


## Pede a permissao (chamado so pela area dos responsaveis, em momento claro - GDD 11.5).
func pedir_permissao() -> void:
	if OS.get_name() == "Android" and not tem_permissao():
		OS.request_permission("android.permission.RECORD_AUDIO")


## Liga a escuta. Retorna false se nao for possivel (sem permissao ou desligado no perfil).
func ligar() -> bool:
	if not Perfil.config.microfone or not tem_permissao():
		desligar()
		return false
	if not ativo:
		_player.stream = AudioStreamMicrophone.new()
		_player.play()
		ativo = true
		calibrar()
	return true


func desligar() -> void:
	if ativo:
		_player.stop()
	ativo = false
	nivel = 0.0


## Recalibra o ruido ambiente durante ~1 segundo.
func calibrar() -> void:
	_calibrando = 1.0
	_amostras_ruido.clear()


func limiar() -> float:
	return maxf(ruido * FATOR[clampi(int(Perfil.config.sensibilidade), 0, 2)], 0.02)


## Existe sopro agora? Retorna forca 0..1 (0 = sem sopro).
func forca_sopro() -> float:
	if not ativo or _calibrando > 0.0:
		return 0.0
	if nivel > limiar() and zcr > LIMIAR_ZCR:
		return clampf((nivel - limiar()) / (limiar() * 3.0), 0.1, 1.0)
	return 0.0


## Houve voz/vocalizacao recentemente? (so presenca de som, nunca julga a palavra)
func voz_agora() -> bool:
	return ativo and Perfil.config.detectar_voz and Time.get_ticks_msec() / 1000.0 < _voz_ate


func _process(delta: float) -> void:
	if not ativo:
		return
	var n := _captura.get_frames_available()
	if n <= 0:
		return
	var buf := _captura.get_buffer(n)
	var soma := 0.0
	var cruzamentos := 0
	var anterior := 0.0
	for f in buf:
		var s := (f.x + f.y) * 0.5
		soma += s * s
		if (s >= 0.0) != (anterior >= 0.0):
			cruzamentos += 1
		anterior = s
	var rms := sqrt(soma / buf.size())
	nivel = lerpf(nivel, rms, 0.5)
	zcr = lerpf(zcr, float(cruzamentos) / buf.size(), 0.5)

	if _calibrando > 0.0:
		_calibrando -= delta
		_amostras_ruido.append(rms)
		if _calibrando <= 0.0 and _amostras_ruido.size() > 0:
			var total := 0.0
			for a in _amostras_ruido:
				total += a
			ruido = maxf(total / _amostras_ruido.size(), 0.004)
		return

	var f := forca_sopro()
	if f > 0.0:
		sopro.emit(f)
	elif nivel > limiar() and zcr < LIMIAR_ZCR:
		_voz_ate = Time.get_ticks_msec() / 1000.0 + 0.4


## Ruido continuo alto? (para sugerir ao responsavel usar o toque - GDD 11.5)
func ambiente_barulhento() -> bool:
	return ruido > 0.08
