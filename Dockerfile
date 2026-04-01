FROM python:3.11-slim

LABEL maintainer="ripandtear-docker"
LABEL description="Container per ripandtear - downloader asincrono da Reddit e altri siti"

RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    curl \
    gcc \
    python3-dev \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir \
    ripandtear \
    "yt-dlp[default]"

# Crea utente e gruppo 3000 con home dedicata
RUN groupadd -g 3000 appgroup && \
    useradd -u 3000 -g 3000 -m -d /home/appuser -s /bin/bash appuser

# Directory dati con permessi corretti
RUN mkdir -p /data && chown 3000:3000 /data

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

VOLUME ["/data"]

USER 3000:3000
WORKDIR /data

ENTRYPOINT ["/entrypoint.sh"]
