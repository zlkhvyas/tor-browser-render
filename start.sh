#!/bin/bash
set -e

# Render sets $PORT at runtime. Fall back to 10000 for local testing.
PORT="${PORT:-10000}"

# Require a VNC password to be set — refuse to start wide open.
if [ -z "$VNC_PASSWORD" ]; then
  echo "ERROR: VNC_PASSWORD env var is not set. Set it in Render's dashboard before deploying."
  exit 1
fi

# Start Xvfb, fluxbox, Tor Browser, and x11vnc under supervisor (background).
/usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf &

# Give the desktop + Tor Browser a moment to come up.
sleep 8

# websockify bridges the browser (HTTPS/WSS, on $PORT) to the VNC server (5900),
# and --web serves the noVNC files cloned from novnc/noVNC — vnc.html lives at
# the repo root, so it's reachable at https://<service>.onrender.com/vnc.html
exec websockify --web=/opt/noVNC "0.0.0.0:${PORT}" localhost:5900
