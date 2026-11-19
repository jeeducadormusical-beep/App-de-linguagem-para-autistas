extends Node
## Autoload "Jogo": catalogo de jogos (modulos) e navegacao entre telas.

## Catalogo modular (GDD 4.1). Para adicionar um jogo novo: crie scenes/<id>.tscn com um
## script que estende res://scripts/base_jogo.gd e acrescente uma linha aqui (ficha: GDD sec. 18).
const CATALOGO := [
	{"id": "torre", "nome": "Torre do Castelo", "icone": "🏰", "cor": "FFC9A8", "requisitos": ["microfone"]},
	{"id": "bolhas", "nome": "Bolhas de Sabão", "icone": "🧼", "cor": "BFDCF7", "requisitos": ["microfone"]},
]

var parametros := {}
var _fade: ColorRect
var _trocando := false


func _ready() -> void:
	RenderingServer.set_default_clear_color(UI.cor_fundo())
	var camada := CanvasLayer.new()
	camada.layer = 100
	add_child(camada)
	_fade = ColorRect.new()
	_fade.color = UI.CORES.fundo
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.modulate.a = 0.0
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	camada.add_child(_fade)


func jogos_visiveis() -> Array:
	var vis: Dictionary = Perfil.config.jogos_visiveis
	return CATALOGO.filter(func(j): return vis.get(j.id, true))


## Troca de tela com um fade lento e suave. `cena` = nome do arquivo em scenes/ sem .tscn
func ir_para(cena: String, params := {}) -> void:
	if _trocando:
		return
	_trocando = true
	parametros = params
	Fala.parar()
	_fade.color = UI.cor_fundo()
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var t := create_tween()
	t.tween_property(_fade, "modulate:a", 1.0, 0.25)
	t.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/%s.tscn" % cena))
	t.tween_property(_fade, "modulate:a", 0.0, 0.3)
	t.tween_callback(func():
		_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_trocando = false)


## Botao "voltar" do Android.
## - No jogo: volta ao hub (livre para a crianca).
## - No hub: nao faz nada (sair do modo crianca exige o portao - GDD 6.1).
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		var cena := get_tree().current_scene
		if cena == null:
			return
		var arquivo := cena.scene_file_path.get_file()
		match arquivo:
			"hub.tscn":
				pass
			"inicio.tscn":
				get_tree().quit()
			_:
				ir_para("hub")
