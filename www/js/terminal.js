document.addEventListener('DOMContentLoaded', function() {
    // Wyświetlenie modalu logowania (opcjonalnie)
    // showLoginModal();
    
    // Inicjalizacja typowania komend
    setupTypedCommands();
    
    // Obsługa wprowadzania komend przez użytkownika
    setupCommandInput();
    
    // Dodanie efektu matrixa w tle (opcjonalnie)
    // setupMatrixBackground();
});

function setupTypedCommands() {
    const commands = {
        welcome: {
            command: "echo 'Witaj w terminalu Casiopea Labs'",
            output: `Witaj w systemie terminalowym <span class="success">casiopea.piwo.org</span>
Data: ${new Date().toLocaleString('pl-PL')}
Ostatnie logowanie: Nieznane

Ten terminal zapewnia dostęp do usług laboratoryjnych Casiopea.
Wpisz <span class="command">help</span> aby zobaczyć dostępne komendy.`
        },
        status: {
            command: "systemctl status",
            output: `● System działający: <span class="success">Tak</span>
● Obciążenie systemu: <span class="success">Niskie</span>
● Temperatura CPU: <span class="success">45°C</span>
● Użycie RAM: <span class="success">2.4GB / 16GB</span>
● Użycie dysku: <span class="success">120GB / 1TB</span>
● Aktywne usługi: <span class="success">12 usług</span>
● Status sieci: <span class="success">Online</span>
● Uptime: 21 dni, 5 godzin, 32 minuty`
        },
        services: {
            command: "service --status-all | grep '+'",
            output: `<table class="service-table">
<tr>
    <th>Usługa</th>
    <th>Status</th>
    <th>Port</th>
    <th>Dostęp</th>
</tr>
<tr>
    <td>nginx</td>
    <td><span class="success">Działający</span></td>
    <td>80, 443</td>
    <td><a href="https://casiopea.piwo.org" target="_blank">Otwórz</a></td>
</tr>
<tr>
    <td>php-fpm</td>
    <td><span class="success">Działający</span></td>
    <td>9000</td>
    <td>Wewnętrzny</td>
</tr>
<tr>
    <td>homebridge</td>
    <td><span class="success">Działający</span></td>
    <td>8581</td>
    <td><a href="http://casiopea.piwo.org:8581" target="_blank">Panel</a></td>
</tr>
<tr>
    <td>pihole</td>
    <td><span class="success">Działający</span></td>
    <td>53, 8080</td>
    <td><a href="http://casiopea.piwo.org:8080/admin" target="_blank">Panel</a></td>
</tr>
<tr>
    <td>jellyfin</td>
    <td><span class="success">Działający</span></td>
    <td>8096</td>
    <td><a href="http://casiopea.piwo.org:8096" target="_blank">Media</a></td>
</tr>
<tr>
    <td>transmission</td>
    <td><span class="warning">Wstrzymany</span></td>
    <td>9091</td>
    <td><a href="http://casiopea.piwo.org:9091" target="_blank">Panel</a></td>
</tr>
<tr>
    <td>samba</td>
    <td><span class="success">Działający</span></td>
    <td>445</td>
    <td>LAN</td>
</tr>
<tr>
    <td>ssh</td>
    <td><span class="success">Działający</span></td>
    <td>22</td>
    <td>Zabezpieczony</td>
</tr>
</table>`
        },
        help: {
            command: "help",
            output: `Dostępne komendy:
<table class="service-table">
<tr>
    <th>Komenda</th>
    <th>Opis</th>
</tr>
<tr>
    <td>help</td>
    <td>Wyświetla tę pomoc</td>
</tr>
<tr>
    <td>status</td>
    <td>Sprawdza status systemu</td>
</tr>
<tr>
    <td>services</td>
    <td>Wyświetla dostępne usługi</td>
</tr>
<tr>
    <td>clear</td>
    <td>Czyści ekran</td>
</tr>
<tr>
    <td>whoami</td>
    <td>Wyświetla informacje o użytkowniku</td>
</tr>
<tr>
    <td>ls</td>
    <td>Wyświetla pliki w katalogu</td>
</tr>
<tr>
    <td>cat [plik]</td>
    <td>Wyświetla zawartość pliku</td>
</tr>
<tr>
    <td>ping [host]</td>
    <td>Sprawdza połączenie z podanym hostem</td>
</tr>
<tr>
    <td>echo [tekst]</td>
    <td>Wyświetla podany tekst</td>
</tr>
<tr>
    <td>login</td>
    <td>Logowanie do systemu</td>
</tr>
</table>`
        }
    };

    // Animowane pisanie komend root
    setTimeout(() => {
        new Typed('#welcomeCommand', {
            strings: [commands.welcome.command],
            typeSpeed: 30,
            showCursor: false,
            onComplete: function() {
                setTimeout(() => {
                    document.getElementById('welcomeOutput').innerHTML = commands.welcome.output;
                    
                    // Uruchom następną komendę po zakończeniu poprzedniej
                    setTimeout(() => {
                        new Typed('#statusCommand', {
                            strings: [commands.status.command],
                            typeSpeed: 30,
                            showCursor: false,
                            onComplete: function() {
                                setTimeout(() => {
                                    document.getElementById('statusOutput').innerHTML = commands.status.output;
                                    
                                    // Uruchom trzecią komendę
                                    setTimeout(() => {
                                        new Typed('#servicesCommand', {
                                            strings: [commands.services.command],
                                            typeSpeed: 30,
                                            showCursor: false,
                                            onComplete: function() {
                                                setTimeout(() => {
                                                    document.getElementById('servicesOutput').innerHTML = commands.services.output;
                                                    
                                                    // Uruchom czwartą komendę
                                                    setTimeout(() => {
                                                        new Typed('#helpCommand', {
                                                            strings: [commands.help.command],
                                                            typeSpeed: 30,
                                                            showCursor: false,
                                                            onComplete: function() {
                                                                setTimeout(() => {
                                                                    document.getElementById('helpOutput').innerHTML = commands.help.output;
                                                                    
                                                                    // Na końcu scrolluj do dołu
                                                                    const terminal = document.querySelector('.terminal-content');
                                                                    terminal.scrollTop = terminal.scrollHeight;
                                                                    
                                                                    // Fokus na input
                                                                    document.getElementById('userInput').focus();
                                                                }, 300);
                                                            }
                                                        });
                                                    }, 1000);
                                                }, 300);
                                            }
                                        });
                                    }, 1000);
                                }, 300);
                            }
                        });
                    }, 1000);
                }, 300);
            }
        });
    }, 500);
}

