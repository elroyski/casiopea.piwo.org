# Casiopea - Piwo.org

Repozytorium projektu Casiopea.

## Konfiguracja

Projekt wykorzystuje Nginx, PHP 8.2 i Let's Encrypt do obsługi strony internetowej.

### Wymagania

- Docker
- Docker Compose
- Port 80 otwarty i przekierowany do serwera (dla konfiguracji HTTPS)
- Domena wskazująca na adres IP serwera

### Konfiguracja domeny i przekierowania portów

Aby Let's Encrypt działał poprawnie:

1. Domena `casiopea.piwo.org` musi wskazywać na publiczny adres IP serwera
2. Port 80 musi być publicznie dostępny (do weryfikacji domeny)
3. W przypadku routera/firewalla należy przekierować port 80 na serwer

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
2. Uruchamia kontenery Docker
3. Wykonuje testy diagnostyczne
4. Opcjonalnie konfiguruje HTTPS z Let's Encrypt

### Opcje konfiguracji

Skrypt można dostosować, edytując następujące parametry w jego kodzie:
- `email` - adres email do powiadomień Let's Encrypt
- `staging` - ustaw na 1 dla środowiska testowego Let's Encrypt
- `setup_letsencrypt` - ustaw na 0, aby pominąć konfigurację Let's Encrypt

### Rozwiązywanie problemów

Jeśli Let's Encrypt nie może zweryfikować domeny:

1. Sprawdź czy domena wskazuje na właściwy adres IP (sprawdź komendą `host casiopea.piwo.org`)
2. Upewnij się, że port 80 jest otwarty i dostępny z internetu
3. Sprawdź czy router/firewall przekierowuje port 80 na serwer
4. Uruchom skrypt ponownie i przeanalizuj wyniki testów diagnostycznych

### Strona

Po uruchomieniu strona będzie dostępna pod adresami:
- HTTP: http://casiopea.piwo.org
- HTTPS: https://casiopea.piwo.org (jeśli skonfigurowano Let's Encrypt) 