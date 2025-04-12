#!/bin/bash

# Kolory dla lepszej czytelności
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Dane do konfiguracji Let's Encrypt
domain="cassiopeia.piwo.org"
docker_project_name="cassiopeiapiworg"  # Dodajemy zmienną dla nazwy projektu Docker
rsa_key_size=4096
email="admin@cassiopeia.piwo.org"  # Zmień na swój adres e-mail
staging=0 # Ustaw na 1, aby testować konfigurację (nie generuje prawdziwych certyfikatów)
setup_letsencrypt=1 # Ustaw na 0, aby pominąć konfigurację Let's Encrypt

# Adres IP serwera do bezpośredniego dostępu
server_ip="192.168.0.101"

echo -e "${YELLOW}Pobieranie najnowszej wersji z repozytorium...${NC}"

# Sprawdzanie czy repozytorium już istnieje
if [ -d ".git" ]; then
    # Jeśli repozytorium istnieje, wykonaj git pull
    git pull origin master
else
    # Jeśli repozytorium nie istnieje, wykonaj git clone
    git clone https://github.com/elroyski/cassiopeia.piwo.org.git .
fi

# Sprawdzanie czy Docker jest zainstalowany
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker nie jest zainstalowany. Proszę zainstalować Docker.${NC}"
    exit 1
fi

# Sprawdzanie czy Docker Compose jest dostępny
has_docker_compose_v1=0
has_docker_compose_v2=0

if command -v docker-compose &> /dev/null; then
    has_docker_compose_v1=1
elif docker compose version &> /dev/null; then
    has_docker_compose_v2=1
else
    echo -e "${RED}Docker Compose nie jest zainstalowany. Proszę zainstalować Docker Compose.${NC}"
    exit 1
fi

# Funkcja do uruchamiania docker-compose
run_docker_compose() {
    if [ $has_docker_compose_v1 -eq 1 ]; then
        docker-compose -p $docker_project_name "$@"
    else
        docker compose -p $docker_project_name "$@"
    fi
}

# Sprawdzenie i zatrzymanie wszystkich kontenerów używających portu 80
if docker ps | grep -q "80/tcp"; then
    echo -e "${YELLOW}Wykryto inne kontenery używające portu 80. Próbuję je zatrzymać...${NC}"
    docker ps -q -f "publish=80" | xargs -r docker stop
    sleep 2
fi

# Tworzenie katalogów dla certbot przed uruchomieniem
mkdir -p certbot/www/.well-known/acme-challenge
mkdir -p certbot/conf
mkdir -p nginx/conf.d

# Tworzenie katalogów dla Unifi Controller
mkdir -p unifi/config
mkdir -p unifi/data
mkdir -p unifi/logs
mkdir -p unifi/run
mkdir -p unifi/lib
mkdir -p unifi/cert
mkdir -p unifi/init

# Tworzenie katalogów dla Pi-hole
mkdir -p pihole/etc
mkdir -p pihole/dnsmasq

# Upewniamy się, że skrypt znajdzie lub utworzy plik docker-compose.yml
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${YELLOW}Plik docker-compose.yml nie istnieje. Tworzę domyślny plik...${NC}"
    cat > docker-compose.yml << EOF
