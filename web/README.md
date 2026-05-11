# Build web (love.js)

Portage du jeu LÖVE 2D vers WebAssembly via [love.js](https://github.com/Davidobot/love.js).

## Installation (une seule fois)

```bash
npm install -g love.js
```

Requiert Node.js >= 16. love.js est un wrapper Emscripten autour de l'image LÖVE 11.5.

## Build

```bash
./web/build.sh
```

Le script :

1. Nettoie les builds precedents (`web/dist`, `web/bullets.love`)
2. Zip le projet en `.love` (exclut `web/`, `.git/`, `node_modules/`, `love.app/`)
3. Lance `love.js` avec `-c` (compat) et 64 Mo de WASM

Sortie : `web/dist/` (~5 Mo, dont ~4.7 Mo de runtime LÖVE WASM).

A relancer apres chaque modif Lua.

## Tester en local

`web/dist/index.html` ne s'ouvre pas en `file://` (CORS sur les workers WebAssembly). Il faut un serveur :

```bash
cd web/dist
python3 -m http.server 8080
# puis http://localhost:8080
```

## Deployer

Le contenu de `web/dist/` est statique : Vercel, Netlify, GitHub Pages, n'importe quoi.

**GitHub Pages** (le plus simple si le repo est deja sur GitHub) :
1. Settings -> Pages -> Source : `GitHub Actions`
2. Creer un workflow qui build a chaque push (voir `.github/workflows/deploy.yml` si present)
3. Le site sera servi a `https://<user>.github.io/<repo>/`

**Vercel / Netlify** : drag-and-drop le dossier `web/dist/` dans leur interface, c'est en ligne en 30 s.

## Options de build

```bash
love.js web/bullets.love web/dist -t "Bullets" -m 67108864 -c
```

- `-t` : titre (apparait dans `<title>` et le H1)
- `-m N` : memoire WASM en octets (64 Mo confortable, baisse a 16-33 Mo si tu veux economiser)
- `-c` : version "compat" (compatibilite navigateurs large, pas besoin de SharedArrayBuffer/COOP/COEP). Sans `-c` : version moderne (plus rapide mais necessite des headers CORS particuliers cote serveur)

Note : les fichiers `web/dist/` et `web/bullets.love` sont ignores par git.
