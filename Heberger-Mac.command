#!/bin/sh
# Double-cliquez sur ce fichier pour héberger une partie de Kikifest.
cd "$(dirname "$0")" || exit 1
if ! command -v node >/dev/null 2>&1; then
  echo "Node.js n'est pas installé."
  echo "Installez la version « LTS » depuis https://nodejs.org puis relancez ce fichier."
  open https://nodejs.org
  read -r _
  exit 1
fi
exec node server/serve.mjs "$@"