services:
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./www:/usr/share/nginx/html
      - ./nginx/conf.d:/etc/nginx/conf.d
      - ./certbot/conf:/etc/letsencrypt
      - ./certbot/www:/var/www/certbot
    depends_on:
      - php
    restart: always
    networks:
      - cassiopeia-network

  php:
    image: php:8.2-fpm-alpine
    volumes:
      - ./www:/usr/share/nginx/html
    restart: always
    networks:
      - cassiopeia-network

  certbot:
    image: certbot/certbot
    volumes:
      - ./certbot/conf:/etc/letsencrypt
      - ./certbot/www:/var/www/certbot
    command: /bin/sh -c "trap exit TERM; while :; do certbot renew; sleep 12h & wait \$\${!}; done;"
    networks:
      - cassiopeia-network

  unifi:
    image: linuxserver/unifi-controller:latest
    container_name: cassiopea-unifi-controller
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/Warsaw
      - MEM_LIMIT=1024 #optional
    volumes:
      - ./unifi/config:/config
      - ./unifi/data:/data
      - ./unifi/logs:/logs
      - ./unifi/run:/run/unifi
      - ./unifi/run:/var/run/unifi
      - ./unifi/lib:/var/lib/unifi
      - ./unifi/cert:/usr/lib/unifi/cert
      - ./unifi/init:/etc/cont-init.d
    ports:
      - 3478:3478/udp
      - 10001:10001/udp
      - 10001:10001/tcp
      - 8080:8080
      - 8443:8443
      - 1900:1900/udp #optional
      - 8843:8843 #optional
      - 8880:8880 #optional
      - 6789:6789 #optional
      - 5514:5514/udp #optional
    restart: unless-stopped
    networks:
      - cassiopeia-network

  pihole:
    container_name: cassiopea-pihole
    image: pihole/pihole:latest
    ports:
      - "53:53/tcp"
      - "53:53/udp"
      - "8888:80/tcp"
    environment:
      TZ: 'Europe/Warsaw'
      WEBPASSWORD: 'casiopea'
      SERVERIP: '192.168.0.101'
    volumes:
      - './pihole/etc:/etc/pihole'
      - './pihole/dnsmasq:/etc/dnsmasq.d'
    cap_add:
      - NET_ADMIN
    restart: unless-stopped
    networks:
      - cassiopeia-network

networks:
  cassiopeia-network:
    driver: bridge
EOF
fi

# Konfiguracja Nginx bez proxy pass do Unifi
cat > nginx/conf.d/default.conf << EOF
server {
    listen 80;
    server_name cassiopeia.piwo.org localhost 127.0.0.1;
    
    # Punkt weryfikacji Let's Encrypt - to musi być przed innymi lokalizacjami
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
        try_files \$uri =404;
    }
    
    location / {
        root /usr/share/nginx/html;
        index index.php index.html index.htm;
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    
    # PHP
    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass php:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
    }
    
    # Deny .htaccess
    location ~ /\.ht {
        deny all;
    }
}
EOF

echo -e "${YELLOW}Uruchamianie kontenerów Docker...${NC}"
run_docker_compose down --remove-orphans
sleep 2
run_docker_compose up -d --force-recreate

