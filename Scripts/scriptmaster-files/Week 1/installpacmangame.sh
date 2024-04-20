#!/bin/bash

# Servers
servers=("gameserver01" "gameserver02")

# Functie om verbinding te maken met een server en commando's uit te voeren
function run_on_server() {
  server=$1
  shift

  echo "** Verbinding maken met $server **"
  ssh -t $server "$@"

  echo "** Acties op $server voltooid **"
  echo
}

# Loop door servers en voer stappen uit
for server in "${servers[@]}"; do
  run_on_server $server <<EOF
  # Melding
  echo "** Apache webserver installeren **"

  # Apache2 installeren
  sudo apt install -y apache2

  # Apache starten als service
  sudo systemctl start apache2

  # Melding
  echo "** Git installeren **"

  # Git installeren
  sudo apt install -y git

  # Melding
  echo "** NPM installeren **"

  # NPM (Node.js Packet Manager) installeren
  sudo apt install -y npm

  # Melding
  echo "** HTML5 game downloaden en naar Apache-directory klonen **"

  # Code van HTML5 game downloaden en naar Apache-directory klonen
  sudo git clone https://github.com/platzhersh/pacman-canvas.git /var/www/html/pacman-canvas

  # In de "pacman-canvas" map gaan die is aangemaakt in de vorige stap
  cd /var/www/html/pacman-canvas

  # Dependencies installeren voor de game
  sudo npm install
  sudo npm audit fix

  # Melding
  echo "** Indexpagina aanmaken **"

  # Indexpagina aanmaken
  cat <<INDEX > /var/www/html/index.html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>PAC-MAN</title>
</head>
<body>
  <h1>Welcome to PAC-MAN</h1>
  <a href="pacman-canvas/index.htm">Play PAC-MAN</a>
</body>
</html>
INDEX
EOF
done

# Melding
echo "** Script voltooid **"
echo "** Het spel kan nu worden gespeeld op http://<ip-adres>/pacman-canvas/ op beide servers **"
