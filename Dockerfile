# Builds everything needed to play the game locally (simulation + web server).
# Use it through docker-compose, see LOCAL_PLAY.md
FROM eclipse-temurin:11-jdk
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV SBT="java -Xmx2g -Dsbt.log.noformat=true -Dsbt.supershell=false -jar /opt/sbt-launch.jar"
WORKDIR /app

# A recent sbt launcher (resolves with Coursier); it still builds with the sbt version pinned in project/build.properties
ARG SBT_LAUNCHER_VERSION=1.9.9
RUN curl -fsSL -o /opt/sbt-launch.jar \
    https://repo1.maven.org/maven2/org/scala-sbt/sbt-launch/${SBT_LAUNCHER_VERSION}/sbt-launch-${SBT_LAUNCHER_VERSION}.jar

# 1. Download all dependencies first, so editing game code doesn't re-download everything.
#    (airline-data is published once without sources so that airline-web can resolve it.)
COPY airline-data/build.sbt /app/airline-data/
COPY airline-data/project/build.properties airline-data/project/plugins.sbt /app/airline-data/project/
RUN cd airline-data && $SBT update publishLocal
COPY airline-web/build.sbt /app/airline-web/
COPY airline-web/project/build.properties airline-web/project/plugins.sbt /app/airline-web/project/
RUN cd airline-web && $SBT update

# 2. Backend simulation: compile, publish for the web project, and save the runtime classpath
COPY airline-data/src /app/airline-data/src
RUN cd airline-data && $SBT publishLocal "export runtime:fullClasspath" | grep -E '^/.*\.jar' | tail -n 1 > /app/airline-data/classpath.txt \
    && test -s /app/airline-data/classpath.txt

# 3. Web server: build a production package
COPY airline-web /app/airline-web
RUN cd airline-web && $SBT stage

# 4. Data files used to generate the world on first launch (build output in target/ is kept)
COPY airline-data /app/airline-data

COPY local /app/local
RUN chmod +x /app/local/*.sh

EXPOSE 9000
