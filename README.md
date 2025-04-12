# Casiopea - Piwo.org

Repozytorium projektu Casiopea.

## Konfiguracja

Projekt wykorzystuje Nginx, PHP 8.2 i Let's Encrypt do obsługi strony internetowej.

### Wymagania

- Docker
- Docker Compose

### Uruchomienie

Uruchom skrypt inicjalizacyjny, aby skonfigurować certyfikaty SSL/TLS:

```bash
# Upewnij się, że skrypt ma prawa do wykonania
chmod +x init-letsencrypt.sh

# Uruchom skrypt inicjalizacyjny
./init-letsencrypt.sh
```

### Strona

Po uruchomieniu strona będzie dostępna pod adresami:
- HTTP: http://casiopea.piwo.org
- HTTPS: https://casiopea.piwo.org

W przypadku problemów z certyfikatami, możesz edytować plik `init-letsencrypt.sh` i zmienić parametr `staging=0` na `staging=1`, aby użyć środowiska testowego Let's Encrypt. 