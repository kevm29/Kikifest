@echo off
rem Double-cliquez sur ce fichier pour heberger une partie de Kikifest.
chcp 65001 >nul
cd /d "%~dp0"
where node >nul 2>nul
if errorlevel 1 (
  echo Node.js n'est pas installe.
  echo Installez la version "LTS" depuis https://nodejs.org puis relancez ce fichier.
  start https://nodejs.org
  pause
  exit /b 1
)
node server\serve.mjs %*
pause
