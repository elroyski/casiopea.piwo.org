#!/bin/bash

# Kolory dla lepszej czytelności
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Pobieranie najnowszej wersji z repozytorium...${NC}"

# Sprawdzanie czy repozytorium już istnieje
if [ -d ".git" ]; then
    # Jeśli repozytorium istnieje, wykonaj git pull
    git pull origin master
else
    # Jeśli repozytorium nie istnieje, wykonaj git clone
    git clone https://github.com/elroyski/casiopea.piwo.org.git .
fi

echo -e "${YELLOW}Uruchamianie kontenerów Docker...${NC}"

# Sprawdzanie czy docker-compose jest zainstalowany
if ! command -v docker-compose &> /dev/null; then
    echo -e "${YELLOW}Docker Compose nie jest zainstalowany. Próba użycia 'docker compose' (V2)...${NC}"
    # Próba uruchomienia używając Docker Compose V2
    if ! command -v docker &> /dev/null; then
        echo -e "${YELLOW}Docker nie jest zainstalowany. Proszę zainstalować Docker i Docker Compose.${NC}"
        exit 1
    else
        docker compose up -d
    fi
else
    # Uruchamianie używając Docker Compose V1
    docker-compose up -d
fi

# Sprawdzanie czy uruchomienie się powiodło
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Kontenery zostały uruchomione pomyślnie!${NC}"
    echo -e "${GREEN}Strona jest dostępna pod adresem: http://localhost${NC}"
else
    echo -e "${YELLOW}Wystąpił błąd podczas uruchamiania kontenerów.${NC}"
    exit 1
fi 