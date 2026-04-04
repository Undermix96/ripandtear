# ripandtear — Docker Setup

Questo setup esegue [ripandtear](https://pypi.org/project/ripandtear/) in background con un loop di sincronizzazione automatica.

## Come funziona

ripandtear tiene traccia dei contenuti di utenti Reddit/subreddit in file `.rat` (JSON camuffato).  
Ogni profilo vive nella propria cartella: `./data/NomeCartella/NomeCartella.rat`

Il container si avvia, cerca tutti i `.rat` in `/data`, li sincronizza con `-sr -sR -H`, poi dorme per `SYNC_INTERVAL` secondi e ricomincia.

---

## Struttura cartelle

```
.
├── Dockerfile
├── docker-compose.yml
├── entrypoint.sh
└── data/                        ← creata automaticamente al primo avvio
    ├── MarioRossi/
    │   ├── MarioRossi.rat       ← file di tracciamento (JSON)
    │   ├── pics/
    │   └── vids/
    └── AltroUtente/
        ├── AltroUtente.rat
        └── ...
```

---

## Avvio rapido

```bash
# 1. Build e avvio in background
docker compose up -d --build

# 2. Aggiungere il primo utente Reddit
docker compose run --rm manage -mk MarioRossi -r mario_rossi_reddit -sr

# 3. Aggiungere un subreddit
docker compose run --rm manage -mk EarthPorn \
  -d "https://www.reddit.com/r/EarthPorn/" -H -S

# 4. Controllare i log del daemon
docker compose logs -f ripandtear
```

---

## Comandi utili

### Aggiungere un utente Reddit
```bash
docker compose run --rm manage -mk NomeCartella -r reddit_username -sr
```
- `-mk NomeCartella` — crea la cartella e il .rat
- `-r reddit_username` — salva il nome utente nel .rat
- `-sr` — esegue subito la prima sync

### Aggiungere un utente Redgifs
```bash
docker compose run --rm manage -mk NomeCartella -R redgifs_username -sR
```

### Aggiungere più account alla stessa cartella (stesso creatore)
```bash
docker compose run --rm manage
# poi dentro il container:
cd /data/NomeCartella
ripandtear -r secondo_account_reddit -sr
```

### Scaricare un singolo URL
```bash
docker compose run --rm manage -d "https://www.reddit.com/r/pics/comments/abc123/"
```

### Vedere gli errori di un profilo
```bash
docker compose run --rm manage
cd /data/NomeCartella
ripandtear -pe    # stampa gli URL in errore
ripandtear -se    # riprova a scaricarli
```

### Forzare un sync immediato (senza aspettare il timer)
```bash
docker compose exec ripandtear /entrypoint.sh
# oppure riavvia il container:
docker compose restart ripandtear
```

---

## Variabili d'ambiente

| Variabile       | Default | Descrizione                                      |
|----------------|---------|--------------------------------------------------|
| `SYNC_INTERVAL` | `3600`  | Secondi tra una sync e la prossima (1 ora)       |
| `RAT_DIR`       | `/data` | Directory dove cercare i file .rat               |
| `LOG_LEVEL`     | `1`     | `0`=silenzioso, `1`=normale, `2`=verbose (`-L`)  |
| `RUN_ONCE`      | `false` | Se `true`, esegue un solo sync e termina         |

Per cambiare l'intervallo a 30 minuti, modifica `docker-compose.yml`:
```yaml
environment:
  SYNC_INTERVAL: "1800"
```

---

## Note importanti

- **Reddit API limits**: ripandtear gestisce i rate limit automaticamente facendo pause
  ai multipli di 5 minuti. Se sembra "bloccato", probabilmente sta solo aspettando.
- **Niente duplicati**: il flag `-H` (hash) rimuove automaticamente i file duplicati.
- **Video**: yt-dlp e ffmpeg sono già inclusi nell'immagine per supportare i video Reddit.
- **Persistenza**: tutti i dati sono in `./data/` sul host — il container è stateless.


## Aggiungere Nuovo subreddit

```bash
ripandtear -mk EarthPorn -u "https://www.reddit.com/r/EarthPorn/top/?sort=top&t=daily&limit=5" -H -S
```
