## How to run this workspace

This workspace is a forked Code - OSS setup with a convenient Docker-first launcher and web/desktop run options on Windows.

### Prerequisites

- Windows 10/11
- PowerShell
- Node.js 22.x and npm 10+ (`node -v`, `npm -v`)
- Git (optional)
- Docker Desktop (if you need containers running before the site)
- For Desktop/Electron build only: Visual Studio 2022 Build Tools with:
  - MSVC v143 x64/x86 build tools
  - MSVC v143 Spectre-mitigated libs
  - Windows 10/11 SDK

### Quickstart (recommended: web + Docker)

This starts Docker Desktop if needed, waits for readiness, optionally runs `docker compose up -d`, and serves the web build.

```powershell
cd D:\Wi-IDE
.\n+scripts\run-with-docker.ps1
```

Options:

- Serve a specific folder and port:

```powershell
.
scripts\run-with-docker.ps1 -FolderPath "D:\Wi-IDE" -Host 127.0.0.1 -Port 8082
```

- Use a specific compose file (or omit to auto-detect `docker-compose.{yml,yaml}` in repo root):

```powershell
.
scripts\run-with-docker.ps1 -ComposeFile .\docker-compose.yml
```

- Skip compose entirely:

```powershell
.
scripts\run-with-docker.ps1 -NoCompose
```

- BAT shim (same arguments supported):

```bat
scripts\run-with-docker.bat
```

### Web build (no Electron, no Docker)

Runs VS Code Web directly (no native modules required):

```powershell
cd D:\Wi-IDE
npx -y @vscode/test-web --host 127.0.0.1 --port 8082 --browserType none "D:\Wi-IDE"
```

Then open `http://127.0.0.1:8082`.

### Desktop app (Electron)

Requires native toolchain. After installing VS Build Tools components listed above:

```powershell
cd D:\Wi-IDE
.
scripts\code.bat
```

The first run will install dependencies, fetch Electron, compile sources, and launch the app.

### Troubleshooting

- Port already in use (`EADDRINUSE`): pass a different `--port` (e.g., `8083`).
- Internal Server Error in web-from-sources: ensure dependencies are installed. If native builds fail, prefer the web build using the command above or fix toolchain.
- `esbuild` or `@parcel/watcher` platform mismatch under `extensions\node_modules`: run `cd extensions && npm ci` to reinstall for Windows.
- `node-gyp` native build errors: install MSVC v143 Build Tools + Spectre-mitigated libs + Windows SDK.
- Slow first run: builds and downloads are expected; subsequent runs are much faster.

### Useful scripts and paths

- Launcher that ensures Docker then serves web: `scripts\run-with-docker.ps1`
- BAT wrapper: `scripts\run-with-docker.bat`
- Web (from sources): `scripts\code-web.bat`
- Server (headless backend mode): `scripts\code-server.bat`
- Desktop/Electron: `scripts\code.bat`

### Clean install

If dependencies get into a bad state:

```powershell
cd D:\Wi-IDE
Remove-Item node_modules -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item extensions\node_modules -Recurse -Force -ErrorAction SilentlyContinue
npm ci
cd extensions; npm ci; cd ..
```


