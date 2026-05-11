# Build web (love.js)

Portage du jeu LÖVE 2D vers WebAssembly via [love.js](https://github.com/Davidobot/love.js).

## Installation (une seule fois)

```bash
npm install -g love.js
```

Requiert Node.js >= 16. love.js est un wrapper Emscripten autour de l'image LÖVE 11.5.

## Build

Depuis la racine du projet :

```bash
# packager le jeu en .love
zip -9 -r web/bullets.love . -x "web/*" "*.git*" "*.DS_Store"

# convertir en page web (compatible mobile, sortie dans web/dist/)
love.js web/bullets.love web/dist --title "Bullets" --memory 67108864 -c
```

Options utiles :
- `-c` : version "compat" (large compatibilite navigateurs, plus lente). Sans `-c` : version moderne, plus rapide mais Chrome/Firefox recents seulement.
- `--memory N` : memoire WASM en octets (defaut 16 Mo, ici 64 Mo confortable).

## Tester en local

`web/dist/index.html` ne s'ouvre pas en `file://` (CORS sur les workers). Il faut un serveur :

```bash
cd web/dist
python3 -m http.server 8080
# puis http://localhost:8080
```

## Deployer

Le contenu de `web/dist/` est statique : Vercel, Netlify, GitHub Pages, n'importe quoi.

Note : les fichiers `web/dist/` et `web/bullets.love` sont ignores par git (`.gitignore` global du projet couvre `dist/`).
