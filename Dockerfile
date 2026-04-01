FROM python:3.12-slim

# Metadati
LABEL maintainer="ripandtear-docker"
LABEL description="Container per ripandtear - downloader asincrono da Reddit e altri siti"

# Installa dipendenze di sistema: ffmpeg (necessario per yt-dlp/video Reddit)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    curl \
    gcc \
    python3-dev \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Installa ripandtear e yt-dlp
RUN pip install --no-cache-dir \
    ripandtear \
    "yt-dlp[default]"

# Directory di lavoro dove verranno creati i .rat e le cartelle dei contenuti
WORKDIR /data

# Script di avvio che gestisce il loop di sync
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Volume per persistere i dati scaricati e i file .rat
VOLUME ["/data"]

ENTRYPOINT ["/entrypoint.sh"]
