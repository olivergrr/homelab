# Homelab

Personal homelab infrastructure running on a dual-boot Linux/Windows system with Raspberry Pi 4 as gateway.

## Architecture

```
Internet
    │
    ▼
┌─────────────────────────────────────┐
│   RPi4 "tiny" (Gateway)             │
│   - Caddy reverse proxy (HTTPS)     │
│   - WireGuard VPN endpoint          │
│   - DuckDNS + Cloudflare DDNS       │
└─────────────────┬───────────────────┘
                  │ WireGuard (10.0.0.x)
                  ▼
┌─────────────────────────────────────┐
│   Main Server "improv"              │
│   - Ryzen 9 9950X, 96GB RAM         │
│   - RTX 5070 Ti (GPU transcoding)   │
│   - Docker containers               │
│   - Media server stack              │
└─────────────────────────────────────┘
```

## Services

### External Access (via Caddy)
| Service | URL |
|---------|-----|
| Mastodon | https://camarena.cc |
| Jellyfin | https://jellyfin.camarena.cc |
| Jellyseerr | https://requests.camarena.cc |
| Navidrome | https://music.camarena.cc |

### Media Stack
Complete automated media server with VPN-protected downloads.

See [media/README.md](media/README.md) for detailed documentation.

| Component | Purpose |
|-----------|---------|
| Gluetun | VPN container (ProtonVPN WireGuard) |
| qBittorrent | Torrent client |
| Prowlarr | Indexer manager |
| Sonarr | TV show automation |
| Radarr | Movie automation |
| Lidarr | Music automation |
| Bazarr | Subtitle management |
| Jellyfin | Video streaming |
| Navidrome | Music streaming |
| Jellyseerr | Media requests |
| FlareSolverr | Cloudflare bypass |

### AI/LLM Services
| Service | Purpose |
|---------|---------|
| LM Studio | Local LLM inference |
| AnythingLLM | LLM chat interface |

## Quick Start

```bash
cd media
cp .env.example .env
# Edit .env with your settings (VPN credentials, paths)
docker compose up -d
```

## Documentation

- [System Overview](SYSTEM_OVERVIEW.md) - Complete system documentation
- [Media Stack](media/README.md) - Media server setup and configuration

## License

Personal project - feel free to use as reference.
