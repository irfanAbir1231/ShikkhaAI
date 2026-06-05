# ShikkhaAI — Complete Startup Guide

This guide covers starting all three services: **Backend**, **RAG**, and **Flutter Frontend** on your real Android device.

---

## Prerequisites

1. **Backend env file**: `backend/.env` exists with these settings:
   ```dotenv
   DATABASE_URL=sqlite:///./shikkhaai.db
   RAG_BASE_URL=http://localhost:8100/rag
   MOCK_MODE=false
   ```

2. **RAG env file**: `rag/.env` exists with:
   ```dotenv
   GEMINI_API_KEY="your-key-here"
   ```

3. **Flutter dependencies installed**:
   ```bash
   cd frontend && flutter pub get
   ```

4. **Android phone**: Connected via USB with **USB Debugging enabled**.

5. **Same WiFi**: Phone and computer must be on the same network (for LAN IP access).

---

## ⚠️ CRITICAL: Windows Firewall Fix

Before anything else, your phone **cannot reach the backend** unless Windows Firewall allows port 8000.

### Option A: Add Firewall Rule (Recommended — Run as Admin)

Open **PowerShell as Administrator** and run:

```powershell
netsh advfirewall firewall add rule name="ShikkhaAI Backend" dir=in action=allow protocol=tcp localport=8000
netsh advfirewall firewall add rule name="ShikkhaAI RAG" dir=in action=allow protocol=tcp localport=8100
```

Verify:
```powershell
netsh advfirewall firewall show rule name="ShikkhaAI Backend"
```

### Option B: ADB Reverse Tunnel (No Admin Needed)

If you can't run as admin, use ADB to tunnel through USB instead of WiFi:

```bash
# Forward phone's localhost:8000 → computer's localhost:8000
adb reverse tcp:8000 tcp:8000
adb reverse tcp:8100 tcp:8100
```

> If `adb` is not in your PATH, use Flutter's bundled adb (usually at `<flutter_sdk>\bin\cache\artifacts\platform-tools\adb.exe`).

If you use ADB reverse, you **must** start Flutter with `API_BASE_URL=http://127.0.0.1:8000` instead of your LAN IP.

---

## Step 1: Start the RAG Service

The RAG service **must** run on **Python 3.11** (torch/sentence-transformers don't work on 3.14).

Open **Terminal 1** (from repo root):

```bash
# Activate the RAG virtual environment (Python 3.11)
source .rag-venv/Scripts/activate

# Start the RAG server on port 8100
uvicorn rag_server:app --host 0.0.0.0 --port 8100
```

**Wait** for the embedding model to load (30–60 seconds). You'll see:
```
Loading weights: 100%|##########| 199/199 [...]
INFO:     Uvicorn running on http://0.0.0.0:8100
```

**Verify:**
```bash
curl http://127.0.0.1:8100/health
# Expected: {"status":"ok","service":"rag"}
```

Leave this terminal open.

---

## Step 2: Start the Backend

Open **Terminal 2** (from repo root):

```bash
# Run backend with uv
uv --directory backend run uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

**Wait** for startup. You'll see:
```
2026-05-26 ... - shikkhaai - INFO - ShikkhaAI backend starting up — mock_mode=False
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8000
```

**Verify:**
```bash
curl http://127.0.0.1:8000/health
# Expected: {"success":true,"data":{"status":"ok","mock_mode":false},"error":null}
```

Leave this terminal open.

---

## Step 3: Find Your Computer's LAN IP

Open **Terminal 3** and run:

```bash
ipconfig | grep "IPv4"
```

Look for your WiFi adapter's IP, e.g.:
```
IPv4 Address. . . . . . . . . . . : 192.168.10.168
```

**Save this IP.** You'll use it in the Flutter command.

> If using **ADB reverse** (Option B), use `127.0.0.1` instead.

---

## Step 4: Start Flutter on Your Android Device

Open **Terminal 3** (from `frontend/` directory):

### If you used Firewall Option A (WiFi):

Replace `192.168.10.168` with your actual LAN IP from Step 3.

```bash
cd frontend
flutter run -d fccddc6b0404 --dart-define=API_BASE_URL=http://192.168.10.168:8000
```

### If you used ADB Reverse Option B (USB tunnel):

```bash
cd frontend
flutter run -d fccddc6b0404 --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

**First build takes 3–5 minutes.** Wait for:
```
√ Built build\app\outputs\flutter-apk\app-debug.apk
Installing build\app\outputs\flutter-apk\app-debug.apk...
Syncing files to device M2004J19C...
```

The app will launch on your phone. **Leave this terminal open** — it's your hot-reload connection.

---

## Quick Reference — All Commands

### Terminal 1 — RAG
```bash
cd <repo-root>
source .rag-venv/Scripts/activate
uvicorn rag_server:app --host 0.0.0.0 --port 8100
```

### Terminal 2 — Backend
```bash
cd <repo-root>
uv --directory backend run uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

### Terminal 3 — Flutter (WiFi)
```bash
cd <repo-root>/frontend
flutter run -d fccddc6b0404 --dart-define=API_BASE_URL=http://<YOUR_LAN_IP>:8000
```

### Terminal 3 — Flutter (ADB Reverse)
```bash
cd <repo-root>/frontend
flutter run -d fccddc6b0404 --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

---

## Verification Checklist

| Check | Command | Expected |
|-------|---------|----------|
| RAG running | `curl http://127.0.0.1:8100/health` | `{"status":"ok","service":"rag"}` |
| Backend running | `curl http://127.0.0.1:8000/health` | `mock_mode: false` |
| Phone can reach backend | Open phone browser → `http://<LAN_IP>:8000/health` | Same JSON response |
| Flutter built | App opens on phone | Splash screen appears |

> **Phone browser test is important!** Before trying registration, open Chrome on your phone and navigate to `http://192.168.10.168:8000/health`. If you see a JSON response, the network path is clear. If it times out, the firewall is still blocking.

---

## Troubleshooting

### "Connection refused" or timeout on phone

1. **Firewall not open** → Run the PowerShell admin command from Step 0.
2. **Wrong IP** → Re-run `ipconfig` and confirm the IP matches.
3. **Different WiFi** → Phone and computer must be on the same router/network.
4. **Backend not bound to 0.0.0.0** → Make sure you used `--host 0.0.0.0`.

### Registration spinner never stops

This means the request is timing out. Check:
1. Can the phone reach `http://<LAN_IP>:8000/health` in a browser?
2. Is the backend terminal showing any requests? (It should log each request.)
3. Check Flutter logs: press `c` in the `flutter run` terminal to clear, then try registration again.

### "No connected devices found"

1. Unplug and re-plug USB.
2. On phone: Settings → Developer Options → USB Debugging → toggle off/on.
3. Trust the computer when the dialog appears on the phone.
4. Run `flutter devices` to verify.

### RAG fails to start

Make sure `.rag-venv` is activated and Python 3.11 is used:
```bash
python --version  # Should show 3.11.x
```

---

## Stopping Everything

To stop all servers:

1. **Flutter**: Press `q` in the Flutter terminal, or `Ctrl+C`.
2. **Backend**: `Ctrl+C` in Terminal 2.
3. **RAG**: `Ctrl+C` in Terminal 1.

Or run this in PowerShell to force-kill all related processes:
```powershell
Get-Process | Where-Object {$_.ProcessName -match 'python|uvicorn|dart'} | Stop-Process -Force
```
