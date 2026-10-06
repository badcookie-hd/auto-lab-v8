extends Node3D

const INK := Color("#eef4ff")
const MUTED := Color("#91a1ba")
const CYAN := Color("#42d9ff")
const ORANGE := Color("#ff9d4d")
const RED := Color("#ff5364")
const GREEN := Color("#49e39a")
const NAVY := Color("#09111f")
const PANEL := Color(0.035, 0.065, 0.11, 0.94)

var camera: Camera3D
var car: Node3D
var parts: Dictionary = {}
var part_meshes: Dictionary = {}
var selected_id := ""
var selected_area: Area3D
var hover_area: Area3D
var highlight_material: StandardMaterial3D

var orbit_yaw := -0.72
var orbit_pitch := -0.17
var orbit_distance := 8.7
var orbit_focus := Vector3(0, 1.05, 0)
var dragging := false
var interior_mode := false
var interior_yaw := 0.55
var interior_pitch := -1.05
var interior_distance := 3.3
var interior_focus := Vector3(0.88, 1.40, 0)
var interior_saved_hood_open := false

var engine_on := false
var radiator_installed := true
var battery_installed := true
var air_filter_installed := true
var oil_installed := true
var hood_open := true
var xray_enabled := false
var v8_cutaway := false
var v8_covers: Array[MeshInstance3D] = []
var v8_internals: Array[MeshInstance3D] = []
var xray_trim: Array[MeshInstance3D] = []
var engine_temp := 24.0
var coolant_level := 1.0
var oil_pressure := 0.0
var engine_health := 100.0
var load_value := 0.25
var elapsed := 0.0
var danger_announced := false
var drive_mode := false
var speed_kmh := 0.0
var drive_heading := 0.0
var temperature_samples: Array[float] = []
var sample_timer := 0.0

const PART_ORDER := ["radiator", "engine", "v8_bank_left", "v8_bank_right", "intake_manifold", "exhaust_manifold", "alternator", "water_pump", "oil", "battery", "air_filter", "coolant", "transmission", "driveshaft", "differential", "hood", "wheel_fl", "wheel_fr", "wheel_rl", "wheel_rr", "steering", "headlight", "fuel_tank", "exhaust", "body", "instrument_cluster", "ignition", "turn_signal", "wiper_stalk", "dashboard", "center_screen", "climate", "hazard", "gear_selector", "parking_brake", "cupholder", "pedals", "front_seat", "seat_belt", "door_controls", "glovebox", "rearview_mirror", "sun_visor", "air_vent"]

var info_title: Label
var info_kicker: Label
var info_body: RichTextLabel
var action_button: Button
var action_hint: Label
var component_selector: OptionButton
var focus_button: Button
var temp_graph: Control
var drive_button: Button
var interior_button: Button
var speed_label: Label
var drive_hint: Label
var drive_world: Node3D
var temp_value: Label
var rpm_value: Label
var pressure_value: Label
var health_value: Label
var temp_bar: ProgressBar
var status_chip: Label
var toast: Label
var objective_label: Label
var start_button: Button
var hood_button: Button
var xray_button: Button
var load_slider: HSlider
var steam: GPUParticles3D
var smoke: GPUParticles3D
var hood_pivot: Node3D
var hood_tween: Tween
var cabin_glass: Node3D
var roof_mesh: MeshInstance3D
var radiator_area: Area3D
var radiator_home := Vector3.ZERO
var coolant_fill_mesh: MeshInstance3D
var coolant_puddle: MeshInstance3D
var dashboard_lights: Array[MeshInstance3D] = []
var indicator_left: Array[MeshInstance3D] = []
var indicator_right: Array[MeshInstance3D] = []
var climate_lights: Array[MeshInstance3D] = []
var wiper_arms: Array[Node3D] = []
var hazard_on := false
var climate_on := false
var indicator_side := 0

var component_data := {
	"hood": {
		"name": "Motorhaube", "category": "KAROSSERIE",
		"body": "Die Motorhaube schützt den Motorraum. Sie wird über einen Hebel im Innenraum entriegelt und anschließend von Hand geöffnet.\n\nIm Simulator kannst du sie jederzeit öffnen oder schließen. Bei Arbeiten am heißen Motor besteht Verbrennungsgefahr.",
		"action": "Haube schließen"
	},
	"radiator": {
		"name": "Kühler", "category": "KÜHLSYSTEM · KRITISCH",
		"body": "Der Kühler gibt Wärme des Kühlmittels an die vorbeiströmende Luft ab. Eine Wasserpumpe bewegt das Kühlmittel durch Motor und Kühler.\n\nBaust du den Kühler bei laufendem Motor aus, steigt die Temperatur schnell. Ab etwa 120 °C drohen Dampf, verzogene Bauteile und ein schwerer Motorschaden.",
		"action": "Kühler ausbauen"
	},
	"engine": {
		"name": "Längs eingebauter V8", "category": "ANTRIEB · SCHNITTMODELL",
		"body": "Acht Zylinder stehen in zwei Bänken mit je vier Zylindern im 90°-V. Die Kolben treiben über Pleuel eine gemeinsame Kurbelwelle längs zur Fahrtrichtung an. Ein Viertakt-Zylinder braucht für Ansaugen, Verdichten, Arbeiten und Ausstoßen zwei Kurbelwellenumdrehungen.\n\nDiese Limousine zeigt den Grundaufbau eines frontmotorisierten V8 mit Hinterradantrieb. Öffne das Schnittmodell, um die acht Zylinder und den Kurbeltrieb zu sehen; der echte Motor hätte zusätzlich viele nicht einzeln modellierte Bauteile.",
		"action": "V8-Schnittmodell öffnen"
	},
	"v8_bank_left": {
		"name": "V8-Zylinderbank links", "category": "MOTOR · 4 ZYLINDER",
		"body": "Vier Zylinder liegen hintereinander und sind zur Fahrzeugmitte geneigt. Über jedem sitzen Ventile, Zündkerze und ein Zylinderkopf; darunter bewegen sich Kolben und Pleuel. Die Ventildeckel schließen den Ölraum nach oben ab.\n\nIm Schnittmodell werden die vier Zylinder dieser Bank sichtbar.",
		"action": "Zylinderbank ansehen"
	},
	"v8_bank_right": {
		"name": "V8-Zylinderbank rechts", "category": "MOTOR · 4 ZYLINDER",
		"body": "Die zweite Bank enthält ebenfalls vier Zylinder. Beide Bänke teilen sich Kurbelgehäuse und Kurbelwelle. Die Zylinder stehen in einem V zueinander; Ansaugung liegt innen, die Abgaskrümmer liegen außen.\n\nDie Darstellung zeigt die Bauteilbeziehungen, nicht die Maße oder Zündfolge eines bestimmten Serienmotors.",
		"action": "Zylinderbank ansehen"
	},
	"intake_manifold": {
		"name": "Ansaugbrücke & Drosselklappe", "category": "MOTOR · LUFTWEG",
		"body": "Gefilterte Luft strömt über die Drosselklappe in die Ansaugbrücke. Acht Ansaugkanäle verteilen sie auf die Zylinder beider Bänke. Das Motorsteuergerät dosiert dazu Kraftstoff und Zündung.\n\nDer Luftfilter sitzt vor der Drosselklappe und gehört zum selben Luftweg.",
		"action": "Ansaugweg ansehen"
	},
	"exhaust_manifold": {
		"name": "Abgaskrümmer", "category": "MOTOR · ABGASWEG",
		"body": "An der Außenseite jeder Zylinderbank sammeln vier Krümmerrohre die heißen Abgase. Sie führen zum Katalysator und weiter durch Schalldämpfer zum Endrohr.\n\nAbgaskrümmer werden schon nach kurzer Motorlaufzeit extrem heiß.",
		"action": "Abgasweg ansehen"
	},
	"alternator": {
		"name": "Lichtmaschine & Riemen", "category": "MOTOR · ELEKTRIK",
		"body": "Die Kurbelwelle treibt über einen Riemen die Lichtmaschine an. Sie versorgt das Bordnetz bei laufendem Motor und lädt die 12-Volt-Batterie. Der Riemen treibt je nach Fahrzeug weitere Nebenaggregate an.\n\nEin defekter Riemen kann auch die Kühlung beeinträchtigen.",
		"action": "Riemenantrieb ansehen"
	},
	"water_pump": {
		"name": "Wasserpumpe & Kühlkreislauf", "category": "MOTOR · KÜHLUNG",
		"body": "Die Wasserpumpe hält das Kühlmittel im Umlauf: durch Motorblock und Zylinderköpfe, zum Kühler und zurück. Thermostat und Lüfter helfen, die Betriebstemperatur zu regeln.\n\nOhne Umlauf kann auch ein montierter Kühler den Motor nicht ausreichend schützen.",
		"action": "Kühlkreislauf ansehen"
	},
	"transmission": {
		"name": "Getriebe", "category": "ANTRIEBSSTRANG · HINTERRADANTRIEB",
		"body": "Hinter dem längs eingebauten V8 liegt das Getriebe im Mitteltunnel. Es passt Drehzahl und Drehmoment an; die gewählte Fahrstufe verbindet den Motor mit der Kardanwelle.\n\nDas Modell zeigt ein Automatikgetriebe vereinfacht als Gehäuse und Abtriebswelle.",
		"action": "Kraftfluss verfolgen"
	},
	"driveshaft": {
		"name": "Kardanwelle", "category": "ANTRIEBSSTRANG · HINTERRADANTRIEB",
		"body": "Die Kardanwelle überträgt die Drehung vom Getriebe unter dem Wagenboden zum Hinterachsdifferenzial. Gelenke erlauben Bewegungen des Antriebsstrangs und der Hinterachse.\n\nBei diesem längs eingebauten Frontmotor ist sie der sichtbare Verbindungsweg nach hinten.",
		"action": "Kraftfluss verfolgen"
	},
	"differential": {
		"name": "Hinterachsdifferenzial", "category": "ANTRIEBSSTRANG · HINTERRADANTRIEB",
		"body": "Das Differenzial lenkt den Kraftfluss quer zu den beiden Hinterrädern und lässt sie in Kurven unterschiedlich schnell drehen. Antriebswellen führen von dort zu den Radnaben.\n\nDie Vorderräder lenken, die Hinterräder treiben diese Limousine an.",
		"action": "Hinterachse ansehen"
	},
	"battery": {
		"name": "12-Volt-Batterie", "category": "ELEKTRIK",
		"body": "Die Batterie versorgt Steuergeräte und Anlasser. Während der Fahrt lädt die Lichtmaschine sie wieder auf.\n\nOhne Batterie lässt sich dieser Verbrenner nicht starten. Beim Abklemmen wird zuerst der Minuspol gelöst.",
		"action": "Batterie ausbauen"
	},
	"air_filter": {
		"name": "Luftfilter", "category": "ANSAUGSYSTEM",
		"body": "Der Luftfilter hält Staub und Schmutz vom Motor fern. Ein zugesetzter Filter kann Leistung kosten; ohne Filter können Partikel den Motor beschädigen.\n\nIm Simulator sinkt ohne Filter die verfügbare Leistung.",
		"action": "Luftfilter ausbauen"
	},
	"oil": {
		"name": "Motoröl & Öldeckel", "category": "SCHMIERUNG · KRITISCH",
		"body": "Motoröl bildet einen Schutzfilm zwischen beweglichen Metallteilen, führt Wärme ab und bindet Schmutz.\n\nFehlt Öl oder Öldruck, entsteht innerhalb kurzer Zeit extremer Verschleiß. Ölstand nur nach Herstellervorgabe prüfen.",
		"action": "Öl ablassen"
	},
	"coolant": {
		"name": "Kühlmittelbehälter", "category": "KÜHLSYSTEM",
		"body": "Der Ausgleichsbehälter nimmt die Volumenänderung des warmen Kühlmittels auf. Der Stand wird bei kaltem Motor zwischen MIN und MAX geprüft.\n\nNach einem Kühlerausbau ist Kühlmittel verloren gegangen. Ein montierter Kühler allein reicht dann nicht: Erst bei abgekühltem, ausgeschaltetem Motor nachfüllen. Niemals ein heißes, unter Druck stehendes Kühlsystem öffnen.",
		"action": "Kühlmittel auffüllen"
	},
	"wheel_fl": {
		"name": "Vorderrad & Bremse", "category": "FAHRWERK",
		"body": "Der Reifen ist die einzige Verbindung zur Straße. Dahinter drücken Bremsbeläge gegen eine Bremsscheibe und wandeln Bewegungsenergie in Wärme um.\n\nLuftdruck, Profil, Alter und Beschädigungen entscheiden über Grip und Bremsweg.",
		"action": "Rad drehen"
	},
	"wheel_fr": {
		"name": "Vorderrad & Bremse", "category": "FAHRWERK",
		"body": "Der Reifen ist die einzige Verbindung zur Straße. Dahinter drücken Bremsbeläge gegen eine Bremsscheibe und wandeln Bewegungsenergie in Wärme um.\n\nLuftdruck, Profil, Alter und Beschädigungen entscheiden über Grip und Bremsweg.",
		"action": "Rad drehen"
	},
	"wheel_rl": {
		"name": "Hinterrad & Bremse", "category": "FAHRWERK",
		"body": "Dieses Hinterrad wird über Kardanwelle, Differenzial und Antriebswelle vom V8 angetrieben. Die Bremsscheibe verzögert das Rad; Feder und Dämpfer halten den Reifen auf der Fahrbahn.\n\nUngleichmäßiger Abrieb kann auf falschen Luftdruck oder Probleme an Fahrwerk und Spur hinweisen.",
		"action": "Rad drehen"
	},
	"wheel_rr": {
		"name": "Hinterrad & Bremse", "category": "FAHRWERK",
		"body": "Dieses Hinterrad wird über Kardanwelle, Differenzial und Antriebswelle vom V8 angetrieben. Die Bremsscheibe verzögert das Rad; Feder und Dämpfer halten den Reifen auf der Fahrbahn.\n\nUngleichmäßiger Abrieb kann auf falschen Luftdruck oder Probleme an Fahrwerk und Spur hinweisen.",
		"action": "Rad drehen"
	},
	"fuel_tank": {
		"name": "Kraftstofftank", "category": "KRAFTSTOFFSYSTEM",
		"body": "Der Tank sitzt geschützt im hinteren Fahrzeugbereich. Eine elektrische Pumpe fördert Kraftstoff zum Motor. Das System ist geschlossen, damit möglichst wenig Dampf austritt.\n\nKraftstoff ist leicht entzündlich – Reparaturen gehören in fachkundige Hände.",
		"action": "Tank lokalisieren"
	},
	"exhaust": {
		"name": "Abgasanlage", "category": "ABGAS & SCHALL",
		"body": "Die Abgasanlage führt heiße Verbrennungsgase nach hinten. Katalysator und weitere Systeme reduzieren Schadstoffe, Schalldämpfer dämpfen den Lärm.\n\nIm Betrieb wird die Anlage sehr heiß. In geschlossenen Räumen darf ein Verbrennungsmotor nie laufen.",
		"action": "Abgasweg zeigen"
	},
	"body": {
		"name": "Karosserie & Sicherheitszelle", "category": "SICHERHEIT",
		"body": "Die Karosserie trägt das Fahrzeug und schützt die Insassen. Knautschzonen nehmen bei einem Unfall Energie auf, während die Fahrgastzelle möglichst stabil bleibt.\n\nGurte, Airbags und Kopfstützen ergänzen dieses Schutzsystem.",
		"action": "Röntgenblick aktivieren"
	},
	"steering": {
		"name": "Lenkung", "category": "BEDIENUNG",
		"body": "Das Lenkrad überträgt den Fahrerwunsch über Lenkgetriebe und Spurstangen an die Vorderräder. Eine Servolenkung reduziert die nötige Kraft.\n\nSpiel, Knacken oder starkes Ziehen zu einer Seite sollte geprüft werden.",
		"action": "Lenkung bewegen"
	},
	"headlight": {
		"name": "Scheinwerfer", "category": "SICHT & ELEKTRIK",
		"body": "Scheinwerfer machen die Straße sichtbar und das Auto erkennbar. Abblendlicht begrenzt Blendung, Fernlicht reicht weiter.\n\nSaubere Gläser und korrekte Einstellung sind sicherheitsrelevant.",
		"action": "Licht umschalten"
	},
	"instrument_cluster": {
		"name": "Kombiinstrument", "category": "INNENRAUM · ANZEIGEN",
		"body": "Im Kombiinstrument stehen Geschwindigkeit, Drehzahl, Kraftstoff und Warnleuchten im Blickfeld. Rote Warnungen verlangen meist sofortige Aufmerksamkeit; die genaue Bedeutung steht im Handbuch.\n\nDie Anzeigen hier spiegeln den Zustand der Simulation vereinfacht wider.",
		"action": "Anzeigen prüfen"
	},
	"ignition": {
		"name": "Startknopf", "category": "INNENRAUM · BEDIENUNG",
		"body": "Der Startknopf aktiviert den Anlasser. Das Steuergerät prüft dabei unter anderem die Stromversorgung. Ohne Batterie startet dieser Motor nicht.\n\nBei echten Autos müssen je nach Modell Bremse oder Kupplung betätigt werden.",
		"action": "Motor starten / stoppen"
	},
	"turn_signal": {
		"name": "Blinkerhebel", "category": "INNENRAUM · BEDIENUNG",
		"body": "Mit dem linken Lenkstockhebel kündigst du Abbiegen und Spurwechsel an. Der Blinker informiert andere, gibt dir aber keinen Vorrang.\n\nViele Autos blinken beim kurzen Antippen dreimal.",
		"action": "Blinker demonstrieren"
	},
	"wiper_stalk": {
		"name": "Scheibenwischerhebel", "category": "INNENRAUM · SICHT",
		"body": "Der rechte Lenkstockhebel steuert Wischer, Intervall und Waschanlage. Gute Wischerblätter halten die Sicht bei Regen frei.\n\nWischer nicht auf trockener oder vereister Scheibe laufen lassen.",
		"action": "Wischer demonstrieren"
	},
	"dashboard": {
		"name": "Armaturenbrett", "category": "INNENRAUM · SICHERHEIT",
		"body": "Das Armaturenbrett trägt Anzeigen, Lüftung, Bedienelemente und auf der Beifahrerseite den Airbag. Nichts auf die Airbag-Abdeckung legen.\n\nDie Oberflächen sind matt, damit sich möglichst wenig in der Frontscheibe spiegelt.",
		"action": "Armaturenbrett ansehen"
	},
	"center_screen": {
		"name": "Infotainment-Bildschirm", "category": "INNENRAUM · INFORMATION",
		"body": "Der mittlere Bildschirm bündelt Navigation, Medien und Fahrzeugeinstellungen. Er ist kein Ersatz für den Blick auf die Straße.\n\nWichtige Funktionen sollten möglichst ohne lange Menüs erreichbar sein.",
		"action": "Bildschirm ansehen"
	},
	"climate": {
		"name": "Klimabedienung", "category": "INNENRAUM · KOMFORT",
		"body": "Heizung, Klimaanlage und Gebläse regeln Temperatur und Luftstrom. Beschlagene Scheiben werden mit warmer, trockener Luft und Frischluft frei.\n\nDie Klimaanlage entzieht der Luft Feuchtigkeit.",
		"action": "Gebläse umschalten"
	},
	"hazard": {
		"name": "Warnblinker", "category": "INNENRAUM · SICHERHEIT",
		"body": "Der Warnblinkschalter lässt alle Fahrtrichtungsanzeiger gleichzeitig blinken. Er warnt bei Panne oder besonderer Gefahr; er ersetzt keine Absicherung der Unfallstelle.",
		"action": "Warnblinker umschalten"
	},
	"gear_selector": {
		"name": "Gangwahlhebel", "category": "INNENRAUM · ANTRIEB",
		"body": "Die Gangwahl verbindet den Motor über das Getriebe mit den Rädern. Bei einem Automatikauto stehen P für Parken, R für Rückwärts, N für Leerlauf und D für Fahren.\n\nVor einem Wechsel zwischen D und R muss das Fahrzeug stehen.",
		"action": "Gangwahl ansehen"
	},
	"parking_brake": {
		"name": "Feststellbremse", "category": "INNENRAUM · BREMSEN",
		"body": "Die Feststellbremse sichert das abgestellte Fahrzeug gegen Wegrollen. Sie wirkt unabhängig vom normalen Bremspedal.\n\nAm Hang zusätzlich einen Gang bzw. P einlegen und die Räder passend einschlagen.",
		"action": "Feststellbremse ansehen"
	},
	"cupholder": {
		"name": "Ablagen & Becherhalter", "category": "INNENRAUM · DETAILS",
		"body": "Ablagen halten kleine Gegenstände griffbereit. Lose Gegenstände können bei starkem Bremsen durch den Innenraum fliegen.\n\nGetränke sicher verschließen und Bedienelemente frei halten.",
		"action": "Ablagen ansehen"
	},
	"pedals": {
		"name": "Pedale", "category": "INNENRAUM · BEDIENUNG",
		"body": "Das rechte Pedal gibt Gas, das linke bremst. Bei einem Schaltwagen kommt links die Kupplung dazu.\n\nFahrermatte und Schuhe dürfen die Pedale nicht blockieren. Beim Bremsen zählt ein klarer, kontrollierter Druck.",
		"action": "Pedale ansehen"
	},
	"front_seat": {
		"name": "Fahrersitz & Kopfstütze", "category": "INNENRAUM · ERGONOMIE",
		"body": "Sitzabstand und Lehnenneigung sollen eine sichere Pedal- und Lenkradbedienung erlauben. Die Kopfstütze schützt bei einem Heckaufprall vor einer starken Bewegung des Kopfes.\n\nDer obere Rand gehört ungefähr auf Scheitelhöhe.",
		"action": "Sitz ansehen"
	},
	"seat_belt": {
		"name": "Dreipunktgurt", "category": "INNENRAUM · SICHERHEIT",
		"body": "Der Gurt hält den Körper beim Bremsen oder Aufprall zurück. Das Schulterband verläuft über Brust und Schulter, das Beckenteil tief über dem Becken.\n\nGurt nicht verdrehen und niemals hinter den Rücken legen.",
		"action": "Gurt ansehen"
	},
	"door_controls": {
		"name": "Türgriff & Fensterheber", "category": "INNENRAUM · BEDIENUNG",
		"body": "An der Tür sitzen Öffner, Fensterheber und oft die Spiegelverstellung. Vor dem Öffnen auf Radfahrende und anderen Verkehr achten.\n\nDie Kindersicherung verhindert das Öffnen hinterer Türen von innen.",
		"action": "Türbedienung ansehen"
	},
	"glovebox": {
		"name": "Handschuhfach", "category": "INNENRAUM · STAURAUM",
		"body": "Das Handschuhfach ist Stauraum für Bordbuch und Kleinteile. Schwere Gegenstände sollten dort nicht lose liegen.\n\nHinter dem Armaturenbrett befindet sich häufig der Beifahrerairbag.",
		"action": "Handschuhfach ansehen"
	},
	"rearview_mirror": {
		"name": "Innenspiegel", "category": "INNENRAUM · SICHT",
		"body": "Der Innenspiegel zeigt den Bereich direkt hinter dem Auto. Er wird vor der Fahrt eingestellt; Außenspiegel ergänzen ihn.\n\nTote Winkel bleiben trotzdem bestehen – vor einem Spurwechsel Schulterblick machen.",
		"action": "Spiegel ansehen"
	},
	"sun_visor": {
		"name": "Sonnenblende", "category": "INNENRAUM · SICHT",
		"body": "Die Sonnenblende reduziert Blendung durch tief stehende Sonne. Manche besitzen einen Schminkspiegel.\n\nBei schlechter Sicht langsam fahren und die Scheibe sauber halten.",
		"action": "Sonnenblende ansehen"
	},
	"air_vent": {
		"name": "Luftdüse", "category": "INNENRAUM · KLIMA",
		"body": "Verstellbare Luftdüsen verteilen warme oder gekühlte Luft. Für freie Scheiben den Luftstrom auch zur Front- und Seitenscheibe leiten.\n\nDauerhaft geschlossene Düsen können die Entfeuchtung verschlechtern.",
		"action": "Luftdüse ansehen"
	}
}


