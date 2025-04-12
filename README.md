# Casiopea - Piwo.org

Repozytorium projektu Casiopea.

## Konfiguracja

Projekt wykorzystuje Nginx, PHP 8.2 i Let's Encrypt do obsługi strony internetowej.

### Wymagania

- Docker
- Docker Compose

### Uruchomienie

Istnieje jeden uniwersalny skrypt, który przeprowadzi cały proces konfiguracji:

```bash
# Pobieranie repozytorium
git clone https://github.com/elroyski/casiopea.piwo.org.git
cd casiopea.piwo.org

# Upewnij się, że skrypt ma prawa do wykonania
chmod +x start.sh

# Uruchom skrypt
./start.sh
```

Skrypt `start.sh` wykonuje następujące czynności:
1. Pobiera najnowszą wersję repozytorium (lub klonuje je, jeśli nie istnieje)
2. Konfiguruje certyfikaty Let's Encrypt
3. Uruchamia kontenery Docker

### Opcje konfiguracji

Skrypt można dostosować, edytując następujące parametry w jego kodzie:
- `email` - adres email do powiadomień Let's Encrypt
- `staging` - ustaw na 1 dla środowiska testowego Let's Encrypt
- `setup_letsencrypt` - ustaw na 0, aby pominąć konfigurację Let's Encrypt

### Strona

Po uruchomieniu strona będzie dostępna pod adresami:
- HTTP: http://casiopea.piwo.org
- HTTPS: https://casiopea.piwo.org (jeśli skonfigurowano Let's Encrypt) 