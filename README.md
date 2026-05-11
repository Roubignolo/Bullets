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

### Couleur

Chaque emitter a 3 params couleur :

- **Hue** (0-360) : teinte de la bullet
- **Rainbow** (toggle ON/OFF) : si ON, la teinte cycle dans le temps -> les bullets forment un degrade arc-en-ciel continu
- **Rainbow speed** : vitesse du cycle (cycles / s)

## Architecture

```text
main.lua          # boucle LÖVE, simulation, input, layout
conf.lua          # config fenetre 1280x800

src/
  player.lua      # vaisseau (deplacement, hitbox, graze ring, flash hit)
  emitter.lua     # factory : un emitter = { blueprint, x, y, params, accum }
  patterns.lua    # blueprints + helpers HSV/rainbow + spawn() avec swing optionnel
  ui.lua          # panneau droit : add patterns, list emitters, params scrollables, stats
  widgets.lua     # immediate-mode : button, toggle, slider, label, color swatch

web/              # build love.js (voir web/README.md)
```

## Modele de bullet

Les bullets sont recalculees a chaque frame depuis leur position de spawn :

```text
b.x = b.x0 + b.vx * b.age
b.y = b.y0 + b.vy * b.age
if b.swing then
    b.x += swing.perpX * swing.amp * sin(b.age * swing.freq + swing.phase)
    b.y += swing.perpY * swing.amp * sin(b.age * swing.freq + swing.phase)
end
```

Pas de drift d'integration. Permet d'ajouter facilement d'autres modificateurs (acceleration, courbure...).

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
- **Save / load** : exporter la scene (emitters + params) en JSON via `love.filesystem`
- **Patterns supplementaires** : homing, accelerating, spawn-on-death, lasers
- **Slider saturation/brightness** (actuellement 1.0 fixe)
- **Multi-selection / copier-coller emitter**