func _ready() -> void:
	build_environment()
	build_drive_world()
	build_car()
	build_ui()
	update_camera()
	select_part("radiator")
	show_toast("Willkommen im AUTO//LAB – klicke ein Bauteil an.", CYAN)


func build_environment() -> void:
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#242a2d")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#e3e7e9")
	env.ambient_light_energy = 0.48
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = false
	env.fog_enabled = false
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-54, -35, 0)
	sun.light_color = Color("#f1f3f3")
	sun.light_energy = 0.86
	sun.shadow_enabled = true
	add_child(sun)

	for light_data in [
		[Vector3(-3, 5, 4), Color("#e7edef"), 1.9],
		[Vector3(4, 3, -4), Color("#e9e7e2"), 1.4]
	]:
		var lamp := OmniLight3D.new()
		lamp.position = light_data[0]
		lamp.light_color = light_data[1]
		lamp.light_energy = light_data[2]
		lamp.omni_range = 10.0
		lamp.shadow_enabled = true
		add_child(lamp)

	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(28, 28)
	var floor_mat := make_material(Color("#30363a"), 0.85, 0.02)
	floor_mat.uv1_scale = Vector3(8, 8, 8)
	var floor := MeshInstance3D.new()
	floor.mesh = floor_mesh
	floor.material_override = floor_mat
	add_child(floor)

	# A real workshop reads through large surfaces, soft boxes and grounded shadows.
	var wall_mat := make_material(Color("#3d464b"), 0.85, 0.02)
	create_visual_box(Vector3(18.0, 5.5, 0.18), Vector3(0, 2.7, -6.0), wall_mat, self)
	create_visual_box(Vector3(0.18, 5.5, 12.0), Vector3(8.9, 2.7, 0), wall_mat, self)
	for x in [-5.4, -1.8, 1.8, 5.4]:
		create_visual_box(Vector3(0.035, 4.2, 0.03), Vector3(x, 2.35, -5.88), make_material(Color("#303942"), 0.62, 0.38), self)
	for x in [-4.8, 0.0, 4.8]:
		var softbox := create_visual_box(Vector3(2.7, 0.045, 0.72), Vector3(x, 5.0, -0.8), make_emissive(Color("#e9f3ff"), 1.4), self)
		softbox.rotation.z = deg_to_rad(4.0 if x < 0 else -4.0)
		var area_light := OmniLight3D.new()
		area_light.position = Vector3(x, 4.65, -0.8)
		area_light.light_color = Color("#dceaff")
		area_light.light_energy = 1.0
		area_light.omni_range = 7.5
		area_light.shadow_enabled = true
		add_child(area_light)
	# Tool cabinets and a workbench make the scene feel spatially grounded.
	var cabinet_mat := make_material(Color("#26313b"), 0.52, 0.55)
	for x in [-5.7, -4.4, -3.1]:
		create_visual_box(Vector3(1.05, 1.7, 0.62), Vector3(x, 0.86, -5.48), cabinet_mat, self)
		for y in [0.35, 0.75, 1.15]:
			create_visual_box(Vector3(0.78, 0.035, 0.04), Vector3(x, y, -5.14), make_material(Color("#89939d"), 0.3, 0.9), self)
	create_visual_box(Vector3(3.8, 0.14, 0.85), Vector3(4.8, 1.05, -5.28), make_material(Color("#574432"), 0.58, 0.05), self)
	for x in [3.15, 6.45]:
		create_visual_box(Vector3(0.16, 1.0, 0.16), Vector3(x, 0.5, -5.28), metal_dark(), self)

	# Illuminated service-bay rings and lane markings.
	for radius in [3.4, 4.0]:
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = radius - 0.025
		torus.outer_radius = radius + 0.025
		torus.rings = 96
		torus.ring_segments = 6
		ring.mesh = torus
		ring.position.y = 0.014
		ring.material_override = make_material(Color("#737b80") if radius < 3.7 else Color("#51585c"), 0.76, 0.05)
		add_child(ring)

	for x in [-5.5, 5.5]:
		var stripe := MeshInstance3D.new()
		var stripe_mesh := BoxMesh.new()
		stripe_mesh.size = Vector3(0.035, 0.018, 11.0)
		stripe.mesh = stripe_mesh
		stripe.position = Vector3(x, 0.012, 0)
		stripe.material_override = make_emissive(Color("#344d59"), 0.35)
		add_child(stripe)

	camera = Camera3D.new()
	camera.fov = 46.0
	camera.current = true
	add_child(camera)

	highlight_material = StandardMaterial3D.new()
	highlight_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	highlight_material.albedo_color = Color(0.2, 0.85, 1.0, 0.24)
	highlight_material.emission_enabled = true
	highlight_material.emission = CYAN
	highlight_material.emission_energy_multiplier = 1.8
	highlight_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED


func build_drive_world() -> void:
	drive_world = Node3D.new()
	drive_world.name = "TestTrack"
	drive_world.visible = false
	add_child(drive_world)
	var ground := MeshInstance3D.new()
	var ground_mesh := PlaneMesh.new()
	ground_mesh.size = Vector2(1000, 180)
	ground.mesh = ground_mesh
	ground.position = Vector3(0, -0.015, 36)
	ground.material_override = make_material(Color("#283530"), 0.96, 0.0)
	drive_world.add_child(ground)
	var road := MeshInstance3D.new()
	var road_mesh := PlaneMesh.new()
	road_mesh.size = Vector2(900, 20)
	road.mesh = road_mesh
	road.position = Vector3(0, 0.012, 36)
	road.material_override = make_material(Color("#25292d"), 0.9, 0.02)
	drive_world.add_child(road)
	var white_line := make_material(Color("#d8d6c8"), 0.85, 0.0)
	for z in [26.4, 45.6]:
		create_visual_box(Vector3(895, 0.012, 0.10), Vector3(0, 0.026, z), white_line, drive_world)
	for x in range(-440, 441, 10):
		create_visual_box(Vector3(4.2, 0.012, 0.10), Vector3(x, 0.027, 36), white_line, drive_world)
	var guard_mat := make_material(Color("#828c92"), 0.42, 0.8)
	for z in [24.5, 47.5]:
		create_visual_box(Vector3(900, 0.10, 0.06), Vector3(0, 0.62, z), guard_mat, drive_world)
		for x in range(-440, 441, 12):
			create_visual_box(Vector3(0.08, 0.68, 0.08), Vector3(x, 0.34, z), guard_mat, drive_world)
	# Repeated roadside lights provide scale without adding vehicle collisions.
	for x in range(-420, 421, 60):
		for z in [18.5, 53.5]:
			create_visual_cylinder(0.06, 4.3, Vector3(x, 2.15, z), guard_mat, drive_world)
			create_visual_box(Vector3(0.95, 0.07, 0.22), Vector3(x - 0.36, 4.26, z), make_emissive(Color("#dde6e5"), 0.55), drive_world)


func build_car() -> void:
	car = Node3D.new()
	car.name = "InteractiveCar"
	car.position.y = 0.08
	add_child(car)

	var paint := make_car_paint(Color("#3e5360"))
	var paint_dark := make_car_paint(Color("#26343d"))
	var black := make_rubber_material()
	var metal := make_material(Color("#9ca6ad"), 0.18, 0.94)
	var glass := make_material(Color(0.12, 0.20, 0.23, 0.28), 0.045, 0.08)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED

	# Smooth, continuous coachwork built from elliptical cross-sections.
	var body_sections: Array[Vector4] = [
		Vector4(-2.72, 0.83, 0.32, 0.64), Vector4(-2.52, 0.91, 0.43, 0.94),
		Vector4(-2.08, 0.95, 0.50, 1.10), Vector4(-1.20, 0.94, 0.51, 1.16), Vector4(-0.28, 0.94, 0.51, 1.17),
		Vector4(0.15, 0.92, 0.50, 1.18), Vector4(1.48, 0.94, 0.49, 1.16),
		Vector4(2.28, 0.91, 0.43, 1.02), Vector4(2.70, 0.84, 0.31, 0.72)
	]
	var body_area := create_loft_part("body", body_sections, Vector3(5.5, 1.05, 2.35), paint, car, 32, true)
	var body_scene := load("res://assets/sedan_body.glb") as PackedScene
	if body_scene:
		var body_model := body_scene.instantiate()
		body_area.add_child(body_model)
		if body_model is MeshInstance3D:
			(body_model as MeshInstance3D).material_override = paint
		for mesh in body_model.find_children("*", "MeshInstance3D", true, false):
			(mesh as MeshInstance3D).material_override = paint
		(body_area.get_child(0) as MeshInstance3D).visible = false
	# Lower sill and subtle chrome strip sharpen the silhouette without making it boxy.
	xray_trim.append(create_visual_box(Vector3(3.25, 0.17, 0.07), Vector3(0.38, 0.55, 1.14), paint_dark, car))
	xray_trim.append(create_visual_box(Vector3(3.25, 0.17, 0.07), Vector3(0.38, 0.55, -1.14), paint_dark, car))
	xray_trim.append(create_visual_box(Vector3(3.55, 0.022, 0.025), Vector3(0.38, 1.08, 1.175), metal, car))
	xray_trim.append(create_visual_box(Vector3(3.55, 0.022, 0.025), Vector3(0.38, 1.08, -1.175), metal, car))

	# Separate sloping windscreen, rear glass and side panes give the cabin a real sedan profile.
	cabin_glass = Node3D.new()
	cabin_glass.name = "CabinGlass"
	car.add_child(cabin_glass)
	create_glass_quad(PackedVector3Array([Vector3(-0.38, 1.49, -0.97), Vector3(-0.38, 1.49, 0.97), Vector3(0.12, 2.22, 0.84), Vector3(0.12, 2.22, -0.84)]), glass, cabin_glass)
	create_glass_quad(PackedVector3Array([Vector3(1.48, 2.22, -0.84), Vector3(1.48, 2.22, 0.84), Vector3(1.98, 1.49, 0.97), Vector3(1.98, 1.49, -0.97)]), glass, cabin_glass)
	for side in [-1.0, 1.0]:
		create_glass_quad(PackedVector3Array([Vector3(-0.32, 1.52, side * 0.98), Vector3(0.13, 2.21, side * 0.84), Vector3(0.80, 2.21, side * 0.84), Vector3(0.80, 1.52, side * 0.98)]), glass, cabin_glass)
		create_glass_quad(PackedVector3Array([Vector3(0.83, 1.52, side * 0.98), Vector3(0.83, 2.21, side * 0.84), Vector3(1.48, 2.21, side * 0.84), Vector3(1.93, 1.52, side * 0.98)]), glass, cabin_glass)
	var roof_sections: Array[Vector4] = [
		Vector4(0.04, 2.23, 0.045, 0.83), Vector4(0.21, 2.27, 0.055, 0.88),
		Vector4(1.31, 2.27, 0.055, 0.88), Vector4(1.55, 2.23, 0.045, 0.83)
	]
	roof_mesh = create_loft_visual(roof_sections, paint, car, 24)
	for side in [-1.0, 1.0]:
		var edge_z: float = side * 0.88
		create_pipe(Vector3(-0.36, 1.49, side * 0.98), Vector3(0.12, 2.23, edge_z), Color("#27333a"), 0.045)
		create_pipe(Vector3(0.80, 1.49, side * 0.98), Vector3(0.80, 2.23, edge_z), Color("#27333a"), 0.04)
		create_pipe(Vector3(1.96, 1.49, side * 0.98), Vector3(1.48, 2.23, edge_z), Color("#27333a"), 0.045)
		create_pipe(Vector3(0.12, 2.23, edge_z), Vector3(1.48, 2.23, edge_z), Color("#27333a"), 0.035)
		create_pipe(Vector3(-0.36, 1.49, side * 0.98), Vector3(1.96, 1.49, side * 0.98), Color("#8e999b"), 0.018)
		for door_x in [-0.19, 0.90, 1.90]:
			create_pipe(Vector3(door_x, 0.76, side * 1.172), Vector3(door_x, 1.40, side * 1.172), Color("#192229"), 0.009)
		for handle_x in [0.38, 1.39]:
			create_visual_box(Vector3(0.19, 0.035, 0.035), Vector3(handle_x, 1.26, side * 1.184), metal, car)
	# Front and rear fascias, recessed grille and body-colored bumpers.
	create_visual_box(Vector3(0.14, 0.34, 1.42), Vector3(-2.70, 0.77, 0), make_material(Color("#070b0e"), 0.64, 0.18), car)
	create_visual_box(Vector3(0.16, 0.22, 2.04), Vector3(-2.67, 0.56, 0), paint_dark, car)
	create_visual_box(Vector3(0.16, 0.24, 2.02), Vector3(2.66, 0.60, 0), paint_dark, car)
	create_visual_box(Vector3(0.15, 0.53, 1.86), Vector3(-2.54, 1.16, 0), paint, car)
	for side in [-1.0, 1.0]:
		create_visual_box(Vector3(2.12, 0.15, 0.16), Vector3(-1.33, 1.37, side * 1.02), paint, car)
	for z in [-0.48, -0.24, 0.0, 0.24, 0.48]:
		create_visual_box(Vector3(0.035, 0.25, 0.025), Vector3(-2.785, 0.78, z), metal_dark(), car)

	# Hood has a pivot so its movement is visible.
	hood_pivot = Node3D.new()
	hood_pivot.name = "HoodPivot"
	hood_pivot.position = Vector3(-0.28, 1.40, 0)
	car.add_child(hood_pivot)
	var hood_area := create_box_part("hood", Vector3(2.18, 0.14, 2.04), Vector3(-1.06, 0, 0), paint, hood_pivot)
	var hood_scene := load("res://assets/sedan_hood.glb") as PackedScene
	if hood_scene:
		var hood_model := hood_scene.instantiate()
		hood_area.add_child(hood_model)
		if hood_model is MeshInstance3D:
			(hood_model as MeshInstance3D).material_override = paint
		for mesh in hood_model.find_children("*", "MeshInstance3D", true, false):
			(mesh as MeshInstance3D).material_override = paint
		(hood_area.get_child(0) as MeshInstance3D).visible = false
	hood_pivot.rotation.z = deg_to_rad(-58)

	# Engine components sit below the closed hood, not through its sheet metal.
	var bay := Node3D.new()
	bay.name = "EngineBay"
	bay.position.y = -0.60
	car.add_child(bay)
	create_visual_box(Vector3(2.18, 0.12, 2.0), Vector3(-1.42, 1.0, 0), black, bay)
	build_v8_powertrain(bay)

	var rad_mat := make_material(Color("#273742"), 0.42, 0.72)
	radiator_area = create_box_part("radiator", Vector3(0.15, 0.92, 1.48), Vector3(-2.12, 1.28, 0), rad_mat, bay)
	radiator_home = radiator_area.position
	for z in [-0.66, -0.58, -0.50, -0.42, -0.34, -0.26, -0.18, -0.10, -0.02, 0.06, 0.14, 0.22, 0.30, 0.38, 0.46, 0.54, 0.62]:
		create_visual_box(Vector3(0.022, 0.80, 0.018), Vector3(-0.085, 0, z), make_material(Color("#79848a"), 0.28, 0.92), radiator_area)
	for y in [-0.34, -0.22, -0.10, 0.02, 0.14, 0.26, 0.38]:
		create_visual_box(Vector3(0.024, 0.012, 1.34), Vector3(-0.09, y, 0), make_material(Color("#4c555b"), 0.34, 0.86), radiator_area)
	create_pipe(Vector3(-1.53, 1.63, 0.54), Vector3(-2.04, 1.52, 0.55), Color("#27343b"), 0.045, bay)
	create_pipe(Vector3(-1.42, 1.04, -0.55), Vector3(-2.04, 1.08, -0.55), Color("#27343b"), 0.045, bay)

	create_box_part("battery", Vector3(0.44, 0.34, 0.39), Vector3(-1.84, 1.28, -0.80), make_material(Color("#151a1d"), 0.62, 0.05), bay)
	create_visual_box(Vector3(0.40, 0.035, 0.35), Vector3(-1.84, 1.47, -0.80), make_material(Color("#30363a"), 0.55, 0.12), bay)
	create_visual_cylinder(0.04, 0.035, Vector3(-1.93, 1.51, -0.91), make_emissive(RED, 1.2), bay)
	create_visual_cylinder(0.04, 0.035, Vector3(-1.74, 1.51, -0.91), make_emissive(Color("#657486"), 0.4), bay)

	create_box_part("air_filter", Vector3(0.44, 0.31, 0.40), Vector3(-1.84, 1.30, 0.81), make_material(Color("#111518"), 0.78, 0.06), bay)
	for z in [0.66, 0.74, 0.82, 0.90, 0.98]:
		create_visual_box(Vector3(0.38, 0.02, 0.015), Vector3(-1.84, 1.47, z), make_material(Color("#333a3e"), 0.62, 0.25), bay)
	create_pipe(Vector3(-1.66, 1.40, 0.75), Vector3(-1.71, 1.70, 0.18), Color("#181c20"), 0.10, bay)
	create_cylinder_part("oil", 0.075, 0.065, Vector3(-0.99, 1.81, -0.47), make_material(Color("#d2ae48"), 0.36, 0.2), bay)
	var reservoir_mat := make_material(Color(0.72, 0.82, 0.84, 0.34), 0.18, 0.0)
	reservoir_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	create_cylinder_part("coolant", 0.17, 0.38, Vector3(-1.76, 1.47, 0.70), reservoir_mat, bay)
	coolant_fill_mesh = create_visual_cylinder(0.13, 0.16, Vector3(-1.76, 1.38, 0.70), make_material(Color(0.78, 0.26, 0.34, 0.68), 0.3, 0.0), bay)
	create_visual_cylinder(0.105, 0.055, Vector3(-1.76, 1.69, 0.70), make_material(Color("#171b1d"), 0.72, 0.05), bay)
	var spill_mat := make_material(Color(0.58, 0.20, 0.27, 0.32), 0.12, 0.0)
	spill_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	coolant_puddle = create_visual_cylinder(0.72, 0.008, Vector3(-2.45, 0.020, 0.18), spill_mat, self)
	coolant_puddle.scale.z = 0.62
	coolant_puddle.visible = false

	# Wheels, hubs, and brake discs.
	make_wheel("wheel_fl", Vector3(-1.72, 0.63, 1.15), black, metal)
	make_wheel("wheel_fr", Vector3(-1.72, 0.63, -1.15), black, metal)
	make_wheel("wheel_rl", Vector3(1.72, 0.63, 1.15), black, metal)
	make_wheel("wheel_rr", Vector3(1.72, 0.63, -1.15), black, metal)

	var tank_mat := make_material(Color("#3a464e"), 0.46, 0.78)
	create_box_part("fuel_tank", Vector3(0.85, 0.25, 0.46), Vector3(1.08, 0.45, 0.55), tank_mat, car)
	create_visual_box(Vector3(0.85, 0.25, 0.46), Vector3(1.08, 0.45, -0.55), tank_mat, car)
	create_pipe(Vector3(1.10, 0.40, -0.66), Vector3(-0.38, 0.41, -0.66), Color("#5a6266"), 0.023)
	create_pipe(Vector3(-0.38, 0.41, -0.66), Vector3(-0.64, 0.96, -0.66), Color("#5a6266"), 0.023)
	create_pipe(Vector3(0.8, 0.38, -0.62), Vector3(2.36, 0.38, -0.62), Color("#3e4a52"), 0.07)
	create_cylinder_part("exhaust", 0.105, 0.46, Vector3(2.67, 0.42, -0.62), metal, car, Vector3(0, 0, PI * 0.5))
	# Seats, center tunnel and exterior mirrors remain visible through glass.
	var leather := make_material(Color(0.50, 0.50, 0.50), 0.82, 0.0)
	leather.albedo_texture = load("res://assets/charcoal_leather.png") as Texture2D
	for seat_x in [0.35, 1.25]:
		for seat_z in [-0.50, 0.50]:
			create_visual_box(Vector3(0.55, 0.15, 0.48), Vector3(seat_x, 1.20, seat_z), leather, car)
			var cushion := create_visual_sphere(0.32, Vector3(seat_x - 0.05, 1.27, seat_z), leather, car)
			cushion.scale = Vector3(0.90, 0.23, 0.70)
			if seat_x == 0.35 and seat_z == 0.50:
				create_box_part("front_seat", Vector3(0.18, 0.67, 0.48), Vector3(seat_x + 0.18, 1.51, seat_z), leather, car)
			else:
				create_visual_box(Vector3(0.18, 0.67, 0.48), Vector3(seat_x + 0.18, 1.51, seat_z), leather, car, Vector3(0, 0, -0.12))
			create_visual_box(Vector3(0.16, 0.16, 0.34), Vector3(seat_x + 0.19, 1.93, seat_z), leather, car)
			var headrest := create_visual_sphere(0.19, Vector3(seat_x + 0.19, 1.95, seat_z), leather, car)
			headrest.scale = Vector3(0.43, 0.47, 0.83)
			for seam_z in [-0.17, 0.17]:
				create_visual_box(Vector3(0.035, 0.46, 0.008), Vector3(seat_x + 0.085, 1.51, seat_z + seam_z), make_material(Color("#4b5358"), 0.75, 0.0), car)
	create_visual_box(Vector3(0.28, 0.34, 1.55), Vector3(-0.02, 1.42, 0), make_material(Color("#111518"), 0.68, 0.08), car, Vector3(0, 0, -0.16))
	for z in [-1.16, 1.16]:
		var mirror := create_visual_sphere(0.16, Vector3(-0.03, 1.72, z), paint, car)
		mirror.scale = Vector3(1.25, 0.62, 0.78)
	for x in [0.38, 1.38]:
		for z in [-1.185, 1.185]:
			create_visual_box(Vector3(0.34, 0.035, 0.025), Vector3(x, 1.40, z), metal, car)

	# Steering wheel and dashboard.
	var steering_area := Area3D.new()
	steering_area.name = "Part_steering"
	steering_area.set_meta("part_id", "steering")
	steering_area.collision_layer = 2
	steering_area.collision_mask = 0
	steering_area.position = Vector3(0.18, 1.55, 0.62)
	car.add_child(steering_area)
	var steer := MeshInstance3D.new()
	var torus_steer := TorusMesh.new()
	torus_steer.inner_radius = 0.22
	torus_steer.outer_radius = 0.29
	steer.mesh = torus_steer
	steer.rotation.z = PI * 0.5
	steer.material_override = black
	steering_area.add_child(steer)
	var steer_shape := CollisionShape3D.new()
	var steer_sphere := SphereShape3D.new()
	steer_sphere.radius = 0.34
	steer_shape.shape = steer_sphere
	steering_area.add_child(steer_shape)
	parts["steering"] = steering_area
	part_meshes["steering"] = [steer]
	build_interior_details(leather, black, metal)

	# Slim headlamp clusters with a dark housing and subdued projector lenses.
	for z in [-0.77, 0.77]:
		var lamp_id := "headlight" if z > 0 else "headlight_aux"
		create_visual_box(Vector3(0.045, 0.22, 0.49), Vector3(-2.68, 1.02, z), make_material(Color("#141d23"), 0.37, 0.22), car)
		var area := create_box_part(lamp_id, Vector3(0.055, 0.15, 0.43), Vector3(-2.713, 1.02, z), make_material(Color("#c0cbd0"), 0.12, 0.35), car)
		var lens := area.get_child(0) as MeshInstance3D
		dashboard_lights.append(lens)
		create_visual_cylinder(0.055, 0.025, Vector3(-0.031, 0, -0.08), make_material(Color("#ecf1f1"), 0.08, 0.14), area, Vector3(0, 0, PI * 0.5))
		if lamp_id == "headlight_aux":
			area.set_meta("part_id", "headlight")
		parts["headlight"] = area
	for z in [-0.78, 0.78]:
		var tail := create_visual_box(Vector3(0.055, 0.16, 0.44), Vector3(2.69, 1.03, z), make_material(Color("#a4252a"), 0.14, 0.17), car)
		dashboard_lights.append(tail)

	# Engine bay particles.
	steam = make_particles(Color(0.72, 0.9, 1.0, 0.38), 28, 2.2, Vector3(-1.25, 1.8, 0), 0.08)
	smoke = make_particles(Color(0.13, 0.15, 0.18, 0.55), 18, 3.0, Vector3(-0.85, 1.8, 0), 0.11)
	car.add_child(steam)
	car.add_child(smoke)

	# Floating component markers.
	for id in ["radiator", "engine", "battery", "air_filter", "oil", "coolant"]:
		var area: Area3D = parts[id]
		var marker := MeshInstance3D.new()
		var marker_mesh := SphereMesh.new()
		marker_mesh.radius = 0.020
		marker_mesh.height = 0.04
		marker.mesh = marker_mesh
		marker.position.y = 0.62
		marker.material_override = make_emissive(CYAN, 1.35)
		marker.set_meta("marker", true)
		area.add_child(marker)