# Sprawdzanie czy uruchomienie się powiodło
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Kontenery zostały uruchomione pomyślnie!${NC}"
    
    # Dajemy chwilę na uruchomienie Nginx
    echo -e "${YELLOW}Czekam 5 sekund, aby Nginx mógł się uruchomić...${NC}"
    sleep 5
    
    echo -e "${GREEN}Strona powinna być dostępna pod adresem: http://localhost${NC}"
    echo -e "${GREEN}Strona powinna być dostępna pod adresem: http://$domain${NC}"
    echo -e "${GREEN}Unifi Controller dostępny pod: https://$server_ip:8443 (bezpośredni dostęp)${NC}"
    echo -e "${GREEN}Pi-hole dostępny pod: http://$server_ip:8888/admin (hasło: casiopea)${NC}"

    # Sprawdzenie dostępu do UniFi
    echo -e "${YELLOW}Sprawdzanie statusu Unifi Controller (może wymagać czasu na uruchomienie)...${NC}"
    sleep 10 # Daj więcej czasu kontrolerowi na uruchomienie
    curl -k -I https://$server_ip:8443 || echo -e "${RED}Brak dostępu do Unifi Controller na https://$server_ip:8443${NC}"
    
    # Testy diagnostyczne
    echo -e "${YELLOW}Wykonuję testy diagnostyczne...${NC}"
    echo -e "Sprawdzanie lokalnego dostępu do serwera:"
    curl -I http://localhost || echo -e "${RED}Brak dostępu do localhost${NC}"
    
    echo -e "\nSprawdzanie dostępu przez IP:"
    ip_local=$(hostname -I | awk '{print $1}')
    echo "Lokalne IP: $ip_local"
    curl -I http://$ip_local || echo -e "${RED}Brak dostępu przez lokalne IP${NC}"
    
    # Sprawdzanie nazwy sieci kontenera
    container_id=$(run_docker_compose ps -q nginx)
    echo -e "\nID kontenera Nginx: $container_id"
    
    if [ -n "$container_id" ]; then
        network_name=$(docker inspect -f '{{range $key, $value := .NetworkSettings.Networks}}{{$key}}{{end}}' $container_id)
        echo -e "Nazwa sieci: $network_name"
        
        # Sprawdzenie, czy Nginx nasłuchuje wewnątrz kontenera
        echo -e "\nSprawdzanie, czy Nginx nasłuchuje wewnątrz kontenera:"
        docker exec -it $container_id netstat -tuln || echo -e "${RED}Nie można sprawdzić portów wewnątrz kontenera${NC}"
    else
        echo -e "${RED}Nie można znaleźć kontenera Nginx${NC}"
    fi

    # Sprawdź logi UniFi
    echo -e "\n${YELLOW}Sprawdzanie logów Unifi Controller:${NC}"
    unifi_id=$(run_docker_compose ps -q unifi)
    if [ -n "$unifi_id" ]; then
        docker logs --tail 20 $unifi_id
    else
        echo -e "${RED}Nie można znaleźć kontenera Unifi Controller${NC}"
    fi
    
    # Konfiguracja Let's Encrypt
    if [ $setup_letsencrypt -eq 1 ]; then
        echo -e "${YELLOW}Czy chcesz skonfigurować HTTPS z Let's Encrypt? (t/n)${NC}"
        read -r odpowiedz
        if [[ "$odpowiedz" =~ ^[tT]$ ]]; then
            echo -e "${YELLOW}Sprawdzanie dostępności domeny...${NC}"
            
            # Sprawdzanie czy domena jest dostępna
            ip_serwera=$(curl -s ifconfig.me)
            echo -e "${YELLOW}IP tego serwera: $ip_serwera${NC}"
            
            # Tworzenie testowego pliku
            echo "testowy_plik_$(date +%s)" > certbot/www/.well-known/acme-challenge/test.txt
            echo -e "${YELLOW}Utworzono plik testowy: $(cat certbot/www/.well-known/acme-challenge/test.txt)${NC}"
            
            # Sprawdzenie uprawnień
            chmod -R 755 certbot/www
            
            echo -e "${YELLOW}Testowy plik został utworzony. Teraz sprawdzę, czy jest dostępny lokalnie...${NC}"
            echo -e "Lokalny dostęp: http://localhost/.well-known/acme-challenge/test.txt"
            curl -v http://localhost/.well-known/acme-challenge/test.txt || echo -e "${RED}Brak dostępu do pliku testowego przez localhost${NC}"
            
            echo -e "\n${YELLOW}Sprawdzam dostęp z zewnątrz: http://$domain/.well-known/acme-challenge/test.txt${NC}"
            curl -v --connect-timeout 10 http://$domain/.well-known/acme-challenge/test.txt || echo -e "${RED}Brak dostępu do pliku testowego przez domenę${NC}"
            
            echo -e "\n${YELLOW}Sprawdzanie DNS domeny...${NC}"
            host $domain || echo -e "${RED}Nie można sprawdzić DNS dla domeny${NC}"
            
            echo -e "\n${YELLOW}Sprawdzenie połączenia do portu 80...${NC}"
            nc -z -v -w5 $domain 80 || echo -e "${RED}Brak dostępu do portu 80 na domenie${NC}"
            
            echo -e "\n${YELLOW}Czy mimo tych testów chcesz spróbować pobrać certyfikat? (t/n)${NC}"
            read -r kontynuuj
            if [[ ! "$kontynuuj" =~ ^[tT]$ ]]; then
                echo -e "${YELLOW}Pominięto konfigurację HTTPS.${NC}"
                exit 0
            fi
            
            echo -e "${YELLOW}Konfiguracja Let's Encrypt...${NC}"
            
            # Wybór trybu: staging/produkcja
            if [ "$staging" -eq 1 ]; then
                staging_arg="--staging"
            else
                staging_arg=""
            fi
            
            echo -e "${YELLOW}Używam sieci: $network_name${NC}"
            
            # Uruchamianie certbot do pobrania certyfikatu
            docker run --rm \
                -v "$(pwd)/certbot/conf:/etc/letsencrypt" \
                -v "$(pwd)/certbot/www:/var/www/certbot" \
                --network "$network_name" \
                certbot/certbot \
                certonly --webroot -w /var/www/certbot \
                $staging_arg \
                -d $domain \
                --email $email \
                --rsa-key-size $rsa_key_size \
                --agree-tos \
                --no-eff-email
            
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}Certyfikat Let's Encrypt został pomyślnie pobrany.${NC}"
                
                # Pobierz rekomendowane pliki konfiguracyjne SSL
                curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf > certbot/conf/options-ssl-nginx.conf
                curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem > certbot/conf/ssl-dhparams.pem
                
                # Teraz dodajemy konfigurację HTTPS (bez proxy_pass dla Unifi)
                cat > nginx/conf.d/default.conf << EOF
