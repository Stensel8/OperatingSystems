#!/bin/bash

# Servers
servers=("gameserver01" "gameserver02")

# Functie om te verbinden met een server en commando's uit te voeren
function run_on_server() {
  server=$1
  shift

  echo "** Verbinden met $server **"
  ssh -t $server "$@"

  echo "** Acties op $server voltooid **"
  echo
}

# Loop door servers en voer stappen uit
for server in "${servers[@]}"; do
  run_on_server $server <<EOF
  # Melding
  echo "** Webserver Apache installeren **"

  # Apache2 installeren
  sudo apt install -y apache2

  # Apache starten als service
  sudo systemctl start apache2

  # Melding
  echo "** Git installeren **"

  # Git installeren
  sudo apt install -y git

  # Melding
  echo "** HTML5 Breakout game downloaden en direct naar Apache-map klonen **"

  # Code downloaden en klonen naar Apache-map
  sudo git clone https://github.com/Stensel8/html5-breakout-game.git /var/www/html/html5-breakout-game

  # Melding
  echo "** Indexpagina aanmaken **"

  # Indexpagina aanmaken
  cat <<INDEX > /var/www/html/index.html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>HTML5 Breakout Game</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      text-align: center;
    }
    .container {
      margin-top: 100px;
    }
    .play-button {
      padding: 10px 20px;
      font-size: 18px;
      background-color: #4CAF50;
      color: white;
      border: none;
      border-radius: 5px;
      cursor: pointer;
    }
    .by-stensel8 {
      margin-top: 50px;
      font-size: 14px;
    }
    .by-stensel8 a {
      color: blue;
      text-decoration: none;
    }
    .contributors {
      margin-top: 20px;
      font-size: 14px;
    }
  </style>
</head>
<body>
  <div class="container">
    <h1>Welcome to HTML5 Breakout Game</h1>
    <button class="play-button" onclick="location.href='/html5-breakout-game/'">Click to Play</button>
  </div>
  <div class="by-stensel8">
    <p>By <a href="https://github.com/Stensel8/html5-breakout-game" target="_blank">Stensel8</a></p>
  </div>
  <div class="contributors">
    <h2>Contributors:</h2>
    <ol>
      <li><a href="https://github.com/VRamazing" target="_blank">VRamazing</a> - 40 commits</li>
      <li><a href="https://github.com/brunolm" target="_blank">brunolm</a> - 2 commits</li>
      <li><a href="https://github.com/Jake0Tron" target="_blank">Jake0Tron</a> - 2 commits</li>
      <li><a href="https://github.com/KayvanMazaheri" target="_blank">KayvanMazaheri</a> - 1 commit</li>
      <li><a href="https://github.com/andilee111" target="_blank">andilee111</a> - 1 commit</li>
      <li><a href="https://github.com/SirDaev" target="_blank">SirDaev</a> - 1 commit</li>
      <li><a href="https://github.com/raj-maurya" target="_blank">raj-maurya</a> - 1 commit</li>
      <li><a href="https://github.com/cynthiajbuck" target="_blank">cynthiajbuck</a> - 1 commit</li>
      <li><a href="https://github.com/httpstersk" target="_blank">httpstersk</a> - 1 commit</li>
      <li><a href="https://github.com/seanmonslow" target="_blank">seanmonslow</a> - 1 commit</li>
      <li><a href="https://github.com/Jaernbrand" target="_blank">Jaernbrand</a> - 1 commit</li>
    </ol>
  </div>
</body>
</html>
INDEX
EOF
done

# Melding
echo "** Script voltooid **"
echo "** De game is nu te benaderen op http://<ip-adres>/html5-breakout-game/ of http://<dns-naam>/html5-breakout-game/ op beide servers **"
