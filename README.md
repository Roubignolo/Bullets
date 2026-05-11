# Bullets

Editeur de patterns de bullets pour shmups, en Lua / LÖVE 2D.

Place autant d'emitters que tu veux dans la zone de jeu, edite leurs parametres en temps reel via des sliders (rate, speed, count, spread, **couleur HSV**, **rainbow**, etc.), et teste tes patterns avec un petit vaisseau pilotable. Compteurs de hits / grazes pour mesurer la difficulte.

Portage navigateur prevu via love.js (voir [web/README.md](web/README.md)).

## Lancer en local

Requiert [LÖVE 2D 11.5](https://love2d.org/) installe.

```bash
love .
```

## Utilisation

Fenetre = zone de jeu (gauche) + panneau d'edition (droite).

### Panneau

- **PATTERNS** : clic sur `+ Spiral`, `+ Wave`, etc. ajoute un emitter au centre haut.
- **EMITTERS** : liste des emitters poses (cap 4 visibles, le reste est selectionnable en cliquant directement dans la zone). Bouton `x` rouge pour supprimer un emitter, `Tout supprimer` pour vider.
- **PARAMETRES** : sliders pour l'emitter selectionne. **Scrollable a la molette** quand il y a beaucoup de params (cas Wave, Fan, etc.). Petit swatch couleur en haut a droite du nom du pattern. Sliders couleur en bas (hue + rainbow toggle + rainbow speed). `Reinitialiser` restaure les defaults.
- **Bas** : Pause / Reset stats, et compteurs Bullets / Hits / Grazes.

### Zone de jeu

- **Drag** : clic-glisser un emitter pour le deplacer.
- **Clic** sur un emitter : le selectionne (le panneau affiche ses parametres).
- Le **vaisseau** se deplace avec les fleches ou WASD. Shift = focus mode (vitesse / 2.5, comme dans tout shmup).
- **Hit zone** = petit cercle blanc au centre du vaisseau (rayon 4 px). En cas de contact, glow rouge + flash.
- **Graze ring** = anneau a 14 px. Quand un bullet passe entre le hitbox et le graze ring, l'anneau s'illumine et le compteur Grazes monte.

### Raccourcis clavier

Layout par defaut : **AZERTY** (ZQSD). Toggle dans le panneau (en bas, au-dessus des stats) pour passer en **QWERTY** (WASD). Le choix est sauvegarde et persistera au prochain lancement.

Les fleches marchent dans les deux layouts.

| Action | AZERTY | QWERTY |
| --- | --- | --- |
| Move | fleches / ZQSD | fleches / WASD |
| Focus | Shift | Shift |
| Pause | Espace | Espace |
| Reset stats | R | R |
| Supprimer l'emitter selectionne | Suppr / Backspace | Suppr / Backspace |
| Quitter | Echap | Echap |
| Scroll panneau parametres | Molette | Molette |

## Patterns inclus

| Pattern | Inspiration | Specifique |
| --- | --- | --- |
| **Spiral** | classique | bras tournants depuis l'emetteur |
| **Ring** | classique | burst circulaire periodique |
| **Fan oscillant** | classique | eventail oscillant autour d'un angle |
| **Aimed** | classique | vise le joueur en continu |
| **Wave** | Cave / DonPachi | bullets avec ondulation sinusoidale perpendiculaire |
| **Twin Spiral** | Touhou | deux spirales contra-rotatives superposees |
| **Shotgun** | Cave | bursts a dispersion aleatoire (visee joueur optionnelle) |
| **Petal** | Touhou | petales tournants emettant un mini-fan chacun |
| **Curve** | Touhou | bullets qui courbent leur trajectoire en arc continu |
| **Accel** | Cave / DonPachi | bullets accelerees (vitesse initiale faible, accel forte) |
| **Homing** | Touhou Marisa | bullets qui steerent doucement vers le joueur |

### Couleur

Chaque emitter a 5 params couleur :

- **Hue** (0-360) : teinte de la bullet
- **Saturation** (0-1) : 0 = blanc, 1 = couleur pure
- **Brightness** (0-1) : 0 = noir, 1 = couleur pleine
- **Rainbow** (toggle ON/OFF) : si ON, la teinte cycle dans le temps -> les bullets forment un degrade arc-en-ciel continu
- **Rainbow speed** : vitesse du cycle (cycles / s)

Le swatch de couleur a droite du nom du pattern montre la teinte resultante en temps reel.

### Scenes (save / load)

Section **SCENES** en bas du panneau avec **3 slots** :

- `Save 1/2/3` : ecrase le slot avec la scene actuelle (emitters + leurs positions + leurs params)
- `Load 1/2/3` : restaure le slot (le bouton est grise tant qu'aucune scene n'a ete sauvegardee dans ce slot)

Stockage : `<save-dir>/scene-N.lua` via `love.filesystem`. Sur web (love.js), persiste en IndexedDB du navigateur, donc survit aux refresh / fermeture d'onglet.

## Architecture

```text
main.lua          # boucle LÖVE, simulation, input, layout, integration bullets
conf.lua          # config fenetre 1280x800

src/
  player.lua      # vaisseau (deplacement, hitbox, graze ring, flash hit, AZERTY/QWERTY)
  emitter.lua     # factory : un emitter = { blueprint, x, y, params, accum }
  patterns.lua    # 11 blueprints + helpers HSV/rainbow + spawn() (swing/curve/accel/homing)
  scenes.lua      # save / load via love.filesystem (Lua serialise dans 3 slots)
  ui.lua          # panneau droit : add patterns, list emitters, params scrollables, scenes, stats
  widgets.lua     # immediate-mode : button (+disabled), toggle, slider, label, color swatch

web/              # build love.js (voir web/README.md)
```

## Modele de bullet

4 modes de mouvement, choisis selon les `opts` passees a `spawn()` :

- **defaut** : position recalculee depuis le spawn (`x0 + vx * age`), pas de drift
- **swing** : ondulation sinusoidale perpendiculaire (Wave)
- **accel** : acceleration tangentielle, formule analytique `x0 + dirX * (v*t + 0.5*a*t²)` (Accel)
- **curve** : rotation continue de l'angle a chaque frame -> bullet en arc (Curve)
- **homing** : steering vers le joueur, rotation clampee par `homingRate * dt` (Homing)

Curve et Homing utilisent l'integration incrementale (necessaire pour les changements de direction continus). Default/swing/accel restent en formule analytique pour zero drift.

## Ajouter un pattern

Dans [src/patterns.lua](src/patterns.lua), ajoute une entree au tableau `Patterns.blueprints` :

```lua
{
    name = "Mon pattern",
    defaultParams = withColorDefaults({ rate = 10, speed = 200 }, 60),
    paramSpecs = withColorSpecs({
        { name = "rate",  min = 1, max = 100, step = 1, label = "Rate" },
        { name = "speed", min = 20, max = 800, step = 5, label = "Speed" },
        -- pour un toggle ON/OFF : ajouter `kind = "toggle"`
    }),
    update = function(em, dt, time, bullets, target)
        -- ex: spawn(em, bullets, em.x, em.y, angle, speed, time, { swingAmp = 50, swingFreq = 4 })
    end,
}
```

`withColorDefaults` et `withColorSpecs` ajoutent automatiquement les params `hue`, `rainbow`, `rainbowSpeed` (et leurs sliders/toggle dans le panneau). `target` est le vaisseau (utile pour viser ou homing).

## Roadmap

- **Editeur Lua live** : textarea + `loadstring` sandboxe pour ecrire un nouveau `update` a la volee
- **Patterns supplementaires** : spawn-on-death (bullet qui explose en gerbe), lasers, delay-then-accelerate
- **Multi-selection / copier-coller emitter** + duplicate selected
- **Plus de slots de save** + nommage des scenes (sauvegarde nominative au lieu de slots numerotes)
- **Bullet shapes** : carre, fleche, etoile (actuellement tous des cercles)
- **Mode replay** : enregistrer / rejouer une session pour analyser un pattern
