# Drittanbieter-Modell

Die sichtbare Karosserie, Haube und Räder basieren auf dem **2005 Ford Mustang GT** von **Ricy** (`ngon_3d`):

- Original: https://sketchfab.com/3d-models/2005-ford-mustang-gt-26b6b60cf2804370ac3c64424242dc1f
- Lizenz: Creative Commons Attribution 4.0 International, https://creativecommons.org/licenses/by/4.0/
- Ausgangs-GLB bezogen aus https://github.com/nesdesignco/FormDrive/blob/main/public/models/mustang-2005.glb

Änderungen für AUTO//LAB: Maßstab und Koordinaten angepasst, Karosserie/Haube/Räder/Innenraum in getrennte GLB-Dateien exportiert, originale Kühler-Meshes zugunsten der interaktiven Lernbaugruppen entfernt. Das visuelle Modell und diese Änderungen werden nicht als von Ford oder Ricy unterstützt dargestellt.

Die ursprüngliche Binärdatei liegt unter `source_assets/mustang-2005.glb` und wird von Godot nicht importiert. Die Konvertierung erfolgt mit `tools/prepare_mustang.py` und Blender 5+.

Die Werkstatt-HDRI `autoshop_01_2k.hdr` stammt von **Oliksiy Yakovlyev / Poly Haven**, https://polyhaven.com/a/autoshop_01, und ist **CC0** (https://polyhaven.com/license). Sie wird für Umgebungslicht und Reflexionen verwendet.