function setupCommandInput() {
    const userInput = document.getElementById('userInput');
    const terminal = document.querySelector('.terminal-content');
    
    userInput.addEventListener('keydown', function(e) {
        if (e.key === 'Enter') {
            e.preventDefault();
            const command = userInput.value.trim();
            if (command) {
                processCommand(command);
                userInput.value = '';
                
                // Przewiń do końca terminala
                terminal.scrollTop = terminal.scrollHeight;
            }
        }
    });
    
    // Fokus na input przy kliknięciu w terminal
    terminal.addEventListener('click', function() {
        userInput.focus();
    });
}

function processCommand(command) {
    const terminal = document.querySelector('.terminal-content');
    const lines = document.querySelector('.terminal-lines');
    
    // Dodaj wprowadzoną komendę do terminala
    const commandLine = document.createElement('div');
    commandLine.className = 'line';
    commandLine.innerHTML = `<span class="user">visitor@casiopea:</span><span class="path">~$</span> <span class="command">${command}</span>`;
    
    // Dodaj wiersz komendy przed terminalem wejściowym
    document.querySelector('.terminal-input').before(commandLine);
    
    // Dodaj odpowiedź
    const outputLine = document.createElement('div');
    outputLine.className = 'line output';
    
    // Przetwarzanie różnych komend
    switch(command.toLowerCase()) {
        case 'help':
            // Komenda help jest już wyświetlona, więc po prostu zrób referencję
            outputLine.innerHTML = document.getElementById('helpOutput').innerHTML;
            break;
        case 'status':
            outputLine.innerHTML = document.getElementById('statusOutput').innerHTML;
            break;
        case 'services':
            outputLine.innerHTML = document.getElementById('servicesOutput').innerHTML;
            break;
        case 'clear':
            // Usuń wszystkie linie oprócz wejścia
            const linesToRemove = document.querySelectorAll('.terminal-lines .line:not(.terminal-input)');
            linesToRemove.forEach(line => line.remove());
            return; // Nie dodawaj żadnego wyjścia
        case 'whoami':
            outputLine.innerHTML = 'visitor';
            break;
        case 'ls':
            outputLine.innerHTML = `total 16
drwxr-xr-x 2 root root 4096 lip 11 09:21 <span class="warning">configs</span>
drwxr-xr-x 2 root root 4096 lip 11 09:22 <span class="warning">data</span>
drwxr-xr-x 2 root root 4096 lip 11 09:22 <span class="warning">services</span>
-rw-r--r-- 1 root root  845 lip 11 09:22 <span class="success">README.md</span>`;
            break;
        case 'login':
            showLoginModal();
            outputLine.innerHTML = 'Otwieranie okna logowania...';
            break;
        default:
            if (command.startsWith('ping ')) {
                const host = command.split(' ')[1];
                if (host) {
                    outputLine.innerHTML = `PING ${host} (127.0.0.1) 56(84) bytes of data.
64 bytes from localhost (127.0.0.1): icmp_seq=1 ttl=64 time=0.035 ms
64 bytes from localhost (127.0.0.1): icmp_seq=2 ttl=64 time=0.046 ms
64 bytes from localhost (127.0.0.1): icmp_seq=3 ttl=64 time=0.049 ms
64 bytes from localhost (127.0.0.1): icmp_seq=4 ttl=64 time=0.048 ms

--- ${host} ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3055ms
rtt min/avg/max/mdev = 0.035/0.044/0.049/0.006 ms`;
                } else {
                    outputLine.innerHTML = '<span class="error">ping: brakujący adres hosta</span>';
                }
            } else if (command.startsWith('cat ')) {
                const file = command.split(' ')[1];
                if (file === 'README.md') {
                    outputLine.innerHTML = `# Casiopea Labs

Ten serwer zawiera usługi wewnętrzne i narzędzia administracyjne
dla sieci domowej Casiopea. 

## Dostępne usługi

- Media Server (Jellyfin)
- Pi-hole (bloker reklam w sieci)
- HomeKit Bridge (integracja urządzeń smart home)
- Samba (udostępnianie plików w sieci)

## Kontakt

W razie problemów technicznych z serwerem, skontaktuj się
z administratorem: admin@casiopea.piwo.org`;
                } else {
                    outputLine.innerHTML = `<span class="error">cat: ${file}: Nie ma takiego pliku lub katalogu</span>`;
                }
            } else if (command.startsWith('echo ')) {
                const text = command.substring(5);
                outputLine.innerHTML = text;
            } else {
                outputLine.innerHTML = `<span class="error">Nieznana komenda: ${command}</span>. Wpisz 'help' aby zobaczyć dostępne komendy.`;
            }
    }
    
    // Dodaj odpowiedź przed terminalem wejściowym
    document.querySelector('.terminal-input').before(outputLine);
    
    // Scrolluj na dół
    terminal.scrollTop = terminal.scrollHeight;
}

