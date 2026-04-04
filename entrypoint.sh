#!/bin/bash
# ==============================================================================
# entrypoint.sh - Gestore del loop di sincronizzazione per ripandtear
# ==============================================================================
# Variabili d'ambiente configurabili:
#   SYNC_INTERVAL   - Secondi tra una sync e la prossima (default: 3600 = 1 ora)
#   RAT_DIR         - Directory con i file .rat (default: /data)
#   LOG_LEVEL       - 0=silenzioso, 1=normale, 2=verbose (default: 1)
#   RUN_ONCE        - Se "true", esegue un solo sync e poi esce (default: false)
# ==============================================================================

set -e

SYNC_INTERVAL="${SYNC_INTERVAL:-3600}"
RAT_DIR="${RAT_DIR:-/data}"
LOG_LEVEL="${LOG_LEVEL:-1}"
RUN_ONCE="${RUN_ONCE:-false}"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# Costruisce i flag di logging per ripandtear
get_log_flags() {
    case "$LOG_LEVEL" in
        0) echo "" ;;
        2) echo "-L" ;;
        *) echo "" ;;
    esac
}

# Esegue la sincronizzazione su una singola directory .rat
sync_rat_dir() {
    local dir="$1"
    local rat_name
    rat_name=$(basename "$dir")

    log "→ Sincronizzazione di: $rat_name"

    # Entra nella directory e lancia la sync
    # -sr = Sync Reddit (utenti e subreddit salvati nel .rat)
    # -sR = Sync Redgifs (se presenti username Redgifs nel .rat)
    # -H  = Hash e rimuove duplicati dopo il download
    cd "$dir" || return 1

    local log_flags
    log_flags=$(get_log_flags)

    if ripandtear $log_flags -sa -H -S; then
        log "✓ Sync completata: $rat_name"
    else
        log "⚠ Sync terminata con errori: $rat_name (potrebbe essere normale se non ci sono nuovi contenuti)"
    fi

    cd "$RAT_DIR"
}

# Trova tutte le directory che contengono un file .rat e le sincronizza
run_sync_all() {
    log "=============================="
    log "Avvio ciclo di sincronizzazione"
    log "=============================="

    local found=0

    # Cerca file .rat dentro /data (sia nella root che in sottocartelle)
    while IFS= read -r -d '' rat_file; do
        local rat_dir
        rat_dir=$(dirname "$rat_file")
        sync_rat_dir "$rat_dir"
        found=$((found + 1))
    done < <(find "$RAT_DIR" -maxdepth 2 -name "*.rat" -print0 2>/dev/null)

    if [ "$found" -eq 0 ]; then
        log "⚠ Nessun file .rat trovato in $RAT_DIR"
        log "  Per aggiungere utenti/subreddit, usa:"
        log "  docker exec <container> ripandtear -mk NomeCartella -r reddit_username -sr"
        log "  oppure modifica direttamente docker-compose.yml e usa 'manage' come CMD"
    else
        log "Sync completata per $found profilo/i."
    fi
}

# ==============================================================================
# MAIN
# ==============================================================================

# Se vengono passati argomenti al container, li esegue direttamente
# Esempio: docker run ... ripandtear -mk MioUtente -r username -sr
if [ $# -gt 0 ]; then
    log "Esecuzione comando manuale: ripandtear $*"
    cd "$RAT_DIR"
    exec ripandtear "$@"
fi

log "ripandtear sync daemon avviato"
log "  Directory dati : $RAT_DIR"
log "  Intervallo sync: ${SYNC_INTERVAL}s ($(( SYNC_INTERVAL / 60 )) minuti)"
log "  Modalità       : $([ "$RUN_ONCE" = "true" ] && echo 'singola esecuzione' || echo 'loop continuo')"
log ""

# Primo sync immediato all'avvio
run_sync_all

if [ "$RUN_ONCE" = "true" ]; then
    log "RUN_ONCE=true — uscita dopo il primo sync."
    exit 0
fi

# Loop continuo
while true; do
    log "Prossima sync tra ${SYNC_INTERVAL}s..."
    sleep "$SYNC_INTERVAL"
    run_sync_all
done
