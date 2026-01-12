# Homelab System Overview

This document provides a comprehensive reference of the homelab infrastructure.

## Architecture Diagram

```
                                    INTERNET
                                        |
                                        v
                        +-------------------------------+
                        |  RPi4 "tiny" (192.168.1.76)   |
                        |  - Caddy (reverse proxy)      |
                        |  - DuckDNS + Cloudflare DDNS  |
                        +-------------------------------+
                                        |
                                   WireGuard VPN
                                    (10.0.0.x)
                                        |
                                        v
+--------------------------------------------------------------------------------+
|                     MAIN SERVER "improv" (10.0.0.5)                            |
|                                                                                |
|  Hardware:                                                                     |
|  - CPU: AMD Ryzen 9 9950X (16 cores / 32 threads)                              |
|  - RAM: 96 GB                                                                  |
|  - GPU: NVIDIA GeForce RTX 5070 Ti (16 GB VRAM)                                |
|  - Storage: 3.7 TB NVMe (nvme0n1)                                              |
|                                                                                |
|  Network:                                                                      |
|  - LAN (WiFi): 192.168.0.106 (wlp9s0)                                          |
|  - WireGuard VPN: 10.0.0.5 (wg0)                                               |
|  - Docker bridges: 172.17-21.x.x                                               |
+--------------------------------------------------------------------------------+
```

## Main Server Specifications

| Component | Details |
|-----------|---------|
| Hostname | improv |
| OS | Ubuntu 24.04 LTS |
| Kernel | 6.14.0-37-generic |
| CPU | AMD Ryzen 9 9950X 16-Core (32 threads) |
| RAM | 96 GB |
| GPU | NVIDIA GeForce RTX 5070 Ti (16 GB VRAM) |
| Local IP | 192.168.0.106 |
| VPN IP | 10.0.0.5 |

## Storage Layout

| Partition | Size | Filesystem | Mount Point | Purpose |
|-----------|------|------------|-------------|---------|
| nvme0n1p1 | 1.1 GB | FAT32 | /boot/efi | EFI System |
| nvme0n1p2 | 2 GB | ext4 | /boot | Linux Boot |
| nvme0n1p3 | 95 GB | ext4 | / | Linux Root |
| nvme0n1p4 | 953 GB | ext4 | /home | Linux Home |
| nvme0n1p5 | 15 GB | swap | [SWAP] | Swap |
| nvme0n1p6 | 953 GB | NTFS | /mnt/data | **Shared Media Drive** |
| nvme0n1p7 | 16 MB | - | - | Microsoft Reserved |
| nvme0n1p8 | 1.7 TB | NTFS | - | Windows C: |
| nvme0n1p9 | 695 MB | NTFS | - | Windows Recovery |

### Shared Storage Notes

- **nvme0n1p6** (953 GB NTFS, label "Media") is the shared data partition
- UUID: `4F62B8747303D32A`
- Mounted at `/mnt/data` (fstab entry with ntfs3 driver)
- Accessible from both Linux and Windows (D:\ drive on Windows)
- Folder structure:
  ```
  /mnt/data/
  ├── media/
  │   ├── movies/
  │   ├── shows/
  │   ├── music/
  │   └── books/
  └── downloads/
      ├── complete/
      ├── incomplete/
      └── torrents/
  ```

## Services

### Docker Containers

| Service | Image | Port | Network |
|---------|-------|------|---------|
| mastodon-web | ghcr.io/mastodon/mastodon:v4.5.2 | 3000 | mastodon_external_network |
| mastodon-streaming | ghcr.io/mastodon/mastodon-streaming:v4.5.2 | 4000 | mastodon_external_network |
| mastodon-sidekiq | ghcr.io/mastodon/mastodon:v4.5.2 | - | mastodon_internal_network |
| mastodon-db | postgres:14-alpine | 5432 | mastodon_internal_network |
| mastodon-redis | redis:7-alpine | 6379 | mastodon_internal_network |
| devcontainer-libretranslate | libretranslate/libretranslate:v1.6.2 | 5000 | devcontainer_internal_network |
| devcontainer-es | elasticsearch-oss:7.10.2 | 9200 | devcontainer_internal_network |
| devcontainer-db | postgres:14-alpine | 5432 | devcontainer_internal_network |
| devcontainer-redis | redis:7-alpine | 6379 | devcontainer_internal_network |

### Systemd User Services

| Service | Application | Port | Config Location |
|---------|-------------|------|-----------------|
| lm-studio.service | LM Studio | 1234 | ~/.config/systemd/user/lm-studio.service |
| anythingllm.service | AnythingLLM Desktop | 3001 | ~/.config/systemd/user/anythingllm.service |

#### Service Management Commands

```bash
# LM Studio
systemctl --user status lm-studio
systemctl --user restart lm-studio
journalctl --user -u lm-studio -f

# AnythingLLM
systemctl --user status anythingllm
systemctl --user restart anythingllm
journalctl --user -u anythingllm -f
```

### Application Binaries

| Application | Location |
|-------------|----------|
| LM Studio | /opt/lm-studio.AppImage |
| AnythingLLM | /opt/anythingllm.AppImage |

## Raspberry Pi 4 Gateway (tiny)

| Property | Value |
|----------|-------|
| Hostname | tiny |
| Local IP | 192.168.1.76 |
| SSH | `ssh tiny` |
| Role | Reverse proxy & VPN gateway |

### Services on RPi4

| Service | Purpose |
|---------|---------|
| Caddy | Reverse proxy with automatic HTTPS |
| WireGuard | VPN server for external access |
| DuckDNS | Dynamic DNS updates (cron, every 5 min) |
| Cloudflare DDNS | Dynamic DNS updates (cron, every 5 min) |

