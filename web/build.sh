#!/usr/bin/env bash
# Build navigateur via love.js. A relancer apres chaque modif Lua.
# Usage : ./web/build.sh

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

# Verif love.js installe
if ! command -v love.js >/dev/null 2>&1; then
    echo "❌ love.js n'est pas installe. Run: npm install -g love.js" >&2
    exit 1
fi

echo "🧹 Clean ancien build..."
rm -rf web/dist web/bullets.love

echo "📦 Package du jeu en .love..."
zip -9 -qr web/bullets.love . \
    -x "web/*" ".git/*" "*.DS_Store" "love.app/*" "node_modules/*"

LOVE_SIZE=$(du -h web/bullets.love | cut -f1)
echo "   -> web/bullets.love ($LOVE_SIZE)"

echo "🌐 Conversion via love.js..."
love.js web/bullets.love web/dist \
    -t "Bullets" \
    -m 67108864 \
    -c

DIST_SIZE=$(du -sh web/dist | cut -f1)
echo ""
echo "✅ Build OK : web/dist/ ($DIST_SIZE)"
echo ""
echo "Test local (necessaire car file:// ne marche pas a cause des CORS) :"
echo "   cd web/dist && python3 -m http.server 8080"
echo "   puis ouvrir http://localhost:8080"
