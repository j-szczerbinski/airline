#!/bin/bash
# Starts the web server once the simulation is up (the simulation listens on 2552 after world init).
set -e
echo "Waiting for the simulation to finish starting (first launch generates the world and can take a while)..."
until (echo > /dev/tcp/127.0.0.1/2552) 2>/dev/null; do sleep 5; done
echo "Simulation is up, starting web server on port 9000"

# A secret is required in production mode; this is only a local game, so a random one per start is fine
SECRET="$(head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \n')"
rm -f /app/airline-web/target/universal/stage/RUNNING_PID
exec /app/airline-web/target/universal/stage/bin/airline-web \
  -J${WEB_JAVA_OPTS:--Xmx1g} \
  -Dhttp.port=9000 \
  -Dplay.http.secret.key="$SECRET" \
  -Dplay.crypto.secret="$SECRET" \
  -Dpidfile.path=/dev/null
