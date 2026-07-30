FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# --- Base desktop + VNC deps + Tor Browser's runtime shared libraries ---
# NOTE: firefox-esr is a Debian package name and does not exist in Ubuntu's
# repos — Tor Browser ships its own bundled Firefox binary, so we don't need
# a Firefox package at all. We just need the shared libs that bundled binary
# links against at runtime.
RUN apt-get update && apt-get install -y --no-install-recommends \
    xvfb \
    fluxbox \
    x11vnc \
    websockify \
    git \
    wget \
    xz-utils \
    xterm \
    ca-certificates \
    supervisor \
    locales \
    xdg-utils \
    libgtk-3-0 \
    libx11-xcb1 \
    libdbus-glib-1-2 \
    libxtst6 \
    libasound2 \
    libnss3 \
    libxss1 \
    && rm -rf /var/lib/apt/lists/*

# --- Clone a pinned noVNC release (not master) so builds are reproducible ---
# Check https://github.com/novnc/noVNC/releases for the latest tag if you want to bump this.
ARG NOVNC_VERSION=v1.7.0
RUN git clone --branch ${NOVNC_VERSION} --depth 1 https://github.com/novnc/noVNC.git /opt/noVNC

# --- Download Tor Browser (English, Linux x86_64) ---
# Pin a version explicitly rather than "latest" so builds are reproducible.
# Verify against https://dist.torproject.org/torbrowser/ before bumping —
# old versions get deleted from this index once superseded, which is what
# caused the previous wget failure (exit code 8 = HTTP error, i.e. 404).
ARG TOR_BROWSER_VERSION=15.0.19
RUN wget -q "https://dist.torproject.org/torbrowser/${TOR_BROWSER_VERSION}/tor-browser-linux-x86_64-${TOR_BROWSER_VERSION}.tar.xz" \
    -O /tmp/tor-browser.tar.xz \
    && tar -xJf /tmp/tor-browser.tar.xz -C /opt/ \
    && rm /tmp/tor-browser.tar.xz
# The tarball extracts to /opt/tor-browser already — no rename needed.

# --- Non-root user: start-tor-browser refuses to run as root, no flag bypasses this ---
RUN useradd -m -s /bin/bash torbrowser \
    && chown -R torbrowser:torbrowser /opt/tor-browser

# --- Supervisor config controls all processes in this single container ---
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY start.sh /start.sh
COPY fluxbox-menu /root/.fluxbox/menu
RUN sed -i 's/\r$//' /start.sh && chmod +x /start.sh

# Render injects $PORT at runtime — the container must listen on it.
EXPOSE 10000

CMD ["/start.sh"]
