# AUTO//LAB – Interaktiver Fahrzeug-Simulator

Ein deutschsprachiger 3D-Lernsimulator für die Grundlagen eines Autos, erstellt mit Godot 4.

Die neue Darstellung zeigt ein detailliertes, texturiertes 2005er Mustang-GT-Modell mit beweglicher Haube, Felgen, Leuchten und Innenraum. Godots Forward+-Renderer beleuchtet es mit einer echten Werkstatt-HDRI, Umgebungsverdeckung und Reflexionen. Unter der Haube sitzt weiterhin der interaktive, längs eingebaute V8; der modellierte Hinterrad-Antriebsstrang reicht bis zur Hinterachse.

Die 3D-Karosserie stammt von Ricy und steht unter CC BY 4.0; die HDRI von Poly Haven ist CC0. Vollständige Angaben und Änderungen stehen in [assets/ATTRIBUTION.md](assets/ATTRIBUTION.md). AUTO//LAB ist weder von Ford noch von den Modellautoren unterstützt.

## Spielen

- `AUTO_LAB.exe` doppelt anklicken, falls du die fertige Windows-Fassung verwendest.
- Alternativ `project.godot` im Godot Project Manager öffnen und **F6/F5** drücken. Für die neue Grafik ist ein PC mit Vulkan-fähiger GPU empfohlen.

## Bedienung

- **Linke Maustaste ziehen:** Kamera um das Auto drehen
- **Mausrad:** hinein- und herauszoomen
- **Bauteil anklicken:** Erklärung und passende Aktion öffnen
- **Bauteilliste rechts:** auch verdeckte oder ausgebaute Teile direkt auswählen
- **F oder FOKUS:** Kamera auf das ausgewählte Bauteil richten
- **G:** Gesamtansicht wiederherstellen
- **I oder INNENRAUM ANSEHEN:** Dach und Glas für einen offenen Blick ins Cockpit ausblenden; erneut drücken für außen
- **Motor starten/stoppen:** Schaltfläche unten links
- **Motorlast:** Regler unten links
- **Haube:** öffnen oder schließen
- **V8-Schnittmodell:** in der Bauteilliste „Längs eingebauter V8“ auswählen und auf **V8-SCHNITT ÖFFNEN** klicken
- **Röntgen:** versteckte Baugruppen sichtbar machen
- **R:** gesamte Simulation zurücksetzen

## Innenraum erkunden

Der Innenraum hat eine eigene dreh- und zoombare Querschnittsansicht. Dabei werden Außenhülle und Dach für freie Sicht ausgeblendet. Klicke auf ein sichtbares Detail oder wähle es in der Bauteilliste rechts aus; mit **F** springt die Kamera gezielt dorthin. **G** stellt die Außenansicht wieder her. Beim Wechsel in den Innenraum schließt sich die Haube nur für die Ansicht und nimmt danach ihren vorherigen Zustand wieder an.

Untersuchen kannst du Kombiinstrument, Startknopf, Blinker- und Wischerhebel, Armaturenbrett, Infotainment-Bildschirm, Klimabedienung, Warnblinker, Gangwahl, Feststellbremse, Becherhalter, Pedale, Fahrersitz mit Kopfstütze, Dreipunktgurt, Türbedienung, Handschuhfach, Innenspiegel, Sonnenblende und Luftdüsen. Blinker, Warnblinker, Gebläse, Wischer und Startknopf haben kleine vorführbare Aktionen.

## V8 und echter Antriebsaufbau

Dieses Lernmodell orientiert sich am Grundlayout einer Limousine mit Frontmotor und Hinterradantrieb: Im Motorraum steht ein 90°-V8 mit zwei Bänken zu je vier Zylindern längs. Das Schnittmodell zeigt die acht Zylinder, Kolben, Pleuel und eine gemeinsame Kurbelwelle. Ansaugbrücke und Drosselklappe sitzen zwischen den Bänken; die Abgaskrümmer führen außen ab. Vorne liegen Riemen, Lichtmaschine, Wasserpumpe und Kühler.