### Caddyfile Location

```
/etc/caddy/Caddyfile
```

### Current Caddy Configuration

```caddyfile
camarena.cc {
    reverse_proxy 10.0.0.5:3000 {
        header_up X-Forwarded-For {remote_host}
        header_up X-Forwarded-Proto {scheme}
        header_up X-Real-IP {remote_host}
    }
    encode gzip
}
```

## Domains & DNS

| Domain | Provider | Purpose |
|--------|----------|---------|
| camarena.cc | Cloudflare | Primary domain (Mastodon) |
| olivergrr.com | (available) | Alternative domain |

### DNS Records

| Record | Type | Target | Service |
|--------|------|--------|---------|
| camarena.cc | A | (dynamic IP) | Mastodon |
| (planned) jellyfin.camarena.cc | A | (dynamic IP) | Jellyfin Media Server |

## Network Topology

```
Internet
    |
    v
[Public IP - Dynamic, updated via DDNS]
    |
    v
Router/Firewall (port forwarding)
    |
    +---> RPi4 (192.168.1.76) - Caddy reverse proxy
    |         |
    |         +---> WireGuard tunnel (10.0.0.x)
    |                   |
    v                   v
[LAN 192.168.0.x]   Main Server (10.0.0.5)
    |                   |
    +-------------------+
    |
Main Server (192.168.0.106)
```

## Media Server Stack

Configuration: `/home/olivergrr/Dev/homelab/media/`

| Service | Port | Purpose | Network |
|---------|------|---------|---------|
| Gluetun | - | VPN container (ProtonVPN WireGuard) | media_network |
| qBittorrent | 8080 | Torrent client (via VPN) | via gluetun |
| NZBGet | 6789 | Usenet client (via VPN) | via gluetun |
| Prowlarr | 9696 | Indexer manager | media_network |
| Sonarr | 8989 | TV show automation | media_network |
| Radarr | 7878 | Movie automation | media_network |
| Lidarr | 8686 | Music automation | media_network |
| Bazarr | 6767 | Subtitle management | media_network |
| Jellyfin | 8096 | Media streaming (GPU transcoding) | media_network |
| Navidrome | 4533 | Music streaming server | media_network |
| Jellyseerr | 5055 | Media requests | media_network |
| FlareSolverr | 8191 | Cloudflare bypass for indexers | media_network |
| Deunhealth | 9999 | Health monitoring | media_network |

### Media Server Commands

```bash
cd /home/olivergrr/Dev/homelab/media

# Start all services
docker compose up -d

# Stop all services
docker compose down

# View logs
docker compose logs -f [service]

# Update all images
docker compose pull && docker compose up -d

# Check VPN IP
docker exec gluetun wget -qO- http://ipinfo.io
```

### Bazarr Configuration

Bazarr requires manual setup after deployment:
1. Connect to Sonarr/Radarr (API keys from each app's Settings → General)
2. Create Language Profile (Settings → Languages → Add Spanish)
3. Enable subtitle providers (OpenSubtitles.com, Subdivx, Podnapisi)
4. Apply profile to existing content via Mass Edit

**Important:** Bazarr volume must match Sonarr/Radarr (`${DATA_PATH}:/data`)

## Windows Dual-Boot

The system dual-boots with Windows. Media is on shared NTFS partition:
- Linux: `/mnt/data`
- Windows: `D:\`

When booted into Windows:
- Docker containers don't run (no downloads, no *arr apps)
- Install Jellyfin Windows for local streaming only
- External access (`jellyfin.camarena.cc`) unavailable

## Planned Additions

### Spotify Integration (Spotisub)
- Import Spotify playlists to Navidrome
- GitHub: https://github.com/blastbeng/spotisub
- Integrates with Lidarr for missing tracks

### Music Discovery (Sonobarr)
- AI-powered artist discovery using LM Studio
- GitHub: https://github.com/dodelidoo-labs/sonobarr

### Future NAS Integration

When NAS is acquired:
- Move media storage from /mnt/data to NAS
- Mount NAS via NFS or SMB
- Update docker-compose volume paths

## Quick Reference

### SSH Connections

```bash
# Connect to RPi4
ssh tiny

# Connect with X forwarding (if needed)
ssh -X tiny
```

### Service URLs (Internal)

| Service | URL |
|---------|-----|
| Mastodon | http://localhost:3000 |
| LM Studio API | http://localhost:1234 |
| AnythingLLM | http://localhost:3001 |
| Jellyfin | http://localhost:8096 |
| qBittorrent | http://localhost:8080 |
| Prowlarr | http://localhost:9696 |
| Sonarr | http://localhost:8989 |
| Radarr | http://localhost:7878 |
| Lidarr | http://localhost:8686 |
| Bazarr | http://localhost:6767 |
| Jellyseerr | http://localhost:5055 |
| Navidrome | http://localhost:4533 |

### Service URLs (External via Caddy)

| Service | URL |
|---------|-----|
| Mastodon | https://camarena.cc |
| Jellyfin | https://jellyfin.camarena.cc |
| Jellyseerr | https://requests.camarena.cc |
| Navidrome | https://music.camarena.cc |

## Maintenance Notes

### Updating AppImages

```bash
# Stop service, replace AppImage, restart
systemctl --user stop <service>
sudo mv /path/to/new.AppImage /opt/<app>.AppImage
sudo chmod +x /opt/<app>.AppImage
systemctl --user start <service>
```

### Checking System Resources

```bash
# CPU/Memory
htop

# GPU
nvidia-smi

# Disk usage
df -h

# Docker containers
docker ps
```

---

*Last updated: January 2026*