server {
    listen 80;
    server_name cassiopeia.piwo.org localhost 127.0.0.1;
    
    # Punkt weryfikacji Let's Encrypt - to musi być przed innymi lokalizacjami
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
        try_files \$uri =404;
    }
    
    location / {
        root /usr/share/nginx/html;
        index index.php index.html index.htm;
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    
    # PHP
    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass php:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
    }
    
    # Deny .htaccess
    location ~ /\.ht {
        deny all;
    }
}

# Serwer HTTPS
server {
    listen 443 ssl;
    server_name cassiopeia.piwo.org;
    
    # Certyfikaty SSL/TLS
    ssl_certificate /etc/letsencrypt/live/cassiopeia.piwo.org/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/cassiopeia.piwo.org/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
    
    root /usr/share/nginx/html;
    index index.php index.html index.htm;
    
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    
    # PHP
    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass php:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
    }
    
    # Deny .htaccess
    location ~ /\.ht {
        deny all;
    }
    
    # Strony błędów
    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
        root /usr/share/nginx/html;
    }
}
EOF
                
                echo -e "${YELLOW}Restartowanie kontenerów, aby zastosować certyfikat...${NC}"
                run_docker_compose restart nginx
                echo -e "${GREEN}Strona jest teraz dostępna pod adresem: https://$domain${NC}"
                echo -e "${GREEN}Unifi Controller dostępny pod: https://$server_ip:8443 (bezpośredni dostęp)${NC}"
            else
                echo -e "${RED}Nie udało się pobrać certyfikatu Let's Encrypt.${NC}"
                echo -e "${RED}Upewnij się, że domena $domain wskazuje na ten serwer i port 80 jest dostępny z internetu.${NC}"
                echo -e "${YELLOW}Możesz ręcznie sprawdzić status weryfikacji:${NC}"
                echo -e "${YELLOW}curl -I http://$domain/.well-known/acme-challenge/test.txt${NC}"
                
                echo -e "\n${RED}Podsumowanie problemu:${NC}"
                echo -e "1. Domena $domain powinna wskazywać na IP: $ip_serwera"
                echo -e "2. Port 80 musi być otwarty i przekierowany do tego serwera"
                echo -e "3. Firewall nie może blokować połączeń HTTP"
                echo -e "4. Router/firewall musi przekierowywać port 80 na lokalny adres IP: $ip_local"
            fi
        else
            echo -e "${YELLOW}Pominięto konfigurację HTTPS.${NC}"
        fi
    fi
else
    echo -e "${RED}Wystąpił błąd podczas uruchamiania kontenerów.${NC}"
    exit 1
fi 