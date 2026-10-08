# DAR Explorer – Selkies- und LTFS-Entwicklungscontainer

Separates Docker-Repository für https://github.com/Protarios/dar-explorer. Enthält Selkies-Desktop im Browser, GTK4/VTE, DAR 2.8.6, LTFS, mkltfs, mt und stenc. Der bisherige LTFS-Container bleibt unangetastet.

**Entwicklungsstand:** Image-Build und reale Bandhardware sind noch nicht getestet; keine produktiven Bänder verwenden.

## Schnellstart auf Unraid

```bash
git clone https://github.com/Protarios/dar-explorer-docker.git
cd dar-explorer-docker
./manage.sh init
nano .env
./manage.sh clone-app
./manage.sh build
./manage.sh up
./manage.sh doctor
```

Die Oberfläche ist über `https://UNRAID-IP:3001` erreichbar (Port in `.env`). Selkies liefert einen browserbasierten Desktop, **keinen klassischen VNC-Server**.

## Konfiguration

Die `.env.example` enthält nur Beispielwerte. Laufwerkszuordnung mit `lsscsi -g` und `ls -l /dev/tape/by-id/` prüfen: `/dev/sgX`, `/dev/nstX` und `/dev/stX` müssen demselben Laufwerk entsprechen. In `.env` ein starkes `SELKIES_PASSWORD` setzen und persistente Host-Verzeichnisse anpassen.

Der eigene Git-Checkout von `Protarios/dar-explorer` liegt in `./app` (nicht im Docker-Repository versioniert) und wird nach `/workspace/dar-explorer` eingebunden. Updates: `./manage.sh update-app` und nach sicherem Unmount `./manage.sh restart`. Kein Image-Neubuild für Python-Änderungen.

`/ltfs` dient im Container als gemeinsamer Mountpoint für DAR und LTFS; `/backup` und `/restore` sind Unraid-Verzeichnis-Mounts. Stoppe den alten LTFS-Container vor dem Zugriff auf das Bandlaufwerk. Ein gleichzeitig verwendetes Laufwerk kann Daten beschädigen.

## Management

- `./manage.sh build`: Image bauen, Container nicht automatisch neu starten
- `./manage.sh up`: Container starten oder aktualisieren
- `./manage.sh restart` / `stop`: nur wenn DAR und LTFS inaktiv sind
- `./manage.sh doctor`: Programmversionen, Geräte und GTK/VTE prüfen
- `./manage.sh status` / `logs` / `shell`: Diagnose

## Sicherheit

Compose reicht `/dev/fuse` und die Tape-Geräte durch und verwendet für LTFS `SYS_ADMIN` und gelockerte Seccomp-/AppArmor-Profile. Die Laufwerkswerkzeuge laufen über passwortloses sudo; der GTK-Prozess selbst bleibt unprivilegiert. **Nur in vertrauenswürdigem LAN/VPN betreiben, nicht öffentlich ins Internet stellen.**

Die Stop-/Restart-Prüfung ist keine vollständige Bandwechsel-Sicherheitsgarantie. Insbesondere ein Host-Reboot oder Docker-Manager-Aktion kann sie umgehen. Erst nach vollständigem LTFS-Unmount neu starten. Unbekanntes Band bedeutet nicht leeres Band – nicht formatieren.

## Sichere erste Tests

1. Alten LTFS-Container stoppen.
2. `./manage.sh doctor`: Versionen und zugeordnete Geräte prüfen.
3. Browseroberfläche und die beiden unabhängigen VTE-Terminals starten.
4. `ltfs -o device_list` und `mt status` prüfen.
5. Nur mit ausdrücklich freigegebenem Testband: Mount, kleine Datei, vollständiger Unmount.
6. Danach erst DAR-Slice-Test und manueller Bandwechsel.

Der erste reale Debian-Trixie-Build kann Anpassungen der älteren LTFS-Autotools-Abhängigkeiten erfordern.

Siehe auch https://docs.linuxserver.io/selkies/developer-guide/building-images/ und https://github.com/LinearTapeFileSystem/ltfs.