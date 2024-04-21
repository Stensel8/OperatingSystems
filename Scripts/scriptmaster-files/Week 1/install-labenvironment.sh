#!/bin/bash

########################################################################################
# © Sten Tijhuis - 550600
# install-labenvironment.sh
########################################################################################

########################################################################################
# Functies
########################################################################################

functie rode_echo() {
  echo -e "\e[31m$1\e[0m"
}

functie oranje_echo() {
  echo -e "\e[33m$1\e[0m"
}

functie groene_echo() {
  echo -e "\e[32m$1\e[0m"
}

functie blauwe_echo() {
  echo -e "\e[34m$1\e[0m"
}

# Functie om foutmeldingen weer te geven en af te sluiten
fout() {
  rode_echo "Fout: $1" >&2
  exit 1
}

# Functie om het IP-adres formaat te valideren
valideer_ip() {
  lokaal ip=$1
  if [[ ! $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    return 1
  fi
}

# Functie om witruimte toe te voegen voor duidelijkere uitvoer
aangepaste_echo() {
  echo -e "\n\e[33m$1\e[0m"
}

# Functie om het pingstatus te testen en weer te geven
test_ip_en_weergeven() {
  lokaal ip=$1
  lokaal teller=$2
  lokaal totaal=$3

  ping -c 1 "$ip" &> /dev/null
  if [[ $? -eq 0 ]]; then
    groene_echo "Testen ${teller}/${totaal}.... OK. Machine lijkt online te zijn!"
  else
    rode_echo "FOUT! Testen ${teller}/${totaal}.... $ip lijkt offline te zijn."
    return 1  # Geef een exitcode verschillend van nul terug bij fout
  fi
}

# Functie om IP-adressen te lezen en valideren
lees_en_valideer_ip_adressen() {
  lokaal poging=0
  lokaal max_pogingen=3
  geldige_invoer=false

  aangepaste_echo "Wat is het IP-adres van de momenteel gebruikte VM (scriptmaster)?"
  terwijl waar; doe
    lezen IPMASTER
    als valideer_ip "$IPMASTER"; dan
      doorbreken
    fi

    ((poging++))
    als ((poging >= max_pogingen)); dan
      fout "Maximum aantal pogingen overschreden. Afsluiten."
    fi
    clear
    rode_echo "Ongeldig IP-adres formaat. Probeer opnieuw."
  gedaan

  poging=0

  aangepaste_echo "Voer het IP-adres van gameserver01 in:"
  terwijl waar; doe
    lezen IPSERVER1
    als valideer_ip "$IPSERVER1"; dan
      doorbreken
    fi

    ((poging++))
    als ((poging >= max_pogingen)); dan
      fout "Maximum aantal pogingen overschreden. Afsluiten."
    fi
    clear
    rode_echo "Ongeldig IP-adres formaat. Probeer opnieuw."
  gedaan

  poging=0

  aangepaste_echo "Voer het IP-adres van gameserver02 in:"
  terwijl waar; doe
    lezen IPSERVER2
    als valideer_ip "$IPSERVER2"; dan
      doorbreken
    fi

    ((poging++))
    als ((poging >= max_pogingen)); dan
      fout "Maximum aantal pogingen overschreden. Afsluiten."
    fi
    clear
    rode_echo "Ongeldig IP-adres formaat. Probeer opnieuw."
  gedaan

  geldige_invoer=true
}

# Functie om alle ingevoerde IP's te testen
test_en_toon_alle_ips() {
  als [[ $geldige_invoer == true ]]; dan
    # Test elk IP-adres en stop script als er een fout optreedt
    als ! test_ip_en_weergeven "$IPMASTER" 1 3; dan
      exit 1
    fi
    als ! test_ip_en_weergeven "$IPSERVER1" 2 3; dan
      exit 1
    fi
    test_ip_en_weergeven "$IPSERVER2" 3 3  # Test de laatste zelfs als eerdere mislukken
  else
    rode_echo "Testen afgebroken. Voer eerst geldige IP-adressen in."
  fi
}

# Lees de initiële IP-adressen en begin met testen
lees_en_valideer_ip_adressen
test_en_toon_alle_ips

########################################################################################
# Genereer ssh-sleutels voor de rootgebruiker en kopieer ze naar de Ubuntu 22.04-servers.
########################################################################################

als [[ $? -eq 0 ]]; dan
  aangepaste_echo
  aangepaste_echo "\e[33mGenereren van ssh-sleutels...\e[0m"
  ssh-keygen
fi

GEBRUIKER="root"

voor HOST in $IPSERVER1 $IPSERVER2
do
  aangepaste_echo
  aangepaste_echo "\e[33mProbeer ssh-sleutels te kopiëren naar $HOST...\e[0m"
  als ssh-copy-id -f -i ~/.ssh/id_rsa.pub $GEBRUIKER@$HOST; dan
    aangepaste_echo "\n\n \e[32mssh-sleutels geïnstalleerd op $HOST \e[0m \n\n"
  else
    aangepaste_echo "\e[31mKopiëren van ssh-sleutels naar $HOST is mislukt. Controleer de bereikbaarheid en probeer het opnieuw.\e[0m"
  fi
gedaan

########################################################################################
# Stel de hostnaam op de huidige machine in op scriptmaster.
########################################################################################

aangepaste_echo
aangepaste_echo "\e[33mInstellen van hostnaam van de huidige machine op 'scriptmaster'...\e[0m"
hostnamectl set-hostname scriptmaster && groene_echo "Hostname ingesteld!"

########################################################################################
# Werk /etc/hosts bij om servers op te lossen (handmatige DNS-oplossing).
########################################################################################

aangepaste_echo "\e[33mBijwerken van /etc/hosts met DNS-vermeldingen...\e[0m"

cat << EOF > /etc/hosts
# /etc/hosts

127.0.0.1 localhost
$IPMASTER     scriptmaster  
$IPSERVER1    gameserver01  
$IPSERVER2    gameserver02  
EOF

echo -e "\e[33mWaarschuwing: Overschrijven van /etc/hosts bestand met nieuwe vermeldingen. Dit zal oude DNS-vermeldingen wissen.\e[0m"
lees -p "Doorgaan? (j/n): " keuze

als [[ $keuze != "j" && $keuze != "J" ]]; dan
    rode_echo "Afsluiten op verzoek van de gebruiker."
    exit 1
fi

########################################################################################
# Kopieer de DNS-vermeldingen in /etc/hosts naar de andere servers.
########################################################################################

aangepaste_echo "\e[33mPoging om DNS-vermeldingen naar andere servers te kopiëren...\e[0m"

voor HOST in "gameserver01" "gameserver02"; doe
    scp -q /etc/hosts $HOST:/etc/hosts && groene_echo "\e[32mDNS-vermeldingen gekopieerd naar $HOST!\e[0m"
gedaan

# Stel de hostnaam in op elke server na het kopiëren van DNS-vermeldingen
voor HOST in "gameserver01" "gameserver02"; doe
    aangepaste_echo "\e[33mInstellen van hostnaam op $HOST...\e[0m"
    ssh $HOST "hostnamectl set-hostname $HOST" && groene_echo "\e[32mHostname ingesteld op $HOST!\e[0m"
gedaan

########################################################################################
# Start de hele cluster opnieuw op zodat de nieuwe hostnamen worden toegepast.
########################################################################################

aangepaste_echo ""
lees -p "Wil je de betrokken machines opnieuw opstarten om de uitstaande naamwijzigingen toe te passen? (j/n): " keuze
als [[ $keuze == "j" || $keuze == "J" ]]; dan
  aangepaste_echo "\e[33mOpnieuw opstarten van alle hosts (volledige cluster)...\e[0m"
  voor HOST in "gameserver01" "gameserver02"; doe
    aangepaste_echo "Poging tot herstarten van $HOST... "
    ssh $HOST "reboot" &

    # Wachtlus met voortgangsupdates
    max_pogingen=10  # Pas indien nodig aan
    voor poging in $(seq 1 $max_pogingen); doe
      slapen 10
      als ping -c 1 $HOST &> /dev/null; dan
        groene_echo "\e[32mSucces!\e[0m"
        pauze
      anders
        echo -n "$((poging * 10))/100s..."  # Tijdgebaseerde voortgangsindicator
      fi
    gedaan

    als [[ $poging == $max_pogingen ]]; dan
      rode_echo "\e[33mHerstartopdracht verzonden, verbinding verbroken, maar het script heeft de host niet zien opkomen.\e[0m"
      rode_echo "\e[31mHerstarten van $HOST mislukt na $max_pogingen pogingen\e[0m"
    fi
  gedaan
    # Herstart de huidige machine
    aangepaste_echo "\e[33mHerstarten van de huidige machine...\e[0m"
    slapen 3
    aangepaste_echo "\e[32mTot ziens!\e[0m"
    herstarten
anders
    echo "Script is uitgevoerd, maar er was een probleem bij het herstarten van (een van) de machines!"
fi
