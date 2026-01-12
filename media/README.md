# Media Server Stack

Complete media server setup with VPN-protected downloads, automated media management, and streaming.

## How It Works - The Big Picture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           YOUR MEDIA SERVER                                  │
│                                                                              │
│  ┌─────────────┐      ┌─────────────┐      ┌─────────────┐                  │
│  │   Jellyfin  │◄─────│   Sonarr    │◄─────│  Prowlarr   │◄── Indexers     │
│  │  (streaming)│      │   (series)  │      │ (search)    │    (1337x, etc) │
│  └─────────────┘      └─────────────┘      └─────────────┘                  │
│         ▲                    │                    │                          │
│         │                    ▼                    │                          │
│         │             ┌─────────────┐             │                          │
│  ┌──────┴──────┐      │   Radarr    │◄────────────┘                          │
│  │    Media    │      │  (movies)   │                                        │
│  │   Files     │      └─────────────┘                                        │
│  │ /mnt/data/  │             │                                               │
│  │   media/    │             ▼                                               │
│  └─────────────┘      ┌─────────────┐      ┌─────────────┐                  │
│         ▲             │ qBittorrent │◄─────│   Gluetun   │◄── Internet      │
│         │             │ (downloads) │      │    (VPN)    │    (Protected)   │
│         │             └─────────────┘      └─────────────┘                  │
│         │                    │                                               │
│         └────────────────────┘                                               │
│              Files moved after download                                      │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Component Explanation

### 1. Gluetun (VPN Container)
**What it does:** Creates a secure VPN tunnel to the internet using ProtonVPN WireGuard.

**Why it matters:**
- All torrent traffic goes through the VPN
- Your real IP is hidden from torrent peers
- Your ISP cannot see what you download

**Protocol:** WireGuard (faster and more stable than OpenVPN)

**Port:** Internal only (other containers connect through it)

---

### 2. qBittorrent (Torrent Client)
**What it does:** Downloads torrent files.

**How it connects:** Routes ALL traffic through Gluetun (VPN).

**Port:** 8080 (WebUI)

**Workflow:**
1. Receives download request from Sonarr/Radarr
2. Downloads file through VPN tunnel
3. Saves to `/downloads/complete`
4. Notifies Sonarr/Radarr when done

---

### 3. Prowlarr (Indexer Manager)
**What it does:** Searches torrent sites (indexers) for content.

**Port:** 9696

**Workflow:**
1. You search for "Breaking Bad" in Sonarr
2. Sonarr asks Prowlarr to search
3. Prowlarr searches 1337x, TPB, EZTV, etc.
4. Returns results to Sonarr

**Connected to:** Sonarr, Radarr, Lidarr (via API)

---

### 4. FlareSolverr (Cloudflare Bypass)
**What it does:** Bypasses Cloudflare protection on torrent sites.

**Port:** 8191

**Why needed:** Many torrent sites use Cloudflare to block bots. FlareSolverr solves the CAPTCHA automatically.

---

### 5. Sonarr (TV Series Manager)
**What it does:** Automates TV series downloads.

**Port:** 8989

**Workflow:**
1. You add a series (e.g., "Breaking Bad")
2. You click Search or set to Monitor
3. Sonarr asks Prowlarr for torrents
4. Picks the best quality match
5. Sends to qBittorrent
6. When done, moves/renames file to `/data/media/shows/`
7. Jellyfin detects the new file

**Features:**
- Automatic quality upgrades
- Season packs or individual episodes
- Release date monitoring

---

### 6. Radarr (Movie Manager)
**What it does:** Same as Sonarr, but for movies.

**Port:** 7878

**Saves to:** `/data/media/movies/`

---

### 7. Lidarr (Music Manager)
**What it does:** Same as Sonarr, but for music.

**Port:** 8686

**Saves to:** `/data/media/music/`

---

### 8. Bazarr (Subtitle Manager)
**What it does:** Automatically downloads subtitles for your media.

**Port:** 6767

**Workflow:**
1. Monitors Sonarr/Radarr libraries
2. When new media appears, searches for subtitles
3. Downloads matching subtitles (Spanish, English, etc.)

**Configuration Required:**
1. Connect to Sonarr/Radarr (Settings → Sonarr/Radarr with API keys)
2. Create Language Profile (Settings → Languages → Add Spanish)
3. Enable Providers (Settings → Providers):
   - OpenSubtitles.com (requires free account)
   - Subdivx (Spanish/Latino)
   - Podnapisi, Argenteam, Subf2m

**Path Mapping:** Bazarr uses same volume as Sonarr/Radarr (`/data`) so no mapping needed.

**Manual Search:** Wanted → click 🔍 on any episode/movie to search manually.

---