function showLoginModal() {
    const modal = document.getElementById('loginModal');
    const closeBtn = document.querySelector('.close');
    const loginBtn = document.getElementById('loginButton');
    const guestBtn = document.getElementById('guestButton');
    
    modal.style.display = 'flex';
    
    closeBtn.addEventListener('click', function() {
        modal.style.display = 'none';
    });
    
    loginBtn.addEventListener('click', function() {
        const username = document.getElementById('username').value;
        const password = document.getElementById('password').value;
        
        // Tutaj możesz dodać logikę autentykacji, ale na razie tylko zamykamy modal
        modal.style.display = 'none';
        
        // Dodaj wiadomość o błędzie logowania do terminala
        const outputLine = document.createElement('div');
        outputLine.className = 'line output';
        outputLine.innerHTML = '<span class="error">Błąd logowania: Nieprawidłowe dane uwierzytelniające</span>';
        document.querySelector('.terminal-input').before(outputLine);
    });
    
    guestBtn.addEventListener('click', function() {
        modal.style.display = 'none';
    });
    
    // Zamykanie modalu po kliknięciu poza nim
    window.addEventListener('click', function(event) {
        if (event.target === modal) {
            modal.style.display = 'none';
        }
    });
}

function setupMatrixBackground() {
    const canvas = document.createElement('canvas');
    canvas.className = 'matrix-bg';
    document.body.appendChild(canvas);
    
    const ctx = canvas.getContext('2d');
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;
    
    const katakana = 'アァカサタナハマヤャラワガザダバパイィキシチニヒミリヰギジヂビピウゥクスツヌフムユュルグズブヅプエェケセテネヘメレヱゲゼデベペオォコソトノホモヨョロヲゴゾドボポヴッン';
    const latin = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const nums = '0123456789';
    const symbols = '!"#$%&()*+,-./:;<=>?@[\\]^_`{|}~';
    
    const alphabet = katakana + latin + nums + symbols;
    
    const fontSize = 16;
    const columns = canvas.width / fontSize;
    
    const rainDrops = [];
    
    for (let x = 0; x < columns; x++) {
        rainDrops[x] = 1;
    }
    
    const draw = () => {
        ctx.fillStyle = 'rgba(0, 0, 0, 0.05)';
        ctx.fillRect(0, 0, canvas.width, canvas.height);
        
        ctx.fillStyle = '#0F0';
        ctx.font = fontSize + 'px monospace';
        
        for (let i = 0; i < rainDrops.length; i++) {
            const text = alphabet.charAt(Math.floor(Math.random() * alphabet.length));
            ctx.fillText(text, i * fontSize, rainDrops[i] * fontSize);
            
            if (rainDrops[i] * fontSize > canvas.height && Math.random() > 0.975) {
                rainDrops[i] = 0;
            }
            rainDrops[i]++;
        }
    };
    
    setInterval(draw, 30);
    
    window.addEventListener('resize', () => {
        canvas.width = window.innerWidth;
        canvas.height = window.innerHeight;
    });
}

