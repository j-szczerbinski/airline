#!/bin/bash
# Generates the world on first launch (only once), then runs the background simulation.
set -e
cd /app/airline-data
CP="$(cat classpath.txt)"
JAVA_OPTS="${SIM_JAVA_OPTS:--Xmx3g}"

java $JAVA_OPTS -cp "$CP" com.patson.init.LocalBootstrap
exec java $JAVA_OPTS -cp "$CP" com.patson.MainSimulation
