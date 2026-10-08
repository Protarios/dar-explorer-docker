#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"
DC=(docker compose --env-file .env)
need_env() { test -f .env || { echo 'Run ./manage.sh init' >&2; exit 2; }; grep -q '^SELKIES_PASSWORD=CHANGE_THIS_BEFORE_START' .env && { echo 'Change SELKIES_PASSWORD' >&2; exit 2; } || true; }
setting() { local val; val="$(sed -n "s/^$1=//p" .env | tail -n 1)"; printf '%s' "$(test -n "$val" && echo "$val" || echo "$2")"; }
app_path() { realpath -m "$(setting APP_DIR ./app)"; }
running() { test -n "$("${DC[@]}" ps --status running -q dar-explorer 2>/dev/null)"; }
idle() {
  running || return 0
  "${DC[@]}" exec -T -u 0 dar-explorer sh -c '
    ! mountpoint -q /ltfs &&
    ! pgrep -x dar >/dev/null &&
    ! pgrep -x dar_xform >/dev/null &&
    ! pgrep -x ltfs >/dev/null &&
    ! pgrep -x mkltfs >/dev/null &&
    ! pgrep -x mt >/dev/null &&
    ! pgrep -x stenc >/dev/null
  ' || { echo 'REFUSED: Tape mount or process active' >&2; exit 3; }
}
case "$1" in
 init) test -e .env || { cp .env.example .env; chmod 600 .env; }; echo 'Configure .env' ;;
 clone-app)
  need_env
  path="$(app_path)"
  test ! -e "$path" || { echo 'Already exists' >&2; exit 2; }
  git clone --branch "$(setting APP_BRANCH ltfs)" --single-branch "$(setting APP_REPOSITORY https://github.com/Protarios/dar-explorer.git)" "$path"
  ;;
 update-app)
  need_env; idle; path="$(app_path)"
  git -C "$path" diff --quiet && git -C "$path" diff --cached --quiet || { echo 'Uncommitted changes' >&2; exit 2; }
  git -C "$path" pull --ff-only
  ;;
 build) need_env; "${DC[@]}" build --pull ;;
 up) need_env; test -f "$(app_path)/dar_explorer.py"; idle; "${DC[@]}" up -d ;;
 restart) need_env; idle; "${DC[@]}" restart ;;
 stop) need_env; idle; "${DC[@]}" stop ;;
 doctor)
  need_env
  "${DC[@]}" exec -T -u 0 dar-explorer bash -lc '
    /opt/dar/bin/dar -V | head -n 3
    /opt/ltfs/bin/ltfs -V 2>&1 | head -n 10
    ls -l /dev/sg* /dev/nst* /dev/st* /dev/fuse 2>/dev/null || true
    lsscsi -g || true
    findmnt /ltfs || true
    /usr/bin/python3 -c "import gi;gi.require_version(\"Gtk\",\"4.0\");gi.require_version(\"Vte\",\"3.91\");from gi.repository import Gtk,Vte;print(\"GTK/VTE OK\")"
    test -f /workspace/dar-explorer/dar_explorer.py && echo "APP OK"
  ' ;;
 status) need_env; "${DC[@]}" ps ;;
 logs) need_env; "${DC[@]}" logs -f --tail 150 ;;
 shell) need_env; "${DC[@]}" exec dar-explorer bash ;;
 *) echo 'Usage: ./manage.sh {init|clone-app|update-app|build|up|restart|stop|doctor|status|logs|shell}'; exit 2 ;;
esac
