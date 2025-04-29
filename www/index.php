<!-- index.html -->
<!DOCTYPE html>
<html lang="pl">
<head>
  <meta charset="UTF-8">
  <title>Cassiopeia Homelab</title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-900 text-white font-sans min-h-screen p-6 overflow-y-auto">

  <h1 class="text-4xl font-bold mb-10 text-center mt-4">🚀 Cassiopeia Homelab</h1>

  <h2 class="text-2xl font-semibold mt-12 mb-4 text-center">🧩 Usługi lokalne</h2>
  <div id="services" class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6 w-full max-w-6xl mx-auto"></div>

  <h2 class="text-2xl font-semibold mt-12 mb-4 text-center">🌐 Sieć lokalna / Sprzęt</h2>
  <div id="hosts" class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6 w-full max-w-6xl mx-auto"></div>

  <h2 class="text-2xl font-semibold mt-12 mb-4 text-center">📦 Zewnętrzne serwisy</h2>
  <div id="external" class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6 w-full max-w-6xl mx-auto"></div>

  <footer class="mt-12 text-sm text-gray-500 text-center">
    cassiopeia.local &copy; 2025 — live status co 60s
  </footer>

  <script>
    async function loadServices() {
      const container = document.getElementById('services');
      container.innerHTML = '';

      let services = [];

      try {
        const response = await fetch('services.json');
        services = await response.json();
      } catch (err) {
        const errorCard = document.createElement('div');
        errorCard.className = 'bg-gray-800 rounded-xl p-3 text-sm text-red-400 shadow block';
        errorCard.textContent = 'Błąd ładowania listy usług 😥';
        container.appendChild(errorCard);
        return;
      }

      const cards = {};

      services.forEach(service => {
        const card = document.createElement('a');
        card.href = service.https ? `https://${service.host}:${service.port}${service.path || '/'}` : `http://${service.host}:${service.port}${service.path || '/'}`;
        card.target = '_blank';
        card.className = `bg-gray-800 rounded-xl p-3 text-sm transition shadow block hover:ring-2`;

        card.innerHTML = `
          <h2 class="text-base font-semibold mb-1">${service.name}</h2>
          <p class="text-gray-400 text-xs mb-1">${card.href}</p>
          <p class="text-xs text-gray-400">Status: sprawdzanie...</p>
        `;

        container.appendChild(card);
        cards[service.id] = card;
      });

      try {
        const res = await fetch('status.php');
        const statuses = await res.json();

        statuses.forEach(status => {
          const card = cards[status.id];
          if (card) {
            const statusEl = card.querySelector('p:last-child');
            statusEl.textContent = status.online ? 'Status: Online ✅' : 'Status: Offline ❌';
            statusEl.classList.replace('text-gray-400', status.online ? 'text-green-400' : 'text-red-400');
          }
        });
      } catch (err) {
        Object.values(cards).forEach(card => {
          const status = card.querySelector('p:last-child');
          status.textContent = 'Status: Błąd ❌';
          status.classList.replace('text-gray-400', 'text-red-400');
        });
      }
    }

    async function loadHosts() {
      const container = document.getElementById('hosts');
      container.innerHTML = '';

      try {
        const response = await fetch('hosts.json');
        const hosts = await response.json();

        hosts.forEach(host => {
          const card = document.createElement('a');
          card.href = host.name === 'Internet (Cloudflare)' ? '#' : `http://${host.ip}`;
          card.target = '_blank';
          card.className = 'bg-gray-800 rounded-xl p-3 text-sm transition shadow block hover:ring-2';

          card.innerHTML = `
            <h2 class="text-base font-semibold mb-1">${host.name}</h2>
            <p class="text-gray-400 text-xs mb-1">${host.ip}</p>
            <p class="text-sm text-gray-400">Status: sprawdzanie...</p>
          `;

          container.appendChild(card);

          setTimeout(() => {
            fetch(`ping.php?ip=${host.ip}`)
              .then(res => res.json())
              .then(data => {
                const status = card.querySelector('p:last-child');
                status.textContent = data.online ? 'Status: Online ✅' : 'Status: Offline ❌';
                status.classList.replace('text-gray-400', data.online ? 'text-green-400' : 'text-red-400');
              })
              .catch(() => {
                const status = card.querySelector('p:last-child');
                status.textContent = 'Status: Błąd ❌';
                status.classList.replace('text-gray-400', 'text-red-400');
              });
          }, 10);
        });
      } catch (err) {
        // brak komunikatu błędu
      }
    }

    async function loadExternal() {
      const container = document.getElementById('external');
      container.innerHTML = '';

      try {
        const response = await fetch('external.json');
        const hosts = await response.json();

        hosts.forEach(host => {
          const card = document.createElement('a');
          card.href = host.url;
          card.target = '_blank';
          card.className = 'bg-gray-800 rounded-xl p-3 text-sm transition shadow block hover:ring-2';

          card.innerHTML = `
            <h2 class="text-base font-semibold mb-1">${host.name}</h2>
            <p class="text-gray-400 text-xs mb-1">${host.url}</p>
            <p class="text-sm text-gray-400">Status: sprawdzanie...</p>
          `;

          container.appendChild(card);

          setTimeout(() => {
            fetch(`ping.php?ip=${host.ip}`)
              .then(res => res.json())
              .then(data => {
                const status = card.querySelector('p:last-child');
                status.textContent = data.online ? 'Status: Online ✅' : 'Status: Offline ❌';
                status.classList.replace('text-gray-400', data.online ? 'text-green-400' : 'text-red-400');
              })
              .catch(() => {
                const status = card.querySelector('p:last-child');
                status.textContent = 'Status: Błąd ❌';
                status.classList.replace('text-gray-400', 'text-red-400');
              });
          }, 10);
        });
      } catch (err) {
        // brak komunikatu błędu jeśli external.json nie istnieje
      }
    }

    loadServices();
    loadHosts();
    loadExternal();
    setInterval(loadServices, 60000);
    setInterval(loadHosts, 60000);
    setInterval(loadExternal, 60000);
  </script>

</body>
</html>