func build_v8_powertrain(bay: Node3D) -> void:
	# Longitudinal front V8: four 45° cylinders on each side, one shared crankshaft.
	# The bay is lowered by 0.60 m relative to the body; keep the valve train below the bonnet.
	var cast_iron := make_material(Color("#51575a"), 0.53, 0.58)
	var machined := make_material(Color("#899195"), 0.31, 0.83)
	var dark_metal := make_material(Color("#242b30"), 0.56, 0.48)
	var cover_paint := make_car_paint(Color("#562c2a"))
	var engine_area := create_box_part("engine", Vector3(1.22, 0.43, 0.70), Vector3(-1.27, 1.15, 0), cast_iron, bay)
	v8_covers.append(engine_area.get_child(0) as MeshInstance3D)
	var crank := create_visual_cylinder(0.105, 1.12, Vector3(0, -0.05, 0), machined, engine_area, Vector3(0, 0, PI * 0.5))
	crank.visible = false
	v8_internals.append(crank)
	for side in [-1.0, 1.0]:
		var bank_id := "v8_bank_left" if side > 0.0 else "v8_bank_right"
		var bank := create_box_part(bank_id, Vector3(1.16, 0.28, 0.27), Vector3(-1.27, 1.48, side * 0.34), cover_paint, bay)
		bank.rotation.x = side * PI * 0.25
		v8_covers.append(bank.get_child(0) as MeshInstance3D)
		for cylinder_index in 4:
			var cylinder_x := -0.42 + float(cylinder_index) * 0.28
			var bore := create_visual_cylinder(0.098, 0.27, Vector3(cylinder_x, -0.035, 0), machined, bank)
			bore.visible = false
			v8_internals.append(bore)
			var piston := create_visual_cylinder(0.083, 0.055, Vector3(cylinder_x, 0.055, 0), dark_metal, bank)
			piston.visible = false
			v8_internals.append(piston)
			var rod_x := -1.27 + cylinder_x
			var rod := create_pipe(Vector3(rod_x, 1.40, side * 0.33), Vector3(rod_x, 1.12, side * 0.035), Color("#b1b7b8"), 0.022, bay)
			rod.visible = false
			v8_internals.append(rod)
			create_visual_cylinder(0.026, 0.11, Vector3(cylinder_x, 0.195, 0), dark_metal, bank)
			var exhaust_z: float = side * 0.67
			create_pipe(Vector3(-1.69 + float(cylinder_index) * 0.28, 1.43, side * 0.52), Vector3(-1.65 + float(cylinder_index) * 0.28, 1.17, exhaust_z), Color("#8b9396"), 0.032, bay)
		create_visual_box(Vector3(1.04, 0.018, 0.028), Vector3(0, 0.15, 0), machined, bank)
	for throw_index in 4:
		var counterweight := create_visual_cylinder(0.15, 0.055, Vector3(-0.42 + float(throw_index) * 0.28, -0.05, 0), dark_metal, engine_area, Vector3(0, 0, PI * 0.5))
		counterweight.visible = false
		v8_internals.append(counterweight)

	# Intake sits in the V; a throttle body connects the separate air-filter box.
	var intake := create_box_part("intake_manifold", Vector3(0.82, 0.17, 0.27), Vector3(-1.27, 1.71, 0), dark_metal, bay)
	create_visual_box(Vector3(0.62, 0.045, 0.18), Vector3.ZERO, machined, intake)
	for cylinder_index in 4:
		var runner_x := -1.69 + float(cylinder_index) * 0.28
		for side in [-1.0, 1.0]:
			create_pipe(Vector3(runner_x, 1.70, side * 0.12), Vector3(runner_x, 1.60, side * 0.29), Color("#788287"), 0.034, bay)
	create_visual_cylinder(0.12, 0.16, Vector3(-1.76, 1.70, 0), machined, bay, Vector3(0, 0, PI * 0.5))

	# Exhaust collectors leave the outside of each bank, then pass under the floor.
	create_box_part("exhaust_manifold", Vector3(1.02, 0.105, 0.10), Vector3(-1.23, 1.14, 0.68), machined, bay)
	create_visual_box(Vector3(1.02, 0.105, 0.10), Vector3(-1.23, 1.14, -0.68), machined, bay)
	for side in [-1.0, 1.0]:
		create_pipe(Vector3(-0.73, 1.14, side * 0.68), Vector3(-0.58, 0.93, side * 0.68), Color("#697177"), 0.055, bay)
		create_pipe(Vector3(-0.58, 0.33, side * 0.68), Vector3(0.25, 0.33, side * 0.68), Color("#697177"), 0.055)
		create_visual_box(Vector3(0.40, 0.17, 0.20), Vector3(0.42, 0.33, side * 0.68), machined, car)
	create_pipe(Vector3(0.62, 0.33, 0.68), Vector3(1.25, 0.34, -0.62), Color("#697177"), 0.055)
	create_pipe(Vector3(0.62, 0.33, -0.68), Vector3(1.25, 0.34, -0.62), Color("#697177"), 0.055)
	create_visual_box(Vector3(0.58, 0.23, 0.30), Vector3(1.75, 0.37, -0.62), dark_metal, car)

	# Front accessory belt: crank pulley, alternator and coolant pump.
	create_visual_cylinder(0.19, 0.045, Vector3(-1.94, 1.12, 0), dark_metal, bay, Vector3(0, 0, PI * 0.5))
	create_cylinder_part("alternator", 0.15, 0.23, Vector3(-1.91, 1.32, -0.43), machined, bay, Vector3(0, 0, PI * 0.5))
	create_cylinder_part("water_pump", 0.12, 0.20, Vector3(-1.94, 1.25, 0.33), machined, bay, Vector3(0, 0, PI * 0.5))
	for pulley in [Vector3(-2.045, 1.12, 0), Vector3(-2.045, 1.32, -0.43), Vector3(-2.045, 1.25, 0.33)]:
		create_visual_cylinder(0.105, 0.025, pulley, dark_metal, bay, Vector3(0, 0, PI * 0.5))
	create_pipe(Vector3(-2.07, 1.12, 0), Vector3(-2.07, 1.32, -0.43), Color("#15191b"), 0.024, bay)
	create_pipe(Vector3(-2.07, 1.32, -0.43), Vector3(-2.07, 1.25, 0.33), Color("#15191b"), 0.024, bay)
	create_pipe(Vector3(-2.07, 1.25, 0.33), Vector3(-2.07, 1.12, 0), Color("#15191b"), 0.024, bay)

	# The crank output points rearwards into gearbox, prop shaft and rear differential.
	create_visual_cylinder(0.29, 0.27, Vector3(-0.60, 0.64, 0), cast_iron, car, Vector3(0, 0, PI * 0.5))
	create_box_part("transmission", Vector3(0.82, 0.34, 0.43), Vector3(-0.09, 0.59, 0), machined, car)
	create_cylinder_part("driveshaft", 0.075, 1.22, Vector3(0.91, 0.47, 0), dark_metal, car, Vector3(0, 0, PI * 0.5))
	create_sphere_part("differential", 0.23, Vector3(1.74, 0.53, 0), cast_iron, car)
	for side in [-1.0, 1.0]:
		create_pipe(Vector3(1.74, 0.53, side * 0.20), Vector3(1.72, 0.63, side * 1.05), Color("#545d62"), 0.065)
		create_pipe(Vector3(-1.72, 0.63, side * 1.06), Vector3(-1.53, 1.25, side * 0.87), Color("#3b4347"), 0.055)


func build_interior_details(leather: Material, rubber: Material, metal: Material) -> void:
	var trim := make_material(Color("#222a2e"), 0.72, 0.08)
	var soft := make_material(Color("#30383d"), 0.88, 0.0)
	var silver := make_material(Color("#819097"), 0.32, 0.76)
	var screen := make_emissive(Color("#152f42"), 0.36)
	var warm := make_emissive(Color("#efa861"), 0.8)
	var red_light := make_emissive(RED, 0.8)

	# A layered dashboard: broad matte fascia, padded lip, instrument binnacle.
	create_visual_box(Vector3(0.43, 0.35, 1.94), Vector3(-0.07, 1.55, 0), trim, car)
	create_visual_box(Vector3(0.52, 0.055, 1.94), Vector3(-0.07, 1.76, 0), soft, car)
	create_visual_box(Vector3(0.045, 0.035, 1.79), Vector3(-0.075, 1.43, 0), silver, car)
	create_box_part("dashboard", Vector3(0.07, 0.08, 0.14), Vector3(-0.055, 1.73, -0.76), soft, car)
	create_visual_box(Vector3(0.14, 0.26, 0.68), Vector3(-0.05, 1.63, 0.57), rubber, car)
	var cluster := create_box_part("instrument_cluster", Vector3(0.035, 0.24, 0.49), Vector3(0.04, 1.65, 0.60), screen, car)
	for dial_z in [-0.17, 0.17]:
		var dial := MeshInstance3D.new()
		var ring := TorusMesh.new()
		ring.inner_radius = 0.073
		ring.outer_radius = 0.084
		dial.mesh = ring
		dial.rotation.z = PI * 0.5
		dial.position = Vector3(0.027, 0.005, dial_z)
		dial.material_override = silver
		cluster.add_child(dial)
		create_visual_box(Vector3(0.012, 0.07, 0.009), Vector3(0.047, 0.005, dial_z), warm, cluster, Vector3(0.55, 0, 0))
	for light_z in [-0.045, 0.0, 0.045]:
		create_visual_box(Vector3(0.014, 0.018, 0.018), Vector3(0.041, -0.078, light_z), red_light if light_z == 0.0 else warm, cluster)
	for side in [-1, 1]:
		var arrow := create_visual_box(Vector3(0.015, 0.024, 0.035), Vector3(0.044, 0.07, side * 0.20), warm, cluster)
		arrow.visible = false
		if side < 0:
			indicator_left.append(arrow)
		else:
			indicator_right.append(arrow)

	# Steering column, central hub, three spokes, plus tactile stalks.
	create_visual_cylinder(0.075, 0.32, Vector3(0.11, 1.55, 0.62), rubber, car, Vector3(0, 0, PI * 0.5))
	var steer_area: Area3D = parts["steering"]
	create_visual_cylinder(0.083, 0.055, Vector3(0, 0, 0), silver, steer_area, Vector3(0, 0, PI * 0.5))
	for spoke_z in [-0.14, 0.14]:
		create_visual_box(Vector3(0.022, 0.045, 0.20), Vector3(0, -0.055, spoke_z), rubber, steer_area, Vector3(0, -0.28 if spoke_z < 0.0 else 0.28, 0))
	create_visual_box(Vector3(0.022, 0.16, 0.045), Vector3(0, 0.16, 0), rubber, steer_area)
	create_box_part("turn_signal", Vector3(0.27, 0.045, 0.045), Vector3(0.15, 1.55, 0.29), rubber, car)
	create_visual_box(Vector3(0.065, 0.056, 0.075), Vector3(0.28, 1.55, 0.29), silver, car)
	create_box_part("wiper_stalk", Vector3(0.27, 0.045, 0.045), Vector3(0.15, 1.55, 0.94), rubber, car)
	create_visual_box(Vector3(0.065, 0.056, 0.075), Vector3(0.28, 1.55, 0.94), silver, car)
	var start: Area3D = create_cylinder_part("ignition", 0.055, 0.025, Vector3(0.035, 1.51, 0.18), red_light, car, Vector3(0, 0, PI * 0.5))
	create_visual_cylinder(0.069, 0.012, Vector3(-0.015, 0, 0), silver, start, Vector3(0, 0, PI * 0.5))

	# Centre display and physical climate controls stay separate and clickable.
	var display := create_box_part("center_screen", Vector3(0.06, 0.25, 0.40), Vector3(-0.045, 1.68, 0), screen, car)
	create_visual_box(Vector3(0.009, 0.025, 0.28), Vector3(0.039, 0.07, 0), make_emissive(CYAN, 0.7), display)
	create_interior_label("AUTO//LAB", Vector3(0.041, 0.015, 0), display, 18)
	for bar in range(4):
		create_visual_box(Vector3(0.01, 0.018, 0.035), Vector3(0.039, -0.055, -0.105 + bar * 0.065), make_emissive(Color("#6aa3ba"), 0.55), display)
	var climate := create_box_part("climate", Vector3(0.055, 0.16, 0.42), Vector3(-0.015, 1.45, 0), trim, car)
	for knob_z in [-0.135, 0.135]:
		create_visual_cylinder(0.048, 0.022, Vector3(0.05, 0, knob_z), silver, climate, Vector3(0, 0, PI * 0.5))
		var climate_light := create_visual_box(Vector3(0.012, 0.012, 0.06), Vector3(0.069, 0.045, knob_z), make_emissive(CYAN, 0.2), climate)
		climate_light.visible = false
		climate_lights.append(climate_light)
	var hazard := create_box_part("hazard", Vector3(0.045, 0.055, 0.075), Vector3(0.01, 1.34, 0), red_light, car)
	create_visual_box(Vector3(0.012, 0.015, 0.04), Vector3(0.03, 0, 0), silver, hazard)
	for vent_z in [-0.79, 0.79]:
		var vent := create_box_part("air_vent", Vector3(0.055, 0.14, 0.25), Vector3(-0.03, 1.58, vent_z), rubber, car)
		for louver in [-0.045, 0.0, 0.045]:
			create_visual_box(Vector3(0.012, 0.014, 0.21), Vector3(0.035, louver, 0), silver, vent)

	# Centre tunnel: stitched armrest, shifter, handbrake and recessed holders.
	create_visual_box(Vector3(0.72, 0.12, 0.34), Vector3(0.52, 1.28, 0), leather, car)
	var gear := create_box_part("gear_selector", Vector3(0.12, 0.20, 0.12), Vector3(0.19, 1.37, 0.05), leather, car)
	create_visual_box(Vector3(0.20, 0.016, 0.22), Vector3(0, -0.095, 0), silver, gear)
	create_visual_box(Vector3(0.13, 0.025, 0.13), Vector3(0, 0.105, 0), trim, gear)
	var gear_mark := create_interior_label("P R N D", Vector3(0.34, 1.31, 0.16), car, 16)
	gear_mark.rotation.x = -PI * 0.5
	gear_mark.rotation.y = 0.0
	var parking := create_box_part("parking_brake", Vector3(0.21, 0.055, 0.07), Vector3(0.52, 1.38, -0.13), rubber, car)
	create_visual_box(Vector3(0.04, 0.015, 0.06), Vector3(0.10, 0.012, 0), warm, parking)
	var holders := create_box_part("cupholder", Vector3(0.20, 0.025, 0.31), Vector3(0.78, 1.33, 0.02), trim, car)
	for z in [-0.075, 0.075]:
		create_visual_cylinder(0.053, 0.012, Vector3(0, 0.015, z), rubber, holders)

	# Driver footwell: the brake pedal is wider than the accelerator.
	var pedals := create_box_part("pedals", Vector3(0.30, 0.23, 0.48), Vector3(-0.27, 0.99, 0.58), rubber, car)
	for pedal_z in [-0.12, 0.13]:
		create_visual_box(Vector3(0.05, 0.20, 0.035), Vector3(0, 0.01, pedal_z), silver, pedals)
		create_visual_box(Vector3(0.035, 0.055, 0.14 if pedal_z < 0.0 else 0.09), Vector3(0.05, -0.05, pedal_z), rubber, pedals)

	# Seat belt webbing, buckle, door card and small reachable switches.
	create_pipe(Vector3(0.73, 1.95, 0.90), Vector3(0.27, 1.22, 0.31), Color("#9ea8a7"), 0.022)
	create_box_part("seat_belt", Vector3(0.09, 0.11, 0.07), Vector3(0.26, 1.24, 0.31), red_light, car)
	for side_z in [-0.86, 0.86]:
		create_visual_box(Vector3(1.36, 0.51, 0.055), Vector3(0.70, 1.43, side_z), soft, car)
		create_visual_box(Vector3(0.70, 0.075, 0.10), Vector3(0.53, 1.62, side_z * 0.97), soft, car)
	var door := create_box_part("door_controls", Vector3(0.31, 0.075, 0.08), Vector3(0.36, 1.58, 0.86), silver, car)
	for button_x in [-0.085, -0.015, 0.055]:
		create_visual_box(Vector3(0.04, 0.008, 0.044), Vector3(button_x, 0.046, -0.01), rubber, door)
	create_box_part("glovebox", Vector3(0.045, 0.20, 0.58), Vector3(-0.045, 1.48, -0.53), soft, car)
	create_visual_box(Vector3(0.025, 0.018, 0.14), Vector3(-0.018, 1.49, -0.53), silver, car)

	# Items above the windscreen, with small hardware instead of flat placeholders.
	var mirror := create_box_part("rearview_mirror", Vector3(0.065, 0.12, 0.32), Vector3(-0.19, 2.02, 0), silver, car)
	create_visual_box(Vector3(0.015, 0.19, 0.025), Vector3(-0.02, 0.13, 0), rubber, mirror)
	var visor := create_box_part("sun_visor", Vector3(0.20, 0.035, 0.48), Vector3(-0.06, 2.16, 0.56), leather, car)
	create_visual_box(Vector3(0.035, 0.035, 0.07), Vector3(-0.10, 0, 0.19), silver, visor)
	for side in [-1, 1]:
		for end_x in [-2.62, 2.64]:
			var indicator := create_visual_box(Vector3(0.05, 0.055, 0.15), Vector3(end_x, 0.97, side * 0.91), warm, car)
			indicator.visible = false
			if side < 0:
				indicator_left.append(indicator)
			else:
				indicator_right.append(indicator)
		var wiper_pivot := Node3D.new()
		wiper_pivot.position = Vector3(-0.22, 1.78, side * 0.43)
		car.add_child(wiper_pivot)
		create_visual_box(Vector3(0.025, 0.018, 0.53), Vector3(0, 0, -side * 0.17), rubber, wiper_pivot)
		wiper_arms.append(wiper_pivot)

	var cabin_light := OmniLight3D.new()
	cabin_light.position = Vector3(0.35, 2.08, 0)
	cabin_light.light_color = Color("#e4edf1")
	cabin_light.light_energy = 0.5
	cabin_light.omni_range = 3.2
	car.add_child(cabin_light)


func build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var top_left := PanelContainer.new()
	top_left.position = Vector2(28, 24)
	top_left.size = Vector2(410, 92)
	top_left.add_theme_stylebox_override("panel", panel_style(Color(0.025, 0.05, 0.09, 0.9), 18, CYAN, 1))
	layer.add_child(top_left)
	var title_box := VBoxContainer.new()
	title_box.add_theme_constant_override("separation", 2)
	title_box.set_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 18)
	top_left.add_child(title_box)
	var brand := Label.new()
	brand.text = "AUTO//LAB"
	brand.add_theme_font_size_override("font_size", 27)
	brand.add_theme_color_override("font_color", INK)
	title_box.add_child(brand)
	var subtitle := Label.new()
	subtitle.text = "INTERAKTIVER FAHRZEUG-SIMULATOR  ·  GODOT 4"
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.add_theme_color_override("font_color", CYAN)
	title_box.add_child(subtitle)

	var help := Label.new()
	help.text = "ZIEHEN: umsehen   ·   MAUSRAD: Zoom   ·   KLICK: untersuchen   ·   F: Fokus   ·   G: Gesamt   ·   I: Innenraum"
	help.position = Vector2(30, 126)
	help.add_theme_font_size_override("font_size", 12)
	help.add_theme_color_override("font_color", Color("#d4e4f5"))
	layer.add_child(help)

	var right := PanelContainer.new()
	right.anchor_left = 1.0
	right.anchor_right = 1.0
	right.anchor_bottom = 1.0
	right.offset_left = -410
	right.offset_top = 24
	right.offset_right = -24
	right.offset_bottom = -190
	right.add_theme_stylebox_override("panel", panel_style(PANEL, 22, Color("#18314a"), 1))
	layer.add_child(right)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	content.set_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 22)
	right.add_child(content)

	info_kicker = Label.new()
	info_kicker.text = "BAUTEIL"
	info_kicker.add_theme_font_size_override("font_size", 12)
	info_kicker.add_theme_color_override("font_color", CYAN)
	content.add_child(info_kicker)
	info_title = Label.new()
	info_title.text = "Wähle ein Bauteil"
	info_title.add_theme_font_size_override("font_size", 25)
	info_title.add_theme_color_override("font_color", INK)
	info_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(info_title)
	component_selector = OptionButton.new()
	component_selector.custom_minimum_size.y = 38
	for id in PART_ORDER:
		component_selector.add_item(str(component_data[id].name))
		component_selector.set_item_metadata(component_selector.item_count - 1, id)
	component_selector.item_selected.connect(func(index: int): select_part(str(component_selector.get_item_metadata(index))))
	content.add_child(component_selector)
	var divider := HSeparator.new()
	divider.add_theme_color_override("separator", Color("#24425d"))
	content.add_child(divider)
	info_body = RichTextLabel.new()
	info_body.bbcode_enabled = true
	info_body.fit_content = false
	info_body.custom_minimum_size.y = 165
	info_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_body.add_theme_font_size_override("normal_font_size", 15)
	info_body.add_theme_color_override("default_color", Color("#c8d4e5"))
	content.add_child(info_body)
	var graph_caption := Label.new()
	graph_caption.text = "TEMPERATURVERLAUF  ·  LETZTE 24 SEKUNDEN"
	graph_caption.add_theme_font_size_override("font_size", 11)
	graph_caption.add_theme_color_override("font_color", MUTED)
	content.add_child(graph_caption)
	temp_graph = Control.new()
	temp_graph.custom_minimum_size.y = 78
	temp_graph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	temp_graph.draw.connect(draw_temperature_graph)
	content.add_child(temp_graph)
	action_hint = Label.new()
	action_hint.text = "Bauteil anklicken, um mehr zu erfahren."
	action_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	action_hint.add_theme_font_size_override("font_size", 12)
	action_hint.add_theme_color_override("font_color", MUTED)
	content.add_child(action_hint)
	action_button = Button.new()
	action_button.text = "AKTION"
	action_button.custom_minimum_size.y = 48
	action_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	style_button(action_button, CYAN)
	action_button.pressed.connect(_on_action_pressed)
	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 8)
	content.add_child(action_row)
	action_row.add_child(action_button)
	focus_button = Button.new()
	focus_button.text = "FOKUS"
	focus_button.custom_minimum_size = Vector2(84, 48)
	style_button(focus_button, ORANGE)
	focus_button.pressed.connect(focus_selected)
	action_row.add_child(focus_button)

	# Bottom control deck.
	var deck := PanelContainer.new()
	deck.anchor_top = 1.0
	deck.anchor_right = 1.0
	deck.anchor_bottom = 1.0
	deck.offset_left = 24
	deck.offset_top = -166
	deck.offset_right = -24
	deck.offset_bottom = -24
	deck.add_theme_stylebox_override("panel", panel_style(Color(0.025, 0.05, 0.085, 0.97), 20, Color("#1b3a54"), 1))
	layer.add_child(deck)
	var deck_h := HBoxContainer.new()
	deck_h.add_theme_constant_override("separation", 18)
	deck_h.set_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 18)
	deck.add_child(deck_h)

	var controls := VBoxContainer.new()
	controls.custom_minimum_size.x = 350
	controls.add_theme_constant_override("separation", 8)
	deck_h.add_child(controls)
	var controls_title := Label.new()
	controls_title.text = "WERKSTATT-STEUERUNG"
	controls_title.add_theme_font_size_override("font_size", 12)
	controls_title.add_theme_color_override("font_color", MUTED)
	controls.add_child(controls_title)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	controls.add_child(buttons)
	start_button = Button.new()
	start_button.text = "▶ MOTOR STARTEN"
	start_button.custom_minimum_size = Vector2(165, 40)
	style_button(start_button, GREEN)
	start_button.pressed.connect(toggle_engine)
	buttons.add_child(start_button)
	hood_button = Button.new()
	hood_button.text = "HAUBE"
	hood_button.custom_minimum_size = Vector2(82, 40)
	style_button(hood_button, CYAN)
	hood_button.pressed.connect(toggle_hood)
	buttons.add_child(hood_button)
	xray_button = Button.new()
	xray_button.text = "RÖNTGEN"
	xray_button.custom_minimum_size = Vector2(90, 40)
	style_button(xray_button, ORANGE)
	xray_button.pressed.connect(toggle_xray)
	buttons.add_child(xray_button)
	var load_row := HBoxContainer.new()
	controls.add_child(load_row)
	var load_label := Label.new()
	load_label.text = "Motorlast"
	load_label.custom_minimum_size.x = 80
	load_label.add_theme_color_override("font_color", MUTED)
	load_row.add_child(load_label)
	load_slider = HSlider.new()
	load_slider.min_value = 0.0
	load_slider.max_value = 1.0
	load_slider.step = 0.01
	load_slider.value = load_value
	load_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	load_slider.value_changed.connect(func(v: float): load_value = v)
	load_row.add_child(load_slider)

	var vline := VSeparator.new()
	vline.add_theme_color_override("separator", Color("#24425d"))
	deck_h.add_child(vline)

	var telemetry := HBoxContainer.new()
	telemetry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	telemetry.add_theme_constant_override("separation", 24)
	deck_h.add_child(telemetry)
	var temp_card := make_metric_card(telemetry, "KÜHLMITTEL", "82 °C", CYAN)
	temp_value = temp_card[0]
	temp_bar = temp_card[1]
	temp_bar.min_value = 40
	temp_bar.max_value = 150
	temp_bar.value = engine_temp
	var rpm_card := make_metric_card(telemetry, "DREHZAHL", "0 U/min", GREEN)
	rpm_value = rpm_card[0]
	var pressure_card := make_metric_card(telemetry, "ÖLDRUCK", "0,0 bar", ORANGE)
	pressure_value = pressure_card[0]
	var health_card := make_metric_card(telemetry, "MOTORZUSTAND", "100 %", Color("#b48cff"))
	health_value = health_card[0]

	status_chip = Label.new()
	status_chip.text = "●  MOTOR AUS"
	status_chip.position = Vector2(30, 158)
	status_chip.add_theme_font_size_override("font_size", 14)
	status_chip.add_theme_color_override("font_color", MUTED)
	layer.add_child(status_chip)

	var drive_panel := PanelContainer.new()
	drive_panel.position = Vector2(26, 195)
	drive_panel.size = Vector2(285, 182)
	drive_panel.add_theme_stylebox_override("panel", panel_style(Color(0.025, 0.05, 0.085, 0.93), 14, Color("#29445a"), 1))
	layer.add_child(drive_panel)
	var drive_controls := VBoxContainer.new()
	drive_controls.add_theme_constant_override("separation", 6)
	drive_panel.add_child(drive_controls)
	drive_button = Button.new()
	drive_button.text = "PROBEFAHRT STARTEN"
	drive_button.custom_minimum_size.y = 39
	style_button(drive_button, GREEN)
	drive_button.pressed.connect(toggle_drive_mode)
	drive_controls.add_child(drive_button)
	interior_button = Button.new()
	interior_button.text = "INNENRAUM ANSEHEN"
	interior_button.custom_minimum_size.y = 36
	style_button(interior_button, CYAN)
	interior_button.pressed.connect(toggle_interior_mode)
	drive_controls.add_child(interior_button)
	speed_label = Label.new()
	speed_label.text = "0 km/h"
	speed_label.add_theme_font_size_override("font_size", 21)
	speed_label.add_theme_color_override("font_color", INK)
	drive_controls.add_child(speed_label)
	drive_hint = Label.new()
	drive_hint.text = "Teststrecke · W/S Gas/Bremse · A/D lenken"
	drive_hint.add_theme_font_size_override("font_size", 12)
	drive_hint.add_theme_color_override("font_color", Color("#c5d5e4"))
	drive_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	drive_controls.add_child(drive_hint)

	objective_label = Label.new()
	objective_label.text = "VERSUCH: Baue den Kühler aus und starte den Motor. Beobachte die Temperatur."
	objective_label.anchor_left = 0.5
	objective_label.anchor_right = 0.5
	objective_label.offset_left = -350
	objective_label.offset_right = 350
	objective_label.offset_top = 28
	objective_label.offset_bottom = 66
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_label.add_theme_font_size_override("font_size", 14)
	objective_label.add_theme_color_override("font_color", ORANGE)
	layer.add_child(objective_label)

	toast = Label.new()
	toast.anchor_left = 0.5
	toast.anchor_right = 0.5
	toast.anchor_top = 0.74
	toast.anchor_bottom = 0.74
	toast.offset_left = -280
	toast.offset_right = 280
	toast.offset_top = -28
	toast.offset_bottom = 28
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toast.add_theme_font_size_override("font_size", 15)
	toast.add_theme_stylebox_override("normal", panel_style(Color(0.025, 0.05, 0.08, 0.96), 14, CYAN, 1))
	toast.modulate.a = 0.0
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(toast)


func _process(delta: float) -> void:
	elapsed += delta
	if drive_mode:
		update_drive(delta)
	update_simulation(delta)
	sample_timer += delta
	if sample_timer >= 0.25:
		sample_timer -= 0.25
		temperature_samples.append(engine_temp)
		if temperature_samples.size() > 96:
			temperature_samples.pop_front()
		temp_graph.queue_redraw()
	update_markers(delta)
	update_dashboard()
	update_interior_controls()


func update_drive(delta: float) -> void:
	var throttle := 0.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		throttle += 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		throttle -= 1.0
	var steer := 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		steer += 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		steer -= 1.0
	apply_drive(delta, throttle, steer)


func apply_drive(delta: float, throttle: float, steer: float) -> void:
	if engine_on:
		var power := clampf(engine_health / 100.0, 0.25, 1.0)
		if not air_filter_installed:
			power *= 0.72
		if throttle > 0.0:
			speed_kmh = minf(135.0, speed_kmh + delta * 17.0 * throttle * power)
		elif throttle < 0.0:
			if speed_kmh > 0.0:
				speed_kmh = move_toward(speed_kmh, 0.0, delta * 28.0)
			else:
				speed_kmh = maxf(-18.0, speed_kmh + delta * 10.0 * throttle)
		else:
			speed_kmh = move_toward(speed_kmh, 0.0, delta * 3.0)
	else:
		speed_kmh = move_toward(speed_kmh, 0.0, delta * 10.0)
	var turn_strength := clampf(absf(speed_kmh) / 35.0, 0.0, 1.0)
	drive_heading += steer * delta * 0.8 * turn_strength * (-1.0 if speed_kmh < 0.0 else 1.0)
	car.rotation.y = drive_heading
	var forward := Vector3(-cos(drive_heading), 0, sin(drive_heading))
	car.position += forward * speed_kmh / 3.6 * delta
	if absf(car.position.x) > 430.0 or car.position.z < 27.5 or car.position.z > 44.5:
		car.position.x = clampf(car.position.x, -430.0, 430.0)
		car.position.z = clampf(car.position.z, 27.5, 44.5)
		speed_kmh = 0.0
	load_value = clampf(maxf(0.18, maxf(throttle, 0.0) * 0.62 + absf(speed_kmh) / 135.0 * 0.35), 0.0, 1.0)
	load_slider.value = load_value
	speed_label.text = "%d km/h" % int(absf(speed_kmh))
	orbit_focus = car.global_position + Vector3(0, 1.03, 0)
	orbit_yaw = 1.18 + drive_heading
	update_camera()


func toggle_drive_mode() -> void:
	if drive_mode:
		drive_mode = false
		drive_world.visible = false
		car.position = Vector3(0, 0.08, 0)
		car.rotation = Vector3.ZERO
		drive_heading = 0.0
		speed_kmh = 0.0
		speed_label.text = "0 km/h"
		drive_button.text = "PROBEFAHRT STARTEN"
		drive_hint.text = "Teststrecke · W/S Gas/Bremse · A/D lenken"
		load_slider.editable = true
		action_button.disabled = false
		focus_button.disabled = false
		hood_button.disabled = false
		xray_button.disabled = false
		interior_button.disabled = false
		reset_view()
		show_toast("Zurück in der Werkstatt. Teile können wieder bearbeitet werden.", CYAN)
		return
	if not engine_on:
		toggle_engine()
	if not engine_on:
		return
	if interior_mode:
		toggle_interior_mode()
	if hood_open:
		toggle_hood()
	drive_mode = true
	drive_world.visible = true
	car.position = Vector3(0, 0.08, 36)
	car.rotation = Vector3.ZERO
	drive_heading = 0.0
	speed_kmh = 0.0
	orbit_focus = car.global_position + Vector3(0, 1.03, 0)
	orbit_distance = 9.5
	orbit_pitch = -0.18
	drive_button.text = "ZUR WERKSTATT"
	drive_hint.text = "W/S Gas/Bremse · A/D lenken · Motortemperatur beachten"
	load_slider.editable = false
	action_button.disabled = true
	focus_button.disabled = true
	hood_button.disabled = true
	xray_button.disabled = true
	interior_button.disabled = true
	update_camera()
	show_toast("Probefahrt gestartet. W/S bewegen, A/D lenken.", GREEN)


func draw_temperature_graph() -> void:
	var graph_size := temp_graph.size
	if graph_size.x < 2.0 or graph_size.y < 2.0:
		return
	temp_graph.draw_rect(Rect2(Vector2.ZERO, graph_size), Color("#0a1827"), true)
	for threshold in [40.0, 90.0, 120.0]:
		var y: float = graph_size.y - (threshold - 20.0) / 130.0 * graph_size.y
		temp_graph.draw_line(Vector2(0, y), Vector2(graph_size.x, y), Color(RED if threshold == 120.0 else Color("#314052"), 0.38), 1.0)
	if temperature_samples.size() < 2:
		return
	var points := PackedVector2Array()
	for i in temperature_samples.size():
		var x := graph_size.x - float(temperature_samples.size() - 1 - i) / 95.0 * graph_size.x
		var y: float = graph_size.y - clamp((temperature_samples[i] - 20.0) / 130.0, 0.0, 1.0) * graph_size.y
		points.append(Vector2(x, y))
	temp_graph.draw_polyline(points, RED if engine_temp >= 118.0 else CYAN, 2.4, true)


func update_simulation(delta: float) -> void:
	var rpm := 0.0
	if engine_on:
		rpm = 850.0 + load_value * 4750.0
		if not air_filter_installed:
			rpm *= 0.76
		if not radiator_installed:
			coolant_level = maxf(0.0, coolant_level - delta * (0.08 + load_value * 0.06))
		if radiator_installed and coolant_level > 0.15:
			var target := 86.0 + load_value * 18.0
			engine_temp = move_toward(engine_temp, target, delta * (1.8 + load_value * 2.0) * coolant_level)
		else:
			engine_temp += delta * (4.2 + load_value * 13.5) * (1.0 if not radiator_installed else 0.65)
		if oil_installed:
			oil_pressure = 1.7 + load_value * 3.4
		else:
			oil_pressure = move_toward(oil_pressure, 0.15, delta * 4.0)
			engine_health -= delta * (2.3 + load_value * 4.0)
		if engine_temp > 118.0:
			steam.emitting = true
			engine_health -= delta * (engine_temp - 115.0) * 0.075
			if not danger_announced:
				danger_announced = true
				show_toast("WARNUNG: Motor überhitzt! Sicher abschalten.", RED)
		else:
			steam.emitting = false
		if engine_temp > 136.0 or engine_health <= 0.0:
			engine_health = max(engine_health, 0.0)
			engine_on = false
			smoke.emitting = true
			show_toast("MOTORSCHADEN – der Motor wurde automatisch gestoppt.", RED)
	else:
		oil_pressure = move_toward(oil_pressure, 0.0, delta * 2.2)
		engine_temp = move_toward(engine_temp, 24.0, delta * (3.0 if radiator_installed else 1.5))
		if engine_temp < 105.0:
			steam.emitting = false
		if engine_temp < 80.0:
			smoke.emitting = false
	if engine_health < 45.0 and engine_on:
		smoke.emitting = true
	engine_health = clamp(engine_health, 0.0, 100.0)
	rpm_value.text = "%d U/min" % int(rpm)


func update_dashboard() -> void:
	temp_value.text = "%d °C" % int(engine_temp)
	if selected_id == "coolant":
		action_hint.text = state_hint_for("coolant")
	coolant_fill_mesh.scale.y = maxf(0.02, coolant_level)
	coolant_fill_mesh.position.y = 1.30 + 0.08 * coolant_level
	coolant_fill_mesh.visible = coolant_level > 0.02
	temp_bar.value = engine_temp
	pressure_value.text = "%.1f bar" % oil_pressure
	health_value.text = "%d %%" % int(engine_health)
	var temp_color := CYAN
	if engine_temp >= 105.0:
		temp_color = ORANGE
	if engine_temp >= 118.0:
		temp_color = RED
	temp_value.add_theme_color_override("font_color", temp_color)
	status_chip.text = "●  MOTOR LÄUFT" if engine_on else "●  MOTOR AUS"
	status_chip.add_theme_color_override("font_color", GREEN if engine_on else MUTED)
	start_button.text = "■ MOTOR STOPPEN" if engine_on else "▶ MOTOR STARTEN"
	if selected_id == "ignition":
		action_button.text = action_text_for("ignition")
	if drive_mode:
		objective_label.text = "PROBEFAHRT · W/S fahren · A/D lenken · Temperatur beobachten"
		objective_label.add_theme_color_override("font_color", RED if engine_temp >= 118.0 else ORANGE)
	elif not radiator_installed:
		objective_label.text = "KÜHLER AUSGEBAUT  ·  Ohne Wärmeabfuhr steigt die Temperatur gefährlich an."
		objective_label.add_theme_color_override("font_color", RED if engine_on else ORANGE)
	elif coolant_level <= 0.15:
		objective_label.text = "KÜHLMITTEL LEER  ·  Motor aus, abkühlen lassen und Behälter auffüllen."
		objective_label.add_theme_color_override("font_color", RED)
	elif engine_temp > 110.0:
		objective_label.text = "ABKÜHLPHASE  ·  Kühler montiert – Temperatur sinkt langsam."
	else:
		objective_label.text = "INNENRAUM: I drücken und kleine Details untersuchen." if interior_mode else "VERSUCH: Baue den Kühler aus und starte den Motor. Beobachte die Temperatur."
		objective_label.add_theme_color_override("font_color", ORANGE)


func update_interior_controls() -> void:
	var flash := fmod(elapsed, 0.8) < 0.4
	for light in indicator_left:
		light.visible = flash and (hazard_on or indicator_side > 0)
	for light in indicator_right:
		light.visible = flash and (hazard_on or indicator_side < 0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = true
			else:
				dragging = false
				if event.position.distance_to(_drag_start) < 5.0:
					pick_part(event.position)
			if event.pressed:
				_drag_start = event.position
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			if interior_mode:
				interior_distance = maxf(2.2, interior_distance - 0.35)
			else:
				orbit_distance = max(5.1, orbit_distance - 0.65)
			update_camera()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			if interior_mode:
				interior_distance = minf(6.5, interior_distance + 0.35)
			else:
				orbit_distance = min(14.0, orbit_distance + 0.65)
			update_camera()
	elif event is InputEventMouseMotion:
		if dragging:
			if interior_mode:
				interior_yaw -= event.relative.x * 0.006
				interior_pitch = clampf(interior_pitch - event.relative.y * 0.005, -1.25, -0.18)
			else:
				orbit_yaw -= event.relative.x * 0.006
				orbit_pitch = clamp(orbit_pitch - event.relative.y * 0.005, -0.72, 0.16)
			update_camera()
		else:
			hover_part(event.position)
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_R: reset_simulation()
			KEY_F: focus_selected()
			KEY_G: reset_view()
			KEY_I: toggle_interior_mode()


var _drag_start := Vector2.ZERO


func update_camera() -> void:
	if interior_mode:
		camera.fov = 50.0
		var focus := car.to_global(interior_focus)
		var flat := cos(interior_pitch) * interior_distance
		camera.position = focus + car.global_basis * Vector3(sin(interior_yaw) * flat, -sin(interior_pitch) * interior_distance, cos(interior_yaw) * flat)
		camera.look_at(focus, Vector3.UP)
		return
	camera.fov = 46.0
	var flat := cos(orbit_pitch) * orbit_distance
	var pos := Vector3(sin(orbit_yaw) * flat, -sin(orbit_pitch) * orbit_distance + 1.1, cos(orbit_yaw) * flat)
	camera.position = orbit_focus + pos
	camera.look_at(orbit_focus, Vector3.UP)


func raycast_part(screen_pos: Vector2) -> Area3D:
	var origin := camera.project_ray_origin(screen_pos)
	var end := origin + camera.project_ray_normal(screen_pos) * 50.0
	var excluded: Array[RID] = []
	var body_candidate: Area3D
	for attempt in 8:
		var query := PhysicsRayQueryParameters3D.create(origin, end, 2)
		query.collide_with_areas = true
		query.collide_with_bodies = false
		query.exclude = excluded
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if not hit or not hit.collider is Area3D:
			break
		var area := hit.collider as Area3D
		if str(area.get_meta("part_id", "")) != "body":
			return area
		body_candidate = area
		excluded.append(area.get_rid())
	return body_candidate


func pick_part(screen_pos: Vector2) -> void:
	if get_viewport().gui_get_hovered_control() != null:
		return
	var area := raycast_part(screen_pos)
	if area and area.has_meta("part_id"):
		select_part(str(area.get_meta("part_id")))


func hover_part(screen_pos: Vector2) -> void:
	if get_viewport().gui_get_hovered_control() != null:
		clear_hover()
		return
	var area := raycast_part(screen_pos)
	if area == hover_area:
		return
	clear_hover()
	hover_area = area
	if hover_area and hover_area != selected_area:
		set_area_highlight(hover_area, true)
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)


func clear_hover() -> void:
	if hover_area and hover_area != selected_area:
		set_area_highlight(hover_area, false)
	hover_area = null
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func select_part(id: String) -> void:
	if not component_data.has(id):
		return
	if selected_area:
		set_area_highlight(selected_area, false)
	selected_id = id
	for index in component_selector.item_count:
		if str(component_selector.get_item_metadata(index)) == id:
			component_selector.select(index)
			break
	selected_area = parts.get(id)
	if selected_area:
		set_area_highlight(selected_area, true)
	var data: Dictionary = component_data[id]
	info_kicker.text = str(data.category)
	info_title.text = str(data.name)
	info_body.text = str(data.body)
	action_button.text = action_text_for(id)
	action_hint.text = state_hint_for(id)


func action_text_for(id: String) -> String:
	match id:
		"engine": return "V8-SCHNITT SCHLIESSEN" if v8_cutaway else "V8-SCHNITT ÖFFNEN"
		"radiator": return "KÜHLER AUSBAUEN" if radiator_installed else "KÜHLER EINBAUEN"
		"battery": return "BATTERIE AUSBAUEN" if battery_installed else "BATTERIE EINBAUEN"
		"air_filter": return "LUFTFILTER AUSBAUEN" if air_filter_installed else "LUFTFILTER EINBAUEN"
		"oil": return "ÖL ABLASSEN" if oil_installed else "ÖL AUFFÜLLEN"
		"coolant": return "KÜHLMITTEL AUFFÜLLEN"
		"hood": return "HAUBE SCHLIESSEN" if hood_open else "HAUBE ÖFFNEN"
		"body": return "RÖNTGEN AUSSCHALTEN" if xray_enabled else "RÖNTGEN AKTIVIEREN"
		"ignition": return "MOTOR STOPPEN" if engine_on else "MOTOR STARTEN"
		"climate": return "GEBLÄSE AUSSCHALTEN" if climate_on else "GEBLÄSE EINSCHALTEN"
		"hazard": return "WARNBLINKER AUS" if hazard_on else "WARNBLINKER AN"
		_: return str(component_data[id].action).to_upper()


func focus_selected() -> void:
	if drive_mode:
		return
	if not selected_area or not is_instance_valid(selected_area):
		return
	if is_interior_part(selected_id):
		if not interior_mode:
			toggle_interior_mode()
		interior_focus = car.to_local(selected_area.global_position)
		interior_distance = 2.6
		update_camera()
		return
	if interior_mode:
		toggle_interior_mode()
	if selected_id in ["engine", "v8_bank_left", "v8_bank_right", "intake_manifold", "exhaust_manifold", "alternator", "water_pump", "radiator", "battery", "air_filter", "coolant", "oil"]:
		set_hood_open(true, false)
	if selected_id in ["transmission", "driveshaft", "differential"] and not xray_enabled:
		toggle_xray(true)
	orbit_focus = selected_area.global_position + Vector3(0, 0.12, 0)
	orbit_distance = 5.2
	if selected_id in ["transmission", "driveshaft", "differential"]:
		orbit_yaw = 0.0
		orbit_pitch = 0.12
		orbit_distance = 6.0
	update_camera()


func reset_view() -> void:
	if interior_mode:
		interior_mode = false
		interior_button.text = "INNENRAUM ANSEHEN"
		cabin_glass.visible = true
		roof_mesh.visible = true
		set_hood_open(interior_saved_hood_open, false)
		hood_button.disabled = false
	orbit_focus = Vector3(0, 1.05, 0)
	orbit_distance = 8.7
	orbit_yaw = -0.72
	orbit_pitch = -0.17
	update_camera()


func is_interior_part(id: String) -> bool:
	return component_data.has(id) and str(component_data[id].category).begins_with("INNENRAUM")


func toggle_interior_mode() -> void:
	if drive_mode:
		return
	interior_mode = not interior_mode
	interior_yaw = 0.55
	interior_pitch = -1.05
	interior_distance = 3.3
	interior_focus = Vector3(0.88, 1.40, 0)
	cabin_glass.visible = not interior_mode
	roof_mesh.visible = not interior_mode
	if interior_mode:
		interior_saved_hood_open = hood_open
		set_hood_open(false, false)
	else:
		set_hood_open(interior_saved_hood_open, false)
	hood_button.disabled = interior_mode
	interior_button.text = "AUSSENANSICHT" if interior_mode else "INNENRAUM ANSEHEN"
	update_camera()
	show_toast("Innenraum: klicke oder wähle ein Detail und drücke F." if interior_mode else "Außenansicht wiederhergestellt.", CYAN)


func state_hint_for(id: String) -> String:
	match id:
		"engine": return "Schnittmodell: %s · zwei Bänke mit je vier Zylindern" % ("offen" if v8_cutaway else "geschlossen")
		"radiator": return "Status: %s" % ("montiert" if radiator_installed else "ausgebaut – Kühlung unterbrochen")
		"battery": return "Status: %s" % ("angeschlossen" if battery_installed else "ausgebaut – Start nicht möglich")
		"air_filter": return "Status: %s" % ("montiert" if air_filter_installed else "ausgebaut – Schmutzrisiko")
		"oil": return "Status: %s" % ("Ölkreislauf gefüllt" if oil_installed else "kein Öldruck – Motorschaden droht")
		"coolant": return "Kühlmittelstand: %d %%" % int(coolant_level * 100.0)
		"turn_signal": return "Blinker: %s" % ("aus" if indicator_side == 0 else "links" if indicator_side > 0 else "rechts")
		"climate": return "Gebläse: %s" % ("an" if climate_on else "aus")
		"hazard": return "Warnblinker: %s" % ("an" if hazard_on else "aus")
		_: return "Tipp: Bauteile leuchten beim Berühren auf."


func set_area_highlight(area: Area3D, enabled: bool) -> void:
	if not is_instance_valid(area):
		return
	for child in area.find_children("*", "MeshInstance3D", true, false):
		if not child.has_meta("marker"):
			(child as MeshInstance3D).material_overlay = highlight_material if enabled else null


func _on_action_pressed() -> void:
	if interior_mode and selected_id == "hood":
		show_toast("Wechsle zur Außenansicht, um die Haube zu bewegen.", ORANGE)
		return
	match selected_id:
		"radiator": toggle_radiator()
		"battery": toggle_removable("battery")
		"air_filter": toggle_removable("air_filter")
		"oil": toggle_oil()
		"hood": toggle_hood()
		"engine": toggle_v8_cutaway()
		"v8_bank_left", "v8_bank_right":
			toggle_v8_cutaway(true)
			focus_selected()
		"intake_manifold", "exhaust_manifold", "alternator", "water_pump", "transmission", "driveshaft", "differential":
			focus_selected()
			show_toast("Bauteil im V8-Antriebsstrang: %s" % component_data[selected_id].name, CYAN)
		"coolant": refill_coolant()
		"body": toggle_xray()
		"steering": animate_steering()
		"headlight": toggle_headlights()
		"ignition": toggle_engine()
		"turn_signal":
			indicator_side = 1 if indicator_side == 0 else -1 if indicator_side == 1 else 0
			show_toast("Blinker %s." % ("links" if indicator_side > 0 else "rechts" if indicator_side < 0 else "aus"), ORANGE)
		"wiper_stalk":
			for arm in wiper_arms:
				var sweep := create_tween()
				sweep.tween_property(arm, "rotation:x", 0.55, 0.3)
				sweep.tween_property(arm, "rotation:x", 0.0, 0.3)
			show_toast("Wischer räumen Regen von der Frontscheibe.", CYAN)
		"climate":
			climate_on = not climate_on
			for light in climate_lights:
				light.visible = climate_on
			show_toast("Gebläse %s." % ("eingeschaltet" if climate_on else "ausgeschaltet"), CYAN)
		"hazard":
			hazard_on = not hazard_on
			show_toast("Warnblinker %s." % ("eingeschaltet" if hazard_on else "ausgeschaltet"), ORANGE)
		"instrument_cluster":
			show_toast("%d km/h · %.0f °C · Motor %s" % [int(absf(speed_kmh)), engine_temp, "an" if engine_on else "aus"], CYAN)
		"exhaust":
			orbit_yaw = 1.1
			update_camera()
			show_toast("Abgasweg: Motor → Katalysator → Schalldämpfer → Endrohr", CYAN)
		"fuel_tank":
			toggle_xray(true)
			show_toast("Der Tank liegt tief und geschützt vor der Hinterachse.", CYAN)
		_:
			if selected_id.begins_with("wheel_"):
				animate_wheel(parts[selected_id])
			elif is_interior_part(selected_id):
				focus_selected()
				show_toast("Detail im Innenraum: %s" % component_data[selected_id].name, CYAN)
	if is_interior_part(selected_id):
		action_button.text = action_text_for(selected_id)
		action_hint.text = state_hint_for(selected_id)


func toggle_engine() -> void:
	if engine_on:
		engine_on = false
		show_toast("Motor ausgeschaltet. Restwärme bleibt im System.", CYAN)
		return
	if not battery_installed:
		show_toast("Start nicht möglich: Die 12-Volt-Batterie fehlt.", RED)
		return
	if engine_health <= 5.0:
		show_toast("Start nicht möglich: Der Motor ist beschädigt. Drücke R zum Zurücksetzen.", RED)
		return
	engine_on = true
	danger_announced = false
	show_toast("Motor läuft. Verändere unten die Motorlast.", GREEN)


func toggle_radiator() -> void:
	radiator_installed = not radiator_installed
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	if radiator_installed:
		tween.tween_property(radiator_area, "position", radiator_home, 0.65)
		tween.parallel().tween_property(radiator_area, "rotation", Vector3.ZERO, 0.65)
		action_button.text = "KÜHLER AUSBAUEN"
		show_toast("Kühler montiert. Prüfe jetzt den Kühlmittelstand.", GREEN)
	else:
		coolant_level = minf(coolant_level, 0.45)
		coolant_puddle.visible = true
		tween.tween_property(radiator_area, "position", Vector3(-4.00, 0.79, -0.05), 0.8)
		tween.parallel().tween_property(radiator_area, "rotation", Vector3(0.0, 0.0, deg_to_rad(-85)), 0.8)
		action_button.text = "KÜHLER EINBAUEN"
		show_toast("Kühler ausgebaut! Starte den Motor und beobachte die Wärme.", ORANGE)
	action_hint.text = state_hint_for("radiator")


func refill_coolant() -> void:
	if not radiator_installed:
		show_toast("Erst den Kühler einbauen – sonst läuft neues Kühlmittel aus.", ORANGE)
		return
	if engine_on:
		show_toast("Motor zuerst ausschalten. Der Kühlkreislauf steht unter Druck.", RED)
		return
	if engine_temp > 70.0:
		show_toast("Motor noch zu heiß: erst abkühlen lassen, dann auffüllen.", RED)
		return
	coolant_level = 1.0
	action_hint.text = state_hint_for("coolant")
	show_toast("Kühlmittel aufgefüllt. Der Kühlkreislauf ist wieder betriebsbereit.", GREEN)


func toggle_removable(id: String) -> void:
	var area: Area3D = parts[id]
	var installed: bool
	if id == "battery":
		battery_installed = not battery_installed
		installed = battery_installed
	else:
		air_filter_installed = not air_filter_installed
		installed = air_filter_installed
	var home: Vector3 = area.get_meta("home_position")
	var target := home if installed else home + Vector3(0, 1.2, 1.65)
	create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).tween_property(area, "position", target, 0.65)
	action_button.text = (("BATTERIE" if id == "battery" else "LUFTFILTER") + (" AUSBAUEN" if installed else " EINBAUEN"))
	action_hint.text = state_hint_for(id)
	show_toast(("Bauteil wieder montiert." if installed else "Bauteil ausgebaut – die Simulation reagiert darauf."), GREEN if installed else ORANGE)


func toggle_oil() -> void:
	oil_installed = not oil_installed
	var area: Area3D = parts["oil"]
	area.visible = oil_installed
	action_button.text = "ÖL ABLASSEN" if oil_installed else "ÖL AUFFÜLLEN"
	action_hint.text = state_hint_for("oil")
	show_toast("Ölkreislauf gefüllt." if oil_installed else "Öl fehlt! Bei laufendem Motor fällt der Öldruck ab.", GREEN if oil_installed else RED)


func toggle_hood() -> void:
	set_hood_open(not hood_open, true)


func set_hood_open(open: bool, animate: bool) -> void:
	if hood_tween and hood_tween.is_running():
		hood_tween.kill()
	hood_open = open
	var target := deg_to_rad(-58.0) if hood_open else 0.0
	if animate:
		hood_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		hood_tween.tween_property(hood_pivot, "rotation:z", target, 0.75)
	else:
		hood_pivot.rotation.z = target
	hood_button.text = "HAUBE ZU" if hood_open else "HAUBE AUF"
	if selected_id == "hood":
		action_button.text = action_text_for("hood")


func toggle_xray(force_on := false) -> void:
	xray_enabled = true if force_on else not xray_enabled
	var body_area: Area3D = parts["body"]
	for child in body_area.find_children("*", "MeshInstance3D", true, false):
		(child as MeshInstance3D).transparency = 0.90 if xray_enabled else 0.0
		if child != body_area.get_child(0):
			(child as MeshInstance3D).visible = not xray_enabled
	for trim_mesh in xray_trim:
		trim_mesh.visible = not xray_enabled
	xray_button.text = "RÖNTGEN AN" if xray_enabled else "RÖNTGEN"
	if selected_id == "body":
		action_button.text = action_text_for("body")
	show_toast("Röntgenblick legt Motor und Antriebsstrang frei." if xray_enabled else "Karosserie wieder vollständig sichtbar.", CYAN)


func toggle_v8_cutaway(force_on := false) -> void:
	v8_cutaway = true if force_on else not v8_cutaway
	set_hood_open(true, false)
	for index in v8_covers.size():
		var cover: MeshInstance3D = v8_covers[index]
		cover.transparency = 0.76 if v8_cutaway else 0.0
		cover.visible = not v8_cutaway if index > 0 else true
	for detail in v8_internals:
		detail.visible = v8_cutaway
	if selected_id == "engine":
		action_button.text = action_text_for("engine")
		action_hint.text = state_hint_for("engine")
	show_toast("V8-Schnitt: acht Zylinder, zwei 45° geneigte Bänke und Kurbelwelle." if v8_cutaway else "V8 wieder geschlossen.", CYAN)


func animate_steering() -> void:
	var area: Area3D = parts["steering"]
	var tween := create_tween()
	tween.tween_property(area, "rotation:x", -0.65, 0.3)
	tween.tween_property(area, "rotation:x", 0.65, 0.55)
	tween.tween_property(area, "rotation:x", 0.0, 0.3)
	show_toast("Lenkeingabe bewegt über das Lenkgetriebe die Vorderräder.", CYAN)


func animate_wheel(area: Area3D) -> void:
	var tween := create_tween()
	tween.tween_property(area, "rotation:z", area.rotation.z + TAU * 2.0, 1.0)
	show_toast("Reifenprofil, Luftdruck und Schäden regelmäßig prüfen.", CYAN)


func toggle_headlights() -> void:
	for mesh in dashboard_lights:
		mesh.visible = not mesh.visible
	show_toast("Beleuchtung umgeschaltet.", CYAN)


func reset_simulation() -> void:
	if drive_mode:
		toggle_drive_mode()
	engine_on = false
	if v8_cutaway:
		toggle_v8_cutaway()
	if xray_enabled:
		toggle_xray()
	engine_temp = 24.0
	coolant_level = 1.0
	coolant_puddle.visible = false
	oil_pressure = 0.0
	engine_health = 100.0
	load_slider.value = 0.25
	danger_announced = false
	indicator_side = 0
	hazard_on = false
	climate_on = false
	for light in climate_lights:
		light.visible = false
	steam.emitting = false
	smoke.emitting = false
	temperature_samples.clear()
	temp_graph.queue_redraw()
	reset_view()
	if not radiator_installed: toggle_radiator()
	if not battery_installed: toggle_removable("battery")
	if not air_filter_installed: toggle_removable("air_filter")
	if not oil_installed: toggle_oil()
	show_toast("Simulation vollständig zurückgesetzt.", GREEN)


func update_markers(_delta: float) -> void:
	for id in ["radiator", "engine", "battery", "air_filter", "oil", "coolant"]:
		var area: Area3D = parts.get(id)
		if not area: continue
		for child in area.get_children():
			if child is MeshInstance3D and child.has_meta("marker"):
				child.scale = Vector3.ONE * (1.0 + sin(elapsed * 3.0 + area.position.x) * 0.26)


func show_toast(message: String, color: Color) -> void:
	toast.text = message
	toast.add_theme_color_override("font_color", color)
	toast.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(3.0)
	tween.tween_property(toast, "modulate:a", 0.0, 0.55)


func create_box_part(id: String, size: Vector3, pos: Vector3, material: Material, parent: Node3D) -> Area3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return create_part(id, mesh, BoxShape3D.new(), size, pos, material, parent)


func create_cylinder_part(id: String, radius: float, height: float, pos: Vector3, material: Material, parent: Node3D, rot := Vector3.ZERO) -> Area3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 28
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = height
	var area := create_part(id, mesh, shape, Vector3.ZERO, pos, material, parent)
	area.rotation = rot
	return area


func create_sphere_part(id: String, radius: float, pos: Vector3, material: Material, parent: Node3D) -> Area3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 28
	mesh.rings = 14
	var shape := SphereShape3D.new()
	shape.radius = radius
	return create_part(id, mesh, shape, Vector3.ZERO, pos, material, parent)


func create_part(id: String, mesh: Mesh, shape: Shape3D, shape_size: Vector3, pos: Vector3, material: Material, parent: Node3D) -> Area3D:
	var area := Area3D.new()
	area.name = "Part_" + id
	area.position = pos
	area.set_meta("part_id", id)
	area.set_meta("home_position", pos)
	area.collision_layer = 2
	area.collision_mask = 0
	parent.add_child(area)
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	area.add_child(mesh_instance)
	var collider := CollisionShape3D.new()
	if shape is BoxShape3D:
		shape.size = shape_size
	collider.shape = shape
	area.add_child(collider)
	parts[id] = area
	part_meshes[id] = [mesh_instance]
	return area


func create_loft_part(id: String, sections: Array[Vector4], collision_size: Vector3, material: Material, parent: Node3D, radial_segments := 24, engine_opening := false) -> Area3D:
	var mesh := make_loft_mesh(sections, radial_segments, engine_opening)
	return create_part(id, mesh, BoxShape3D.new(), collision_size, Vector3.ZERO, material, parent)


func create_loft_visual(sections: Array[Vector4], material: Material, parent: Node3D, radial_segments := 24) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = make_loft_mesh(sections, radial_segments)
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(instance)
	return instance


func create_glass_quad(points: PackedVector3Array, material: Material, parent: Node3D) -> MeshInstance3D:
	var normal := (points[1] - points[0]).cross(points[2] - points[0]).normalized()
	var normals := PackedVector3Array([normal, normal, normal, normal])
	var uvs := PackedVector2Array([Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2, 0, 2, 3])
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var pane := MeshInstance3D.new()
	pane.mesh = mesh
	pane.material_override = material
	pane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(pane)
	return pane


func make_loft_mesh(sections: Array[Vector4], radial_segments: int, engine_opening := false) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for i in sections.size():
		var section := sections[i]
		var previous := sections[max(0, i - 1)]
		var following := sections[min(sections.size() - 1, i + 1)]
		for j in radial_segments:
			var angle := TAU * float(j) / float(radial_segments)
			var point := Vector3(section.x, section.y + sin(angle) * section.z, cos(angle) * section.w)
			var prev_point := Vector3(previous.x, previous.y + sin(angle) * previous.z, cos(angle) * previous.w)
			var next_point := Vector3(following.x, following.y + sin(angle) * following.z, cos(angle) * following.w)
			var along := (next_point - prev_point).normalized()
			var around := Vector3(0, cos(angle) * section.z, -sin(angle) * section.w).normalized()
			vertices.append(point)
			normals.append(along.cross(around).normalized())
			uvs.append(Vector2(float(i) / max(1.0, sections.size() - 1.0), float(j) / radial_segments))
	for i in sections.size() - 1:
		for j in radial_segments:
			var midpoint_x: float = (sections[i].x + sections[i + 1].x) * 0.5
			var midpoint_angle := TAU * (float(j) + 0.5) / float(radial_segments)
			if engine_opening and midpoint_x > -2.5 and midpoint_x < -0.25 and midpoint_angle > PI * 0.24 and midpoint_angle < PI * 0.76:
				continue
			var next_j := (j + 1) % radial_segments
			var a := i * radial_segments + j
			var b := (i + 1) * radial_segments + j
			var c := (i + 1) * radial_segments + next_j
			var d := i * radial_segments + next_j
			indices.append_array(PackedInt32Array([a, c, b, a, d, c]))
	# Close both ends with separate vertices so the cap keeps a crisp normal.
	for cap_index in [0, sections.size() - 1]:
		var cap_normal := Vector3.LEFT if cap_index == 0 else Vector3.RIGHT
		var center_index := vertices.size()
		var cap := sections[cap_index]
		vertices.append(Vector3(cap.x, cap.y, 0))
		normals.append(cap_normal)
		uvs.append(Vector2(0.5, 0.5))
		var ring_start := vertices.size()
		for j in radial_segments:
			var angle := TAU * float(j) / float(radial_segments)
			vertices.append(Vector3(cap.x, cap.y + sin(angle) * cap.z, cos(angle) * cap.w))
			normals.append(cap_normal)
			uvs.append(Vector2(0.5 + sin(angle) * 0.5, 0.5 + cos(angle) * 0.5))
		for j in radial_segments:
			var next_j := (j + 1) % radial_segments
			if cap_index == 0:
				indices.append_array(PackedInt32Array([center_index, ring_start + j, ring_start + next_j]))
			else:
				indices.append_array(PackedInt32Array([center_index, ring_start + next_j, ring_start + j]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func create_interior_label(value: String, pos: Vector3, parent: Node3D, size: int) -> Label3D:
	var label := Label3D.new()
	label.text = value
	label.font_size = size
	label.pixel_size = 0.003
	label.modulate = Color("#d9eef7")
	label.position = pos
	label.rotation.y = PI * 0.5
	parent.add_child(label)
	return label


func create_visual_box(size: Vector3, pos: Vector3, material: Material, parent: Node3D, rot := Vector3.ZERO) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = pos
	instance.rotation = rot
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(instance)
	return instance


func create_visual_cylinder(radius: float, height: float, pos: Vector3, material: Material, parent: Node3D, rot := Vector3.ZERO) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 28
	instance.mesh = mesh
	instance.position = pos
	instance.rotation = rot
	instance.material_override = material
	parent.add_child(instance)
	return instance


func create_visual_sphere(radius: float, pos: Vector3, material: Material, parent: Node3D) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 32
	mesh.rings = 18
	instance.mesh = mesh
	instance.position = pos
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(instance)
	return instance


func make_wheel(id: String, pos: Vector3, tire_mat: Material, metal_mat: Material) -> void:
	var area := Area3D.new()
	area.name = "Part_" + id
	area.position = pos
	area.rotation.x = PI * 0.5
	area.set_meta("part_id", id)
	area.set_meta("home_position", pos)
	area.collision_layer = 2
	area.collision_mask = 0
	car.add_child(area)
	var collider := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.59
	shape.height = 0.30
	collider.shape = shape
	area.add_child(collider)
	var tire := MeshInstance3D.new()
	var tire_mesh := TorusMesh.new()
	tire_mesh.inner_radius = 0.40
	tire_mesh.outer_radius = 0.59
	tire_mesh.rings = 64
	tire_mesh.ring_segments = 20
	tire.mesh = tire_mesh
	tire.material_override = tire_mat
	area.add_child(tire)
	# Low-profile road tire, recessed brake disc, alloy rim and five slender spokes.
	create_visual_cylinder(0.405, 0.20, Vector3.ZERO, make_material(Color("#171b1d"), 0.75, 0.10), area)
	create_visual_cylinder(0.33, 0.035, Vector3(0, 0.10, 0), make_material(Color("#626a6d"), 0.38, 0.78), area)
	var rim := MeshInstance3D.new()
	var rim_mesh := TorusMesh.new()
	rim_mesh.inner_radius = 0.355
	rim_mesh.outer_radius = 0.405
	rim_mesh.rings = 64
	rim_mesh.ring_segments = 12
	rim.mesh = rim_mesh
	rim.position.y = 0.13
	rim.material_override = metal_mat
	area.add_child(rim)
	for angle_deg in range(0, 360, 72):
		var spoke := create_visual_box(Vector3(0.055, 0.045, 0.29), Vector3(0, 0.145, 0.19), metal_mat, area)
		spoke.rotation.y = deg_to_rad(angle_deg)
		var angle := deg_to_rad(angle_deg)
		create_visual_cylinder(0.018, 0.012, Vector3(sin(angle) * 0.11, 0.175, cos(angle) * 0.11), make_material(Color("#2d353a"), 0.45, 0.65), area)
	create_visual_cylinder(0.105, 0.08, Vector3(0, 0.17, 0), metal_mat, area)
	create_visual_box(Vector3(0.12, 0.055, 0.17), Vector3(0.26, 0.08, 0), make_car_paint(Color("#672e28")), area)
	var arch_z := 1.21 if pos.z > 0.0 else -1.21
	for segment in 16:
		var angle_a := PI * float(segment) / 16.0
		var angle_b := PI * float(segment + 1) / 16.0
		create_pipe(Vector3(pos.x + cos(angle_a) * 0.68, pos.y + sin(angle_a) * 0.68, arch_z), Vector3(pos.x + cos(angle_b) * 0.68, pos.y + sin(angle_b) * 0.68, arch_z), Color("#182026"), 0.018)
	parts[id] = area
	part_meshes[id] = [tire]


func create_pipe(from: Vector3, to: Vector3, color: Color, radius := 0.045, parent_node: Node3D = null) -> MeshInstance3D:
	var midpoint := (from + to) * 0.5
	var length := from.distance_to(to)
	var pipe := create_visual_cylinder(radius, length, midpoint, make_material(color, 0.5, 0.25), parent_node if parent_node != null else car)
	pipe.quaternion = Quaternion(Vector3.UP, (to - from).normalized())
	return pipe


func make_particles(color: Color, amount: int, lifetime: float, pos: Vector3, radius: float) -> GPUParticles3D:
	var particles := GPUParticles3D.new()
	particles.amount = amount
	particles.lifetime = lifetime
	particles.position = pos
	particles.emitting = false
	particles.visibility_aabb = AABB(Vector3(-2, -0.5, -2), Vector3(4, 5, 4))
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.material = make_material(color, 1.0, 0.0)
	particles.draw_pass_1 = sphere
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3(0, 1, 0)
	process.spread = 24.0
	process.initial_velocity_min = 0.45
	process.initial_velocity_max = 1.2
	process.gravity = Vector3(0, 0.38, 0)
	process.scale_min = 0.55
	process.scale_max = 1.8
	particles.process_material = process
	return particles


func make_material(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metallic
	if color.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return mat


func make_car_paint(color: Color) -> StandardMaterial3D:
	var mat := make_material(color, 0.16, 0.78)
	mat.clearcoat_enabled = true
	mat.clearcoat_roughness = 0.075
	return mat


func make_rubber_material() -> StandardMaterial3D:
	var mat := make_material(Color("#080a0c"), 0.92, 0.0)
	mat.anisotropy_enabled = true
	mat.anisotropy = 0.18
	return mat


func metal_dark() -> StandardMaterial3D:
	return make_material(Color("#343b40"), 0.30, 0.88)


func make_emissive(color: Color, strength: float) -> StandardMaterial3D:
	var mat := make_material(color, 0.3, 0.15)
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = strength
	return mat


func panel_style(color: Color, radius: int, border_color: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.border_color = border_color
	style.content_margin_left = 18
	style.content_margin_top = 14
	style.content_margin_right = 18
	style.content_margin_bottom = 14
	return style


func style_button(button: Button, accent: Color) -> void:
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", panel_style(Color(accent, 0.14), 10, Color(accent, 0.7), 1))
	button.add_theme_stylebox_override("hover", panel_style(Color(accent, 0.28), 10, accent, 1))
	button.add_theme_stylebox_override("pressed", panel_style(Color(accent, 0.42), 10, Color.WHITE, 1))


func make_metric_card(parent: HBoxContainer, label_text: String, value_text: String, color: Color) -> Array:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 4)
	parent.add_child(box)
	var caption := Label.new()
	caption.text = label_text
	caption.add_theme_font_size_override("font_size", 11)
	caption.add_theme_color_override("font_color", MUTED)
	box.add_child(caption)
	var value := Label.new()
	value.text = value_text
	value.add_theme_font_size_override("font_size", 22)
	value.add_theme_color_override("font_color", color)
	box.add_child(value)
	var bar := ProgressBar.new()
	bar.custom_minimum_size.y = 6
	bar.show_percentage = false
	bar.value = 64
	bar.add_theme_stylebox_override("background", panel_style(Color("#111d2b"), 3, Color.TRANSPARENT, 0))
	bar.add_theme_stylebox_override("fill", panel_style(color, 3, color, 0))
	box.add_child(bar)
	return [value, bar]
