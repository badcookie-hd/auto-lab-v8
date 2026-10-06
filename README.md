# AUTO//LAB – Interaktiver Fahrzeug-Simulator

Ein deutschsprachiger 3D-Lernsimulator für die Grundlagen eines Autos, erstellt mit Godot 4.

Die überarbeitete Grafik nutzt eigenständige, abgerundete 3D-Modelle für Karosserie und Haube mit Radausschnitten und offenem Motorraum. Dazu kommen getrennte Scheiben, schlankere Scheinwerfer, Straßenreifen mit Felgen und Bremsen, eine Lederstruktur im Innenraum sowie eine neutral ausgeleuchtete 3D-Werkstatt. Unter der weiter geöffneten Haube sitzt nun ein längs eingebauter V8; darunter führt ein modellierter Hinterrad-Antriebsstrang bis zu den Hinterrädern.

## Spielen

- `AUTO_LAB.exe` doppelt anklicken, falls du die fertige Windows-Fassung verwendest.
- Alternativ `project.godot` im Godot Project Manager öffnen und **F6/F5** drücken.

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

Der Innenraum hat eine eigene dreh- und zoombare Querschnittsansicht. Klicke auf ein sichtbares Detail oder wähle es in der Bauteilliste rechts aus; mit **F** springt die Kamera gezielt dorthin. **G** stellt die Außenansicht wieder her. Beim Wechsel in den Innenraum schließt sich die Haube nur für die Ansicht und nimmt danach ihren vorherigen Zustand wieder an.

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

Das Auto bleibt eine stilisierte 3D-Darstellung. V8-Baugruppen und Kraftfluss folgen einem realen Grundlayout, aber Maße, Zündfolge, Leitungsführung, Motorsteuerung, Fahrverhalten und Temperatur sind keine technische Berechnung eines konkreten Serienfahrzeugs. Das Spiel ersetzt keine Reparaturanleitung oder Werkstattausbildung.

Karosserie und Haube liegen als GLB-Dateien unter `assets/` und können mit Blender 5+ aus `tools/build_body.py` neu erzeugt werden. Die Lederstruktur ist eine für dieses Projekt generierte Bilddatei. Trotz der überarbeiteten Form ist das Spiel keine fotorealistische Darstellung eines konkreten Automodells.
