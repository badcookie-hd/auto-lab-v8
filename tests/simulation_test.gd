extends SceneTree


func _initialize() -> void:
	call_deferred("run_tests")


func run_tests() -> void:
	var scene: PackedScene = load("res://main.tscn")
	var lab = scene.instantiate()
	root.add_child(lab)
	await process_frame

	# Baseline: the scene exposes all important learning components.
	for id in ["radiator", "engine", "battery", "air_filter", "oil", "coolant", "wheel_fl", "fuel_tank", "exhaust", "body", "steering", "headlight"]:
		assert_true(lab.parts.has(id), "Bauteil fehlt: " + id)
	for id in ["v8_bank_left", "v8_bank_right", "intake_manifold", "exhaust_manifold", "alternator", "water_pump", "transmission", "driveshaft", "differential"]:
		assert_true(lab.parts.has(id) and lab.component_data.has(id), "V8-Antriebsbauteil fehlt: " + id)
	assert_true(lab.parts["v8_bank_left"].position.z > 0.0 and lab.parts["v8_bank_right"].position.z < 0.0, "V8-Zylinderbänke liegen nicht auf beiden Seiten")
	assert_true(absf(lab.parts["v8_bank_left"].rotation.x - lab.parts["v8_bank_right"].rotation.x - PI * 0.5) < 0.01, "V8-Zylinderbänke bilden keinen 90-Grad-Winkel")
	assert_true(lab.v8_internals.size() >= 25, "Acht Zylinder, Pleuel und Kurbelwelle fehlen im Schnittmodell")
	assert_true(lab.parts["engine"].position.x < lab.parts["transmission"].position.x and lab.parts["transmission"].position.x < lab.parts["driveshaft"].position.x and lab.parts["driveshaft"].position.x < lab.parts["differential"].position.x, "Längs angeordneter Hinterradantrieb ist falsch aufgebaut")
	assert_true(absf(lab.parts["fuel_tank"].position.z) > 0.30, "Kraftstofftank blockiert die Kardanwelle")
	lab.toggle_v8_cutaway()
	assert_true(lab.v8_cutaway and lab.v8_internals[0].visible and not lab.v8_covers[1].visible, "V8-Schnittmodell zeigt Innenteile nicht")
	lab.toggle_v8_cutaway()
	assert_true(not lab.v8_cutaway and lab.v8_covers[1].visible, "V8-Schnittmodell schließt nicht")
	lab.select_part("driveshaft")
	lab.focus_selected()
	assert_true(lab.xray_enabled and not lab.xray_trim[0].visible and absf(lab.orbit_yaw) < 0.01, "Antriebsstrang wird in der Röntgenansicht nicht freigelegt")
	lab.toggle_xray()
	assert_true(lab.xray_trim[0].visible, "Karosserie nach Röntgenansicht nicht wiederhergestellt")
	assert_true(lab.parts["body"].find_children("*", "MeshInstance3D", true, false).size() >= 2, "Das neue Karosseriemodell wurde nicht geladen")
	assert_true(lab.parts["hood"].find_children("*", "MeshInstance3D", true, false).size() >= 2, "Das neue Haubenmodell wurde nicht geladen")
	assert_true(lab.component_selector.item_count == lab.PART_ORDER.size(), "Bauteilauswahl ist unvollständig")
	lab.select_part("oil")
	assert_true(lab.action_button.text == "ÖL ABLASSEN", "Bauteilaktion passt nicht zur Auswahl")
	lab.focus_selected()
	assert_true(lab.orbit_focus.distance_to(lab.parts["oil"].global_position + Vector3(0, 0.12, 0)) < 0.01, "Kamerafokus findet das Bauteil nicht")
	lab.reset_view()

	# The cabin is navigable and every small feature is actually selectable.
	for id in ["instrument_cluster", "ignition", "turn_signal", "wiper_stalk", "dashboard", "center_screen", "climate", "hazard", "gear_selector", "parking_brake", "cupholder", "pedals", "front_seat", "seat_belt", "door_controls", "glovebox", "rearview_mirror", "sun_visor", "air_vent"]:
		assert_true(lab.parts.has(id) and lab.component_data.has(id), "Innenraum-Detail fehlt: " + id)
	lab.toggle_interior_mode()
	assert_true(lab.interior_mode and not lab.roof_mesh.visible and not lab.cabin_glass.visible, "Offene Innenansicht öffnet sich nicht")
	assert_true(not lab.hood_open, "Haube wird für den Innenraumblick nicht geschlossen")
	lab.select_part("center_screen")
	lab.focus_selected()
	assert_true(lab.interior_mode and lab.interior_focus.distance_to(lab.parts["center_screen"].position) < 0.01, "Innenraum-Fokus funktioniert nicht")
	await physics_frame
	var screen_point: Vector2 = lab.camera.unproject_position(lab.parts["center_screen"].global_position)
	var picked = lab.raycast_part(screen_point)
	assert_true(picked != null and str(picked.get_meta("part_id")) == "center_screen", "Bildschirm ist nicht per Mausklick erreichbar")
	lab.select_part("climate")
	lab._on_action_pressed()
	assert_true(lab.climate_on, "Gebläse lässt sich nicht einschalten")
	lab.select_part("hazard")
	lab._on_action_pressed()
	assert_true(lab.hazard_on, "Warnblinker lässt sich nicht einschalten")
	lab.reset_view()
	assert_true(not lab.interior_mode and lab.roof_mesh.visible and lab.cabin_glass.visible, "Gesamtansicht kehrt nicht nach außen zurück")
	assert_true(lab.hood_open, "Vorher geöffnete Haube wird nicht wiederhergestellt")
	lab.toggle_hood()
	await create_timer(0.85).timeout
	assert_true(not lab.hood_open and absf(lab.hood_pivot.rotation.z) < 0.01, "Haube schließt nicht vollständig")
	assert_true(lab.parts["hood"].global_position.y - 0.07 > lab.parts["oil"].global_position.y + 0.045, "Geschlossene Haube schneidet durch Motorbauteile")
	lab.toggle_hood()
	lab.toggle_hood()
	lab.toggle_hood()
	await create_timer(0.85).timeout
	assert_true(lab.hood_open and absf(lab.hood_pivot.rotation.z - deg_to_rad(-58.0)) < 0.01, "Schnelles Umschalten lässt die Haube im falschen Zustand")

	# The requested experiment: without a radiator, temperature must reach danger level.
	lab.toggle_radiator()
	await create_timer(0.9).timeout
	assert_true(lab.radiator_area.global_position.y > 0.05 and lab.radiator_area.global_position.y < 0.5, "Ausgebauter Kühler liegt nicht auf dem Werkstattboden")
	assert_true(lab.coolant_level <= 0.45 and lab.coolant_puddle.visible, "Ausbau zeigt keinen Kühlmittelverlust")
	lab.refill_coolant()
	assert_true(lab.coolant_level <= 0.45, "Kühlmittel lässt sich ohne Kühler auffüllen")
	lab.load_value = 1.0
	lab.toggle_engine()
	for i in 65:
		lab.update_simulation(0.1)
	assert_true(not lab.radiator_installed, "Kühler wurde nicht ausgebaut")
	assert_true(lab.engine_temp > 118.0, "Motor überhitzt ohne Kühler nicht")
	assert_true(lab.steam.emitting, "Dampfeffekt fehlt bei Überhitzung")
	assert_true(lab.engine_health < 100.0, "Überhitzung beschädigt den Motor nicht")

	# Reinstalling the radiator is not enough: coolant must be refilled safely.
	lab.toggle_radiator()
	lab.engine_on = false
	lab.refill_coolant()
	assert_true(lab.coolant_level < 1.0, "Heißes Kühlsystem lässt sich fälschlich öffnen")
	lab.engine_temp = 60.0
	lab.refill_coolant()
	assert_true(lab.coolant_level == 1.0, "Kühlmittel lässt sich nach Abkühlung nicht auffüllen")
	lab.engine_temp = 115.0
	lab.toggle_engine()
	for i in 80:
		lab.update_simulation(0.1)
	assert_true(lab.radiator_installed, "Kühler lässt sich nicht wieder einbauen")
	assert_true(lab.engine_temp < 115.0, "Temperatur sinkt mit Kühler und Kühlmittel nicht")

	# Electrical interlock: removed battery prevents the engine from starting.
	lab.engine_on = false
	lab.toggle_removable("battery")
	lab.toggle_engine()
	assert_true(not lab.engine_on, "Motor startet fälschlich ohne Batterie")

	# The free drive uses the same engine state and returns to the workshop.
	lab.reset_simulation()
	lab.toggle_drive_mode()
	assert_true(lab.drive_mode and lab.engine_on and lab.drive_world.visible, "Probefahrt startet nicht")
	assert_true(not lab.hood_open and lab.action_button.disabled, "Werkstattaktionen bleiben während der Fahrt aktiv")
	lab.apply_drive(2.0, 1.0, 0.0)
	assert_true(lab.speed_kmh > 0.0 and lab.car.position.x < 0.0, "Auto beschleunigt nicht vorwärts")
	lab.apply_drive(1.0, 0.0, 1.0)
	assert_true(lab.drive_heading > 0.0, "Lenkung beeinflusst Fahrtrichtung nicht")
	lab.engine_on = false
	var speed_before_coast: float = lab.speed_kmh
	lab.apply_drive(1.0, 0.0, 0.0)
	assert_true(lab.speed_kmh < speed_before_coast, "Auto rollt bei Motorstopp nicht aus")
	lab.toggle_drive_mode()
	assert_true(not lab.drive_mode and not lab.drive_world.visible and not lab.action_button.disabled, "Rückkehr zur Werkstatt schlägt fehl")
	lab.toggle_xray(true)
	lab.toggle_v8_cutaway(true)
	lab.reset_simulation()
	assert_true(not lab.xray_enabled and not lab.v8_cutaway and lab.xray_trim[0].visible and lab.v8_covers[1].visible, "Zurücksetzen stellt Karosserie und Motorabdeckung nicht wieder her")

	print("AUTO_LAB_TEST: PASS – V8-Aufbau, Innenraum, Kühlung, Batteriesperre und Probefahrt funktionieren.")
	quit(0)


func assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("AUTO_LAB_TEST: FAIL – " + message)
	quit(1)
