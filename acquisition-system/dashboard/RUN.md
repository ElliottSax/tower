# Running the DealSourceAI Dashboard

## Quick Start

### Terminal 1: Start the Dashboard
```bash
cd /mnt/e/projects/acquisition-system/dashboard
npm run dev
```

Wait for the message:
```
✓ Ready in 2.5s
○ Local:        http://localhost:3000
○ Network:      http://192.168.x.x:3000
```

### Terminal 2 (or Browser): Access the Dashboard
```bash
# Option 1: In your browser
http://localhost:3000/client

# Option 2: Test with curl
curl http://localhost:3000/client
```

---

## What You'll See

### Pages Available:
- http://localhost:3000/client - Dashboard Home
- http://localhost:3000/client/leads - Leads Page
- http://localhost:3000/client/campaigns - Campaigns Page
- http://localhost:3000/client/responses - Responses Page
- http://localhost:3000/client/analytics - Analytics Page
- http://localhost:3000/client/settings - Settings Page

---

## Troubleshooting

### Port 3000 already in use?
```bash
# Find what's using port 3000
lsof -ti:3000

# Kill it
kill -9 $(lsof -ti:3000)

# Or use a different port
PORT=3001 npm run dev
```

### Dependencies not installed?
```bash
npm install
```

### Build errors?
```bash
# Clean and rebuild
rm -rf .next
npm run dev
```

---

## WSL2 Access from Windows

If you're using WSL2 and want to access from Windows browser:

1. In WSL terminal: `ip addr show eth0 | grep inet`
2. Copy the IP address (e.g., 172.x.x.x)
3. In Windows browser: `http://172.x.x.x:3000/client`

Or use: `http://localhost:3000/client` (WSL2 usually forwards localhost)

---

## Production Build

```bash
# Build for production
npm run build

# Start production server
npm start

# Access at http://localhost:3000/client
```

---

## Docker

```bash
# From project root
docker compose --profile dashboard up -d

# Access at http://localhost:3001/client
```

---

## Demo Screenshots

Once running, take screenshots for:
- Sales decks
- Investor pitches
- Marketing materials
- Client onboarding docs

All pages have realistic mock data ready to demo!

---

**Dashboard is ready. Just run `npm run dev` and visit http://localhost:3000/client** 🚀
