# Bullets

Editeur de patterns de bullets pour shmups, en Lua / LÖVE 2D.

Permet de creer de nouveaux patterns et de les tester en temps reel avec un petit vaisseau deplaçable, jouable directement en ligne via love.js.

## Lancer en local

Requiert [LÖVE 2D 11.5](https://love2d.org/) installe.

```bash
love .
```

## Build web

Voir [web/README.md](web/README.md) pour le portage navigateur via love.js.

## Controles

| Action | Touches |
|---|---|
| Deplacement | fleches ou WASD |
| Focus / precision | Shift |
| Changer de pattern | `1` `2` `3` `4` |
| Reset simulation | `R` |
| Pause | Espace |
| Quitter | Echap |
| Tweak parametres | `Q`/`E` (rate)  `Z`/`C` (speed)  `[`/`]` (count)  `,`/`.` (spread/rot) |

## Patterns inclus (v1)

- **Spiral** — bras tournants depuis l'emetteur
- **Ring** — burst circulaire periodique
- **Fan oscillant** — eventail oscillant vers le bas
- **Aimed** — vise le joueur en continu, avec dispersion

Chaque pattern expose `params` editables a chaud avec les touches.

## Architecture

```
main.lua          # boucle LÖVE, simulation, input
conf.lua          # config fenetre
src/player.lua    # vaisseau (deplacement, hitbox, draw)
src/patterns.lua  # 4 patterns + helpers spawn/clamp
src/ui.lua       # HUD : pattern courant, params, controles
web/              # build love.js
```

## Ajouter un pattern

Dans [src/patterns.lua](src/patterns.lua), suivre le template d'un pattern existant : table avec `name`, `params`, `accum`, fonctions `reset`, `update(dt, time, emitter, bullets)`, `keypressed(key)`, `describe()`. Puis l'ajouter au tableau retourne par `Patterns.list()`.
