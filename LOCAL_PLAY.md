# Playing locally (single-player)

This runs your own private copy of the game on your computer: your own database, your own
simulation, and the web UI at http://localhost:9000. There's no shared server, so you get no lag
from other players, and you choose how fast game weeks go by.

## What you need

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (Windows / Mac / Linux)
- About 8 GB of free RAM and 5 GB of disk space
- An internet connection for the first build (it downloads Java/Scala dependencies) and for the
  map tiles (Google Maps). The game itself runs on your machine.

## Start it

From the repository folder:

```bash
docker compose up --build
```

- **First launch only:** the build takes several minutes. The simulation then generates the
  world (airports, cities, countries, airplane models), which can take another 10–20 minutes.
  The website comes up after the world has been generated. Later launches skip this step.
- Open http://localhost:9000, sign up for an account (it only exists on your machine), and
  start your airline.

To run it in the background, use `docker compose up -d --build`. Stop it with
`docker compose down`. Your save is kept in a Docker volume, so it's still there next time.

## Game speed

One game week (a "cycle") runs every `CYCLE_DURATION_SECONDS` real seconds. The online servers
use **600** (10 minutes). The local default is **60**.

```bash
CYCLE_DURATION_SECONDS=30 docker compose up -d
```

On Windows PowerShell: `$env:CYCLE_DURATION_SECONDS=30; docker compose up -d`

You can also put `CYCLE_DURATION_SECONDS=30` in a `.env` file next to `docker-compose.yml`.

- `0` = start the next week as soon as the previous one has finished computing.
- The simulation can't go faster than your computer computes a week, so on a big world a week
  may take more than a few seconds regardless.
- If a week takes longer than the configured duration, the next one starts right after; weeks
  never pile up.

## Map

The map uses Google Maps. Without a key it still loads, but it's greyed out with a
"for development purposes only" watermark. To get a clean map, create a Maps JavaScript API key
in the Google Cloud console and start with:

```bash
GOOGLE_MAP_KEY=your-key docker compose up -d
```

## Optional features that aren't set up

- **Flight search** needs Elasticsearch (see the main README). Without it, the flight search
  page won't return results; the rest of the game works.
- Email (password reset) and airport photo banners need Google API credentials (see
  `airline-web/README`). You don't need them for local play.

## Start over with a new world

This deletes your local save:

```bash
docker compose down -v
```

## Running without Docker

Follow the main README, and set the speed with the `CYCLE_DURATION_SECONDS` environment variable
(or `airline.cycle-duration-seconds` in `airline-data/src/main/resources/application.conf`)
before you start `MainSimulation`. You need JDK 11 to build `airline-data`.
