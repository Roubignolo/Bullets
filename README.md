# Bullets

Editeur de patterns de bullets pour shmups, en Lua / LÖVE 2D.

Place autant d'emitters que tu veux dans la zone de jeu, edite leurs parametres en temps reel via des sliders, et teste tes patterns avec un petit vaisseau pilotable. Compteurs de hits / grazes pour mesurer la difficulte.

Portage navigateur prevu via love.js (voir [web/README.md](web/README.md)).

## Lancer en local

Requiert [LÖVE 2D 11.5](https://love2d.org/) installe.

```bash
love .
```

## Utilisation

Fenetre = zone de jeu (gauche) + panneau d'edition (droite).

### Panneau

- **PATTERNS** : un clic sur `+ Spiral`, `+ Ring`, etc. ajoute un emitter au centre de la zone.
- **EMITTERS** : liste des emitters poses. Clic pour selectionner (highlight bleu autour). Bouton `x` rouge pour supprimer un emitter, `Tout supprimer` pour vider.
- **PARAMETRES** : sliders pour l'emitter selectionne (rate, speed, count, spread, etc., variables selon le pattern). `Reinitialiser les parametres` restaure les defaults du pattern.
- **Bas** : Pause / Reset stats, et compteurs Bullets / Hits / Grazes.

### Zone de jeu

- **Drag** : clic-glisser un emitter pour le deplacer dans la zone.
- **Clic** sur un emitter : le selectionne (le panneau affiche ses parametres).
- Le **vaisseau** se deplace avec les fleches ou WASD. Shift = focus mode (vitesse / 2.5, comme dans tout shmup).
- **Hit zone** = petit cercle blanc au centre du vaisseau (rayon 4 px). En cas de contact, glow rouge + flash sur la coque + incrementation du compteur Hits.
- **Graze ring** = anneau a 14 px. Quand un bullet passe entre le hitbox et le graze ring, l'anneau s'illumine en blanc et le compteur Grazes monte.

### Raccourcis clavier

| Action | Touche |
| --- | --- |
| Move | fleches / WASD |
| Focus | Shift |
| Pause | Espace |
| Reset stats | R |
| Supprimer l'emitter selectionne | Suppr / Backspace |
| Quitter | Echap |

## Patterns inclus

- **Spiral** — bras tournants depuis l'emetteur
- **Ring** — burst circulaire periodique
- **Fan oscillant** — eventail oscillant autour d'un angle
- **Aimed** — vise le joueur en continu

## Architecture

```text
main.lua          # boucle LÖVE, simulation, input, layout
conf.lua          # config fenetre 1280x800

src/
  player.lua      # vaisseau (deplacement, hitbox, graze ring, flash hit)
  emitter.lua     # factory : un emitter = { blueprint, x, y, params, accum }
  patterns.lua    # blueprints : { name, defaultParams, paramSpecs, update }
  ui.lua         # panneau droit : add patterns, list emitters, sliders, stats
  widgets.lua    # immediate-mode : button, slider, label

web/              # build love.js (voir web/README.md)
```

## Ajouter un pattern

Dans [src/patterns.lua](src/patterns.lua), ajoute une entree au tableau `Patterns.blueprints` :

```lua
{
    name = "Mon pattern",
    defaultParams = { rate = 10, speed = 200, ... },
    paramSpecs = {
        { name = "rate",  min = 1,  max = 100, step = 1, label = "Rate" },
        ...
    },
    update = function(em, dt, time, bullets, target)
        -- emit logic, ex: spawn(bullets, em.x, em.y, angle, speed)
    end,
}
```

Les sliders du panneau s'autogenrent depuis `paramSpecs`. `target` est le vaisseau (utile pour viser).

## Roadmap (suggestions)

- **Editeur de patterns custom** : textarea + `loadstring` sandboxe pour ecrire un nouveau `update` a la volee
- **Save / load** : exporter la scene (emitters + params) en JSON via `love.filesystem`
- **Plus de patterns** : zigzag, sinusoide, homing, delay-spawn
- **Color / size par emitter** : sliders couleur HSV et taille bullet
- **Replay** : rejouer une session pour analyser un pattern
