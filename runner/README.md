# GitHub Actions Runner Setup

## Übersicht

Dieses Setup verwendet **NixOS systemd Services** + **Docker Compose** + `.env` Dateien für Secrets.

## Setup

### 1. Kopiere das Template

```bash
cp github-runner.nix.template hosts/gateway/github-runner.nix
```

### 2. Konfiguriere die Nix-Config

Passe `hosts/gateway/github-runner.nix` an:
```nix
let
  hostName = "gateway";              # Name des Hosts
  runnerLabels = "gateway,self-hosted";
  workDir = "/home/admin/docker/runner";
  composeFile = "compose.yaml";
  runnerUser = "admin";
in
```

**Wichtig:** Der `workDir` muss auf den `runner/` Ordner zeigen, damit docker-compose die `.env` Datei findet!

### 3. Importiere in default.nix

Füge in `hosts/gateway/default.nix` hinzu:
```nix
{
  imports = [
    ./github-runner.nix
  ];
}
```

### 4. Erstelle die `.env` Datei

```bash
cd /home/admin/docker/runner
cat > .env << 'EOF'
GITHUB_RUNNER_TOKEN=<runner-token-hier>
GITHUB_RUNNER_REPO_URL=https://github.com/JohanHaas/homelab-docker
RUNNER_LABELS=gateway,self-hosted
EOF
chmod 644 .env
```

**Token generieren:**
1. GitHub → Repo → Settings → Actions → Runners
2. **"New self-hosted runner"** klicken
3. Token nach `--token` kopieren
4. In `.env` eintragen

**Wichtig:**
- `.env` ist in `.gitignore` — wird nicht committed
- Token ist kurzlebig (~1 Stunde) — bei Problemen neuen generieren
- Permissions: `644` (nicht `600`!) damit Docker es lesen kann

### 5. Deploye die Konfiguration

```bash
sudo nixos-rebuild switch
```

### 6. Status prüfen

```bash
sudo systemctl status <hostName>-runner
sudo journalctl -u <hostName>-runner -f
```

Beispiel für `hostName = "gateway"`:
```bash
sudo systemctl status gateway-runner
sudo journalctl -u gateway-runner -f
```

## Environment-Variablen

Diese Variablen werden aus der `.env` Datei geladen:

| Variable | Beispiel | Beschreibung |
|----------|----------|-------------|
| `GITHUB_RUNNER_TOKEN` | `Aba1B2cD3...` | Runner Registration Token (von GitHub) |
| `GITHUB_RUNNER_REPO_URL` | `https://github.com/org/repo` | Repository URL |
| `RUNNER_LABELS` | `gateway,self-hosted` | Komma-getrennte Labels für Runner |

## Sicherheit

- ✅ `.env` Datei hat `644` Permissions (lesbar für alle, änderbar nur Owner)
- ✅ Secrets stehen NICHT in der Nix-Config
- ✅ Secrets stehen NICHT in Git (`.gitignore` schützt sie)
- ✅ Pro Host eine separate `.env` Datei
- ✅ Docker-Compose lädt `.env` automatisch

## Quick-Start (für Homelab)

Falls du bereits `gateway` erfolgreich konfiguriert hast, für `homelab`:

1. Kopiere das Template: `cp github-runner.nix.template hosts/homelab/github-runner.nix`
2. Ändere `hostName = "homelab"` und `runnerLabels = "homelab,self-hosted"`
3. Importiere in `hosts/homelab/default.nix`
4. Erstelle `.env` mit neuem Token
5. Deploy: `nixos-rebuild switch --flake .#homelab --target-host homelab`

## Troubleshooting

**Problem: `Invalid configuration provided for token`**
- Token ist abgelaufen oder falsch → neuen Token generieren
- Permissions falsch → `chmod 644 .env`

**Problem: `.env` wird nicht geladen**
- Check: `docker compose config | grep GITHUB_RUNNER`
- `workDir` muss auf `runner/` zeigen!

**Logs prüfen:**
```bash
sudo journalctl -u gateway-runner -n 50 -f
docker compose -f /home/admin/docker/runner/compose.yaml logs -f
```
