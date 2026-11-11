#!/bin/sh
# Régénère src/game (et quelques fichiers de src/mtlib) depuis les sources MotionTypes de Hammerfest.
# Usage : tools/mt2hx/regen.sh <WebGamesArchives/Hammerfest/class/hammer> <mtypes/lib>
#   (sources : github.com/motion-twin/WebGamesArchives et github.com/motion-twin/mtypes)
# src/game/Boot.hx est écrit à la main et conservé. Les corrections manuelles vont dans patches.py.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
TMP=$(mktemp -d)
python3 "$HERE/mt2hx.py" "$TMP/game" "$1"
python3 "$HERE/mt2hx.py" "$TMP/lib" "$2"
cp "$ROOT/src/game/Boot.hx" "$TMP/Boot.hx"
rm -rf "$ROOT/src/game"
mkdir -p "$ROOT/src/game"
cp -r "$TMP/game/." "$ROOT/src/game/"
cp "$TMP/Boot.hx" "$ROOT/src/game/Boot.hx"
for f in DepthManager PersistCodec BitCodec Tools Md5; do
  sed 's/^package;$/package mtlib;/' "$TMP/lib/$f.hx" > "$ROOT/src/mtlib/$f.hx"
done
# outils d'édition non portés
cd "$ROOT/src/game"
rm -f Loader.hx mode/Editor.hx mode/ScriptEditor.hx mode/ItemBrowser.hx mode/QuestBrowser.hx mode/Browser.hx mode/Converter.hx
rm -rf "$TMP"
python3 "$HERE/patches.py"
