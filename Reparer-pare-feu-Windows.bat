@echo off
rem Double-cliquez sur ce fichier pour autoriser Kikifest dans le pare-feu Windows
rem (a faire une fois, si l'autre joueur n'arrive pas a joindre votre ordinateur).
rem Il supprime les regles qui BLOQUENT Node.js (creees quand on clique "Annuler" a la
rem question du pare-feu) et autorise les ports 8080 et 8081 en entree.
chcp 65001 >nul
net session >nul 2>&1
if errorlevel 1 (
  echo Demande des droits administrateur : repondez "Oui" a la fenetre de Windows.
  powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)
cd /d "%~dp0"
echo.
echo === Kikifest : reparation du pare-feu Windows ===
echo.
set NODE=
for /f "delims=" %%i in ('where node 2^>nul') do if not defined NODE set "NODE=%%i"
echo 1. Suppression des anciennes regles de Node.js (dont celles qui bloquent)...
netsh advfirewall firewall delete rule name="Node.js JavaScript Runtime" >nul 2>nul
netsh advfirewall firewall delete rule name="Node.js: Server-side JavaScript" >nul 2>nul
if defined NODE netsh advfirewall firewall delete rule name=all dir=in program="%NODE%" >nul 2>nul
netsh advfirewall firewall delete rule name="Kikifest (Node.js)" >nul 2>nul
netsh advfirewall firewall delete rule name="Kikifest (port 8080)" >nul 2>nul
netsh advfirewall firewall delete rule name="Kikifest (port 8081)" >nul 2>nul
netsh advfirewall firewall delete rule name="Kikifest" >nul 2>nul
echo 2. Autorisation de Kikifest...
set OK=1
if defined NODE netsh advfirewall firewall add rule name="Kikifest (Node.js)" dir=in action=allow program="%NODE%" enable=yes profile=any >nul || set OK=0
netsh advfirewall firewall add rule name="Kikifest (port 8080)" dir=in action=allow protocol=TCP localport=8080 enable=yes profile=any >nul || set OK=0
netsh advfirewall firewall add rule name="Kikifest (port 8081)" dir=in action=allow protocol=TCP localport=8081 enable=yes profile=any >nul || set OK=0
echo.
if "%OK%"=="1" (
  echo C'est fait : Kikifest est autorise dans le pare-feu Windows.
) else (
  echo Le pare-feu n'a pas pu etre modifie. S'il est gere par un antivirus
  echo ^(Avast, Norton, Kaspersky, Bitdefender, McAfee...^), autorisez Node.js ou le port 8080 dans ses reglages.
)
echo.
echo Etat du pare-feu Windows :
netsh advfirewall show currentprofile state
echo Relancez maintenant Heberger-Windows.bat.
echo.
pause