Vom Motor aus geht die Drehung über das Getriebe im Mitteltunnel, die Kardanwelle und das Hinterachsdifferenzial zu beiden Hinterrädern. Kraftstoffleitung und Abgasweg sind ebenfalls sichtbar. Wähle ein Bauteil rechts aus und drücke **F**; für versteckte Teile wird die Karosserie durchsichtig. Mit **G** kehrst du zur Gesamtansicht zurück.

## Probefahrt

Mit **PROBEFAHRT STARTEN** links im Bild wechselst du auf eine Teststrecke. Der Motor startet dabei, sofern Batterie und Motorzustand es zulassen. Die Haube schließt sich automatisch. Mit **W/S** oder den Pfeiltasten gibst du Gas und bremst; **A/D** oder die Pfeiltasten lenken. Die Anzeige links zeigt die Geschwindigkeit. **ZUR WERKSTATT** bringt das Auto zurück, damit du wieder Bauteile ausbauen und reparieren kannst.

Die Probefahrt übernimmt den Zustand aus der Werkstatt. Ohne Kühler und Kühlmittel überhitzt der Motor auch unterwegs. Ohne Luftfilter sinkt die verfügbare Beschleunigung; bei Motorschaden rollt das Auto aus.

## Kühler-Versuch

1. Klicke vorne im Motorraum auf den Kühler. Beim Start ist er bereits ausgewählt.
2. Klicke rechts auf **KÜHLER AUSBAUEN**.
3. Starte unten links den Motor.
4. Stelle die Motorlast hoch.
5. Beobachte Kühlmittelverlust am Boden, Temperaturverlauf, Dampf und Motorzustand.
6. Stoppe den Motor und baue den Kühler wieder ein.
7. Lass den Motor abkühlen, wähle den Kühlmittelbehälter und fülle Kühlmittel auf.

## Enthaltene interaktive Systeme

- Kühler, sichtbarer Kühlmittelverlust und Nachfüllen bei abgekühltem Motor
- Motor, Motorlast, Drehzahl und Motortemperatur
- 90°-V8 mit acht dargestellten Zylindern, Ansaug- und Abgasseite, Nebenaggregaten und Schnittansicht
- Getriebe, Kardanwelle, Differenzial und Antriebswellen als durchgehender Hinterrad-Antriebsstrang
- Motoröl und Öldruck
- 12-Volt-Batterie mit Startsperre
- Luftfilter mit Leistungseinfluss
- Räder, Reifen und Bremsen
- Kraftstofftank und Abgasanlage
- Karosserie, Sicherheitszelle, Lenkung und Beleuchtung
- Temperaturdiagramm sowie sichtbare Überhitzung mit Dampf, Warnung und Motorschaden
- frei steuerbare Probefahrt mit Zustandsfolgen für Antrieb, Kühlung und Luftfilter
- offener, anklickbarer Innenraum mit 19 erklärten Bedienelementen und Sicherheitsdetails

## Technischer Hinweis

Die sichtbare Außenhülle und Kabine sind nun ein detailliertes 3D-Modell. Die interaktiven Motor- und Unterbodenbaugruppen bleiben jedoch ein vereinfachtes Lernmodell, kein maßstabsgetreuer Nachbau des Mustang-Antriebs. Maße, Zündfolge, Leitungsführung, Motorsteuerung, Fahrverhalten und Temperatur sind keine technische Berechnung eines konkreten Serienfahrzeugs. Das Spiel ersetzt keine Reparaturanleitung oder Werkstattausbildung.

Die alten, selbst erzeugten Limousinenmodelle bleiben als Fallback erhalten und können mit Blender 5+ aus `tools/build_body.py` neu gebaut werden. `tools/prepare_mustang.py` trennt das lizenzierte Ausgangsmodell in Karosserie, Haube, Räder und Innenraum. Die Lederstruktur des Fallbacks ist eine für dieses Projekt generierte Bilddatei. Für optische Qualität und Details ist der neue Aufbau deutlich besser, aber „hyperrealistisch“ im Sinn einer Filmproduktion ist insbesondere die interaktive Technik noch nicht.
