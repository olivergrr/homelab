#!/bin/bash
# Script to configure Caddy reverse proxy on RPi4 (tiny)
# Run this script FROM tiny, not from the main server

# Backup existing config
sudo cp /etc/caddy/Caddyfile /etc/caddy/Caddyfile.backup.$(date +%Y%m%d)

# Check if entries already exist
if grep -q "jellyfin.camarena.cc" /etc/caddy/Caddyfile; then
    echo "Jellyfin entry already exists"
else
    echo "Adding Jellyfin..."
    sudo tee -a /etc/caddy/Caddyfile > /dev/null << 'EOF'

jellyfin.camarena.cc {
    reverse_proxy 10.0.0.5:8096 {
        header_up X-Forwarded-For {remote_host}
        header_up X-Forwarded-Proto {scheme}
        header_up X-Real-IP {remote_host}
    }
    encode gzip
}
EOF
fi

if grep -q "requests.camarena.cc" /etc/caddy/Caddyfile; then
    echo "Jellyseerr entry already exists"
else
    echo "Adding Jellyseerr..."
    sudo tee -a /etc/caddy/Caddyfile > /dev/null << 'EOF'

requests.camarena.cc {
    reverse_proxy 10.0.0.5:5055 {
        header_up X-Forwarded-For {remote_host}
        header_up X-Forwarded-Proto {scheme}
        header_up X-Real-IP {remote_host}
    }
    encode gzip
}
EOF
fi

if grep -q "music.camarena.cc" /etc/caddy/Caddyfile; then
    echo "Navidrome entry already exists"
else
    echo "Adding Navidrome..."
    sudo tee -a /etc/caddy/Caddyfile > /dev/null << 'EOF'

music.camarena.cc {
    reverse_proxy 10.0.0.5:4533 {
        header_up X-Forwarded-For {remote_host}
        header_up X-Forwarded-Proto {scheme}
        header_up X-Real-IP {remote_host}
    }
    encode gzip
}
EOF
fi

echo ""
echo "Reloading Caddy..."
sudo systemctl reload caddy

echo ""
echo "Current Caddyfile:"
echo "=================="
sudo cat /etc/caddy/Caddyfile

echo ""
echo "Caddy status:"
sudo systemctl status caddy --no-pager

echo ""
echo "Done! Services should be accessible at:"
echo "  - https://jellyfin.camarena.cc"
echo "  - https://requests.camarena.cc"
echo "  - https://music.camarena.cc"
echo ""
echo "Note: Ensure DNS CNAME records point to camarena.cc in Cloudflare"
