# Fenêtres dockables ReaScript (ReaImGui)

Guide pour créer un panneau ancrable dans l’interface REAPER, distribué via ReaPack. Référence d’implémentation : dossier `check-hardware/`.

---

## Prérequis

### ReaImGui (extension, pas un script)

Les fenêtres dockables passent par **[ReaImGui](https://github.com/cfillion/reaimgui)** (cfillion), une extension REAPER — pas par l’API `gfx` native.

Installation :

1. Ouvrir **Extensions > ReaPack > Browse packages**
2. Activer le dépôt **ReaTeam Extensions** si ce n’est pas déjà fait
3. Installer **ReaImGui**

ReaImGui n’est **pas** listé dans `index.xml` du dépôt : c’est une dépendance externe, comme le script cfillion « Apply render preset » pour Band Record.

### Limite des ReaScripts

| Approche | Dockable dans REAPER ? |
|----------|------------------------|
| `gfx.init()` | Non — fenêtre flottante seulement |
| **ReaImGui** | Oui — dockers natifs REAPER ou flottant |
| Extension C++ | Oui — intégration native complète (hors scope ReaPack script) |

---

## Architecture d’un paquet dockable

Exemple `check-hardware/` :

```
check-hardware/
├── check-hardware.lua    # Point d’entrée (action toggle)
├── config.lua            # Chemins et réglages fenêtre
├── core/
│   └── reaimgui.lua      # Vérification ReaImGui + shim API
└── ui/
    └── window.lua        # Boucle ImGui (Begin / contenu / End)
```

### Type de script : toggle + defer

Une fenêtre dockable est un script **persistant** :

- **`reaper.defer(loop)`** — redessine l’UI à chaque frame tant que la fenêtre est ouverte
- **Toggle action** — `SetToggleCommandState` pour que le bouton toolbar reste enfoncé tant que le panneau tourne
- **`reaper.atexit(cleanup)`** — remet le toggle à OFF si REAPER se ferme ou le script s’arrête

Ce n’est **pas** une action one-shot.

---

## Étapes de création

### 1. Vérifier ReaImGui au démarrage

`core/reaimgui.lua` teste `reaper.ImGui_CreateContext` et charge le shim **intégré** à ReaImGui (si disponible) :

```lua
if reaper.ImGui_GetBuiltinPath then
	package.path = reaper.ImGui_GetBuiltinPath() .. "/?.lua;" .. package.path
	local ImGui = require("imgui") "0.9"
end
```

Ne pas charger l’ancien shim `Scripts/ReaTeam Extensions/API/imgui.lua` : il peut entrer en conflit avec les noms d’API récents.

### 2. Créer le contexte avec le docking activé

```lua
local ctx = reaper.ImGui_CreateContext("Check Hardware", reaper.ImGui_ConfigFlags_DockingEnable())
```

> **Attention** : le flag s’appelle `ConfigFlags_DockingEnable`, pas `ConfigFlags_DockEnable` (qui n’existe pas et provoque une erreur).

Sans ce flag, la fenêtre ne pourra pas s’ancrer.

### 3. Positionner la fenêtre dans un docker (première ouverture)

```lua
reaper.ImGui_SetNextWindowDockID(ctx, -1, reaper.ImGui_Cond_FirstUseEver())
```

| `dock_id` | Signification |
|-----------|---------------|
| `0` | Flottante |
| `-1` à `-16` | Index d’un docker natif REAPER |
| `> 0` | Dockspace ImGui (après drag utilisateur) |

`Cond_FirstUseEver` : n’applique la position qu’à la première ouverture ; REAPER mémorise ensuite la position choisie par l’utilisateur.

L’utilisateur peut glisser l’onglet de la fenêtre pour la dock/undock (comme le mixer).

### 4. Boucle de rendu

```lua
local function run()
	local visible, open = reaper.ImGui_Begin(ctx, "Check Hardware", true, reaper.ImGui_WindowFlags_NoCollapse())
	if visible then
		reaper.ImGui_Text(ctx, "Hardware check")
		reaper.ImGui_End(ctx)
	end

	if open and not reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_Escape()) then
		reaper.defer(run)
	else
		exit() -- remet le toggle OFF
	end
end
```

- `ImGui_Begin` retourne `visible` (fenêtre non minimisée) et `open` (utilisateur n’a pas cliqué ×)
- `ImGui_End` est obligatoire après chaque `Begin` réussi (`visible == true`)
- Échap ferme le panneau (convention ReaTeam)

### 5. Pattern toggle (toolbar / raccourci)

```lua
local function set_button_state(set)
	local _, _, sec, cmd = reaper.get_action_context()
	reaper.SetToggleCommandState(sec, cmd, set or 0)
	reaper.RefreshToolbar2(sec, cmd)
end

function init()
	set_button_state(1)
	reaper.atexit(function() set_button_state(0) end)
	reaper.defer(run)
end
```

Assigner l’action à une **toolbar** ou un raccourci en mode toggle pour un comportement type panneau natif.

---

## Publication ReaPack

### Entrée dans `index.xml`

Catégorie **Various** (ou nouvelle catégorie si besoin). Lister **tous** les fichiers chargés via `dofile` :

```xml
<reapack name="Check Hardware" type="script" desc="Dockable panel to check audio/MIDI hardware.">
	<version name="1.0.1" author="Emmanuel Béziat" time="2026-06-10T12:00:00Z">
		<source main="Check Hardware" file="check-hardware/check-hardware.lua">https://raw.githubusercontent.com/EmmanuelBeziat/reaper-scripts/main/check-hardware/check-hardware.lua</source>
		<source file="check-hardware/config.lua">https://raw.githubusercontent.com/EmmanuelBeziat/reaper-scripts/main/check-hardware/config.lua</source>
		<source file="check-hardware/core/reaimgui.lua">https://raw.githubusercontent.com/EmmanuelBeziat/reaper-scripts/main/check-hardware/core/reaimgui.lua</source>
		<source file="check-hardware/ui/window.lua">https://raw.githubusercontent.com/EmmanuelBeziat/reaper-scripts/main/check-hardware/ui/window.lua</source>
		<changelog><![CDATA[Fix ReaImGui docking flag (ConfigFlags_DockingEnable).]]></changelog>
	</version>
</reapack>
```

- Point d’entrée : `main="Check Hardware"` (nom de l’action dans REAPER)
- Modules : `<source file="...">` sans attribut `main`

### Test local

#### Enregistrer l’action dans REAPER

« ReaScript: Load » exécute le script une fois **sans** l’ajouter à la liste d’actions. Pour disposer d’une action permanente :

1. **Via ReaPack** (recommandé) : ajouter le dépôt comme source ReaPack, synchroniser, installer le paquet *Check Hardware*
2. **Copie manuelle** : placer `check-hardware/` dans `{ResourcePath}/Scripts/` (ex. `Scripts/reaper-scripts/check-hardware/`), puis **redémarrer REAPER** ou rescanner les scripts

Ensuite : **Actions > Show action list** → chercher « Check Hardware ».

#### Vérifier le panneau

1. Lancer l’action — la fenêtre s’ouvre
2. Glisser l’onglet vers un docker (mixer, etc.) pour vérifier le docking

#### Dépannage

| Problème | Cause probable | Solution |
|----------|----------------|----------|
| Action absente de la liste | Script chargé via « Load » uniquement | Installer via ReaPack ou copier dans `Scripts/` + redémarrage |
| `ConfigFlags_DockEnable` nil | Mauvais nom de constante | Utiliser `ConfigFlags_DockingEnable` |
| Erreur dans `imgui.lua` | Ancien shim ReaTeam incompatible | Utiliser `ImGui_GetBuiltinPath()` + `require('imgui')` |

---

## Évolutions possibles

- Contenu UI dans `ui/` (listes devices, meters, boutons)
- Logique métier dans `core/` (énumération drivers, MIDI, etc.)
- `config.lua` pour titres, tailles, docker par défaut
- Migrer Helix MIDI de `gfx` vers ReaImGui si un docking est souhaité

---

## Ressources

- [ReaImGui (GitHub)](https://github.com/cfillion/reaimgui)
- [Template ReaTeam — Basic ReaImGui](https://github.com/ReaTeam/ReaScripts-Templates/blob/master/ReaImGui/X-Raym_Basic%20ReaImGui.lua)
- [Documentation ReaImGui](https://cfillion.github.io/reaimgui/)