### 9. Jellyfin (Media Server)
**What it does:** Streams your media (movies, TV shows) to any device.

**Port:** 8096 (local), 8920 (HTTPS)

**External URL:** https://jellyfin.camarena.cc

**Features:**
- Web interface, mobile apps, TV apps
- Hardware transcoding (uses your RTX 5070 Ti)
- Multiple users with parental controls
- Watch progress sync across devices

---

### 10. Navidrome (Music Streaming Server)
**What it does:** Streams your music library to any device.

**Port:** 4533

**External URL:** https://music.camarena.cc

**Why use Navidrome instead of Jellyfin for music?**
- Specialized for music with better organization
- Supports Subsonic API (works with many apps)
- Lighter and faster for music-only streaming

**Compatible Apps:**
- **Android:** DSub, Ultrasonic, Symfonium
- **iOS:** play:Sub, Amperfy
- **Desktop:** Sonixd, Sublime Music

**Music Flow:**
```
Lidarr downloads music → /data/media/music → Navidrome scans → Stream anywhere
```

---

### 11. Jellyseerr (Request Manager)
**What it does:** Lets users request movies/series without accessing Sonarr/Radarr directly.

**Port:** 5055

**External URL:** https://requests.camarena.cc

**Use case:** Share with family/friends - they request, you approve, it downloads automatically.

---

### 12. Deunhealth (Health Monitor)
**What it does:** Monitors container health and restarts unhealthy containers.

**Port:** 9999

---

### 13. NZBGet (Usenet Downloader)
**What it does:** Downloads from Usenet (alternative to torrents).

**Port:** 6789

**Note:** Requires paid Usenet provider subscription. Currently inactive until configured.

---

## Complete Workflow Example

**"I want to watch Breaking Bad":**

1. **You** → Go to Sonarr (localhost:8989)
2. **You** → Add "Breaking Bad", click Search
3. **Sonarr** → Asks Prowlarr to find torrents
4. **Prowlarr** → Searches 1337x, EZTV via FlareSolverr
5. **Prowlarr** → Returns results to Sonarr
6. **Sonarr** → Picks best quality, sends to qBittorrent
7. **qBittorrent** → Downloads through Gluetun VPN
8. **qBittorrent** → Completes, notifies Sonarr
9. **Sonarr** → Moves file to `/data/media/shows/Breaking Bad/Season 1/`
10. **Bazarr** → Detects new episode, downloads Spanish subtitles
11. **Jellyfin** → Detects new file in library
12. **You** → Watch on https://jellyfin.camarena.cc

---

## Security Considerations

### What's Protected

| Component | Protection Level | Details |
|-----------|------------------|---------|
| Torrent Traffic | ✅ High | All traffic through ProtonVPN |
| Your IP | ✅ Hidden | Peers only see VPN IP |
| ISP Visibility | ✅ Hidden | ISP sees encrypted VPN traffic only |
| Local Network | ⚠️ Medium | Containers isolated in Docker network |

### What Happens If You Download a Virus?

**The Risk:**
Torrents can contain malware. A malicious file could be disguised as a movie/series.

**Your Protections:**

1. **Docker Isolation:**
   - Containers run in isolated environments
   - A virus in `/mnt/data` cannot easily access your system
   - Containers don't have access to your home folder or system files

2. **Limited Scope:**
   - qBittorrent only writes to `/mnt/data/downloads`
   - Sonarr/Radarr only write to `/mnt/data/media`
   - Virus would be contained to the NTFS partition

3. **File Types:**
   - Sonarr/Radarr only import video files (.mkv, .mp4, etc.)
   - Executable files (.exe) are ignored
   - Reduces risk of accidentally running malware

4. **What Could Go Wrong:**
   - Malicious video file exploiting Jellyfin vulnerability (rare)
   - If you manually open files from `/mnt/data` on Windows

**Recommendations:**

1. **Don't open downloaded files directly** - Always stream through Jellyfin
2. **Keep containers updated** - `docker compose pull && docker compose up -d`
3. **Use reputable uploaders** - Check torrent comments/ratings
4. **Avoid suspicious releases** - If a "cam" version is 50GB, it's suspicious
5. **Windows access** - Run antivirus scan on `/mnt/data` periodically when in Windows

### Network Security

```
Internet
    │
    ▼
┌─────────────────────────────────────┐
│  RPi4 (Caddy) - Only ports 80/443   │
│  - Jellyfin, Jellyseerr & Navidrome │
│  - HTTPS with Let's Encrypt         │
└─────────────────────────────────────┘
    │
    ▼ (WireGuard VPN)
┌─────────────────────────────────────┐
│  Main Server                        │
│  - All *arr apps local only         │
│  - qBittorrent local only           │
│  - No direct internet exposure      │
└─────────────────────────────────────┘
```

**What's exposed to internet:**
- Jellyfin (streaming) - via Caddy reverse proxy
- Jellyseerr (requests) - via Caddy reverse proxy
- Navidrome (music) - via Caddy reverse proxy

**What's NOT exposed:**
- qBittorrent, Sonarr, Radarr, Prowlarr, etc.
- Only accessible from your local network

---

## Quick Reference

### URLs

| Service | Local URL | External URL |
|---------|-----------|--------------|
| Jellyfin | http://localhost:8096 | https://jellyfin.camarena.cc |
| Navidrome | http://localhost:4533 | https://music.camarena.cc |
| Jellyseerr | http://localhost:5055 | https://requests.camarena.cc |
| qBittorrent | http://localhost:8080 | - |
| Sonarr | http://localhost:8989 | - |
| Radarr | http://localhost:7878 | - |
| Prowlarr | http://localhost:9696 | - |
| Lidarr | http://localhost:8686 | - |
| Bazarr | http://localhost:6767 | - |

### Common Commands

```bash
cd ~/Dev/homelab/media

# Start all services
docker compose up -d

# Stop all services
docker compose down

# Restart a specific service
docker compose restart sonarr

# View logs
docker compose logs -f sonarr

# Update all containers
docker compose pull && docker compose up -d

# Check VPN IP (should NOT be your real IP)
docker exec gluetun wget -qO- http://ipinfo.io

# Check container health
docker ps
```

### Folder Structure

```
/mnt/data/                    # Shared NTFS partition (accessible from Windows)
├── media/
│   ├── movies/               # Radarr imports here
│   ├── shows/                # Sonarr imports here
│   ├── music/                # Lidarr imports here
│   └── books/                # (future use)
└── downloads/
    ├── complete/             # Finished downloads
    ├── incomplete/           # In-progress downloads
    └── torrents/             # .torrent files

~/Dev/homelab/media/config/   # Container configurations (Linux only)
├── sonarr/
├── radarr/
├── jellyfin/
└── ...
```

### Troubleshooting

**VPN not working:**
```bash
docker logs gluetun
docker exec gluetun wget -qO- http://ipinfo.io
```

**Downloads stuck/stalled:**
- Check qBittorrent trackers tab
- May be no seeders - try different release
- Check VPN is connected

**Indexer errors:**
- Check FlareSolverr is running
- Ensure indexer has flaresolverr tag
- Some sites may be temporarily down

**Jellyfin not finding media:**
- Check files are in correct folders
- Library scan: Dashboard → Scheduled Tasks → Scan Library
- Check file permissions

**Bazarr path mapping error:**
- Ensure Bazarr volume is `${DATA_PATH}:/data` (same as Sonarr/Radarr)
- Recreate container: `docker compose up -d bazarr --force-recreate`

---

## Windows Dual-Boot Setup

The media is stored on a shared NTFS partition (`/mnt/data` in Linux, `D:\` in Windows). When booted into Windows, the Docker containers don't run.

### Streaming from Windows

For **viewing only** (no downloads), install Jellyfin natively on Windows:

1. Download from https://jellyfin.org/downloads/windows
2. Install and configure libraries:
   - Movies: `D:\media\movies`
   - Shows: `D:\media\shows`
   - Music: `D:\media\music`
3. Enable NVENC transcoding (Dashboard → Playback → Transcoding)

**Notes:**
- Linux and Windows Jellyfin instances are separate (different watch history/users)
- External access (`jellyfin.camarena.cc`) only works when Linux is running
- GPU transcoding works natively on Windows with RTX 5070 Ti

---

## Planned Features / Roadmap

### Spotify Playlist Sync
- [ ] **Spotisub**: Import Spotify playlists to Navidrome
  - GitHub: https://github.com/blastbeng/spotisub
  - Works with Subsonic API (Navidrome compatible)
  - Integrates with Lidarr to download missing tracks
  - Workflow: Spotify playlists → Spotisub → Lidarr downloads → Navidrome streams

### Music Discovery (AI-Powered)
- [ ] **Sonobarr**: Discover new artists based on your library
  - GitHub: https://github.com/dodelidoo-labs/sonobarr
  - Uses Last.fm similarity or LM Studio (local AI)
  - Integrates with Lidarr for automated additions

### Karaoke Video Automation (Future Project)
- [ ] **Ultimate Vocal Remover integration**
  - App: https://ultimatevocalremover.com/
  - Automatically remove vocals from downloaded songs
- [ ] **Karaoke video pipeline**
  - Generate videos with lyrics synced to instrumental tracks
  - Host karaoke videos in Jellyfin
  - Workflow: Lidarr → UVR (vocal removal) → Lyrics sync → Video generation → Jellyfin

---

*Last updated: January 2026*