// Dane systemowe
const startDate = new Date();

// Aktualizuj czas działania
function updateUptime() {
    const now = new Date();
    const diff = Math.floor((now - startDate) / 1000);
    
    const days = Math.floor(diff / 86400);
    const hours = Math.floor((diff % 86400) / 3600);
    const minutes = Math.floor((diff % 3600) / 60);
    const seconds = diff % 60;
    
    const uptimeText = `${days} dni, ${hours} godzin, ${minutes} minut, ${seconds} sekund`;
    document.getElementById('uptime').textContent = uptimeText;
}

// Aktualizuj co sekundę
setInterval(updateUptime, 1000);

// Obsługa terminala
const terminal = {
    output: document.getElementById('terminal-output'),
    input: document.getElementById('cmd'),
    
    // Przetwarzanie polecenia
    processCommand(command) {
        this.addLine(`~$ ${command}`);
        
        // Usuwamy dodatkowe spacje i dzielimy na poszczególne części polecenia
        const args = command.trim().split(' ');
        const cmd = args[0].toLowerCase();
        
        switch(cmd) {
            case 'help':
                this.showHelp();
                break;
            case 'clear':
                this.clear();
                break;
            case 'ls':
                this.listServices();
                break;
            case 'status':
                this.checkStatus();
                break;
            case 'uname':
                if (args[1] === '-a') {
                    this.showSystemInfo();
                } else {
                    this.addLine('cassiopeia.piwo.org');
                }
                break;
            case 'whoami':
                this.addLine('guest');
                break;
            case 'date':
                this.addLine(new Date().toString());
                break;
            case 'echo':
                this.addLine(args.slice(1).join(' '));
                break;
            case 'uptime':
                const uptime = document.getElementById('uptime').textContent;
                this.addLine(`Czas działania: ${uptime}`);
                break;
            case 'login':
                this.addLine('Błąd: Brak uprawnień do logowania. Dostęp tylko dla administratorów.');
                break;
            case '':
                // Puste polecenie
                break;
            default:
                this.addLine(`bash: ${cmd}: nie znaleziono polecenia`);
        }
        
        // Dodaj nową pustą linię z kursorem
        this.addPrompt();
        
        // Przewiń do dołu
        this.output.scrollTop = this.output.scrollHeight;
    },
    
    // Dodawanie nowej linii tekstu
    addLine(text, className = '') {
        const line = document.createElement('div');
        line.className = `terminal-line ${className}`;
        line.textContent = text;
        
        // Usunięcie mrugającego kursora z ostatniej linii
        const lines = this.output.querySelectorAll('.terminal-line');
        if (lines.length > 0) {
            const lastLine = lines[lines.length - 1];
            if (lastLine.innerHTML.includes('<span class="blink">')) {
                this.output.removeChild(lastLine);
            }
        }
        
        this.output.appendChild(line);
    },
    
    // Dodawanie znaku zachęty z kursorem
    addPrompt() {
        const prompt = document.createElement('div');
        prompt.className = 'terminal-line';
        prompt.innerHTML = '~$ <span class="blink">▋</span>';
        this.output.appendChild(prompt);
    },
    
    // Czyszczenie terminala
    clear() {
        this.output.innerHTML = '';
    },
    
    // Wyświetlanie pomocy
    showHelp() {
        this.addLine('Dostępne polecenia:');
        this.addLine('  help           - Wyświetla tę pomoc');
        this.addLine('  ls             - Wyświetla dostępne usługi');
        this.addLine('  status         - Sprawdza status systemu');
        this.addLine('  uname -a       - Wyświetla informacje o systemie');
        this.addLine('  clear          - Czyści terminal');
        this.addLine('  whoami         - Pokazuje aktualnego użytkownika');
        this.addLine('  date           - Wyświetla aktualną datę i czas');
        this.addLine('  echo [tekst]   - Wyświetla podany tekst');
        this.addLine('  uptime         - Wyświetla czas działania systemu');
    },
    
    // Wyświetlanie listy usług
    listServices() {
        this.addLine('Dostępne usługi:');
        this.addLine('  ssh            - port 22    - [ACTIVE]');
        this.addLine('  http           - port 80    - [ACTIVE]');
        this.addLine('  https          - port 443   - [ACTIVE]');
        this.addLine('  mysql          - port 3306  - [PROTECTED]');
        this.addLine('  minecraft      - port 25565 - [INACTIVE]');
    },
    
    // Sprawdzanie statusu systemu
    checkStatus() {
        this.addLine('Status systemu:');
        this.addLine('  System: Online', 'success');
        this.addLine('  Obciążenie CPU: 12%', 'success');
        this.addLine('  Użycie pamięci: 34%', 'success');
        this.addLine('  Dysk: 23% zajęte', 'success');
        this.addLine('  Sieć: Aktywna', 'success');
        this.addLine('  Bezpieczeństwo: Poziom 2 (Standardowy)', 'warning');
    },
    
    // Wyświetlanie informacji o systemie
    showSystemInfo() {
        this.addLine('Linux cassiopeia.piwo.org 5.10.0-20-amd64 #1 SMP Debian 5.10.158-2 (2022-12-13) x86_64 GNU/Linux');
    }
};

// Inicjalizacja terminala po załadowaniu strony
document.addEventListener('DOMContentLoaded', function() {
    // Obsługa wprowadzania poleceń
    terminal.input.addEventListener('keydown', function(e) {
        if (e.key === 'Enter') {
            const command = this.value;
            terminal.processCommand(command);
            this.value = '';
        }
    });
    
    // Dodaj pierwszy prompt przy starcie
    if (terminal.output.querySelectorAll('.terminal-line').length === 0) {
        terminal.addPrompt();
    }
    
    // Ustawiamy focus na polu wprowadzania
    terminal.input.focus();
    
    // Utrzymanie focusu na polu wprowadzania
    document.addEventListener('click', function() {
        terminal.input.focus();
    });
    
    // Inicjalizacja licznika czasu działania
    updateUptime();
}); 