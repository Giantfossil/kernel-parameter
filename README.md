# Kernel-Parameter Konfiguration

Modulare `sysctl`-Konfiguration für Linux-Systeme (speziell Arch Linux Workstations) zur Optimierung von Sicherheit (Hardening), Netzwerk-Performance, Speicherverwaltung (zRAM/VM) und Entwickler-Tools (inotify/Limits).

---

## Inhaltsverzeichnis

- [Übersicht](#übersicht)
- [Architektur & Priorisierung](#architektur--priorisierung)
- [Verzeichnisstruktur](#verzeichnisstruktur)
- [Konfigurationsmodule im Detail](#konfigurationsmodule-im-detail)
  - [10-hardening.conf](#10-hardeningconf)
  - [20-network.conf](#20-networkconf)
  - [30-memory.conf](#30-memoryconf)
  - [40-development.conf](#40-developmentconf)
  - [99-local.conf](#99-localconf)
- [Deployment](#deployment)
- [Verifikation & Hilfsbefehle](#verifikation--hilfsbefehle)

---

## Übersicht

Der Linux-Kernel stellt über das Pseudo-Dateisystem `/proc/sys` tausende konfigurierbare Laufzeitparameter (`sysctl`) bereit. Dieses Repository strukturiert diese Einstellungen in voneinander getrennte, logische Einheiten, um Wartbarkeit, Nachvollziehbarkeit und Versionskontrolle sicherzustellen.

Die Konfigurationsdateien werden via Symlinks nach `/etc/sysctl.d/` ausgerollt und überschreiben dort selektiv die Distributions-Standards (`/usr/lib/sysctl.d/`).

---

## Architektur & Priorisierung

Die Konfiguration folgt dem `systemd` / `freedesktop`-Standard für Dateihierarchien:

```text
┌─────────────────────────────────────────────────────────────┐
│ 1. /etc/sysctl.d/*.conf     (Höchste Priorität: Admin/User) │
├─────────────────────────────────────────────────────────────┤
│ 2. /run/sysctl.d/*.conf     (Mittlere Priorität: Runtime)   │
├─────────────────────────────────────────────────────────────┤
│ 3. /usr/lib/sysctl.d/*.conf (Niedrigste Priorität: OS/Distro)│
└─────────────────────────────────────────────────────────────┘
```

- **Dateiname-Reihenfolge:** Dateien innerhalb von `/etc/sysctl.d/` werden in strikt **alphanumerischer Reihenfolge** eingelesen.
- **Präzedenz:** Später gelesene Dateien überschreiben zuvor gesetzte Werte identischer Parameter (z. B. überschreibt `99-local.conf` Parameter aus `20-network.conf`).
- **Vererbung:** Distributionsdateien unter `/usr/lib/sysctl.d/` bleiben unangetastet; nur die ausdrücklich in `/etc/sysctl.d/` definierten Schlüssel werden zur Laufzeit überschrieben.

---

## Verzeichnisstruktur

| Pfad | Beschreibung |
| :--- | :--- |
| [`sysctl.d/`](file:///home/giant/.local/src/public/kernel_parameter/sysctl.d) | Quellverzeichnis aller modularen Sysctl-Dateien |
| [`sysctl.d/10-hardening.conf`](file:///home/giant/.local/src/public/kernel_parameter/sysctl.d/10-hardening.conf) | Kernel-Absicherung, Angriffsflächen-Minimierung und Berechtigungen |
| [`sysctl.d/20-network.conf`](file:///home/giant/.local/src/public/kernel_parameter/sysctl.d/20-network.conf) | TCP/IP-Sicherheit, BBR Stauregelung und Puffergrößen |
| [`sysctl.d/30-memory.conf`](file:///home/giant/.local/src/public/kernel_parameter/sysctl.d/30-memory.conf) | Virtueller Speicher, zRAM-Optimierung, Swappiness und Dirty-Pages |
| [`sysctl.d/40-development.conf`](file:///home/giant/.local/src/public/kernel_parameter/sysctl.d/40-development.conf) | Dateisystem-Watcher (`inotify`), AIO, PID-Limits und Debugging |
| [`sysctl.d/99-local.conf`](file:///home/giant/.local/src/public/kernel_parameter/sysctl.d/99-local.conf) | Hostspezifische Overrides (z. B. IP-Forwarding) |
| [`deploy.sh`](file:///home/giant/.local/src/public/kernel_parameter/deploy.sh) | Deployment-Skript (erstellt Symlinks nach `/etc/sysctl.d/`) |
| [`README.md`](file:///home/giant/.local/src/public/kernel_parameter/README.md) | Statische Dokumentation des Ist-Zustands |

---

## Konfigurationsmodule im Detail

### 10-hardening.conf
Fokus auf Kernel- und Dateisystem-Sicherheit:
- **Speicherschutz:** ASLR (`kernel.randomize_va_space = 2`), Verbot von Core-Dumps für SUID-Binaries (`fs.suid_dumpable = 0`).
- **Informationslecks:** Schutz von Kernel-Adressen (`kernel.kptr_restrict = 2`) und `dmesg`-Einschränkung für unprivilegierte Benutzer (`kernel.dmesg_restrict = 1`).
- **eBPF & JIT:** Deaktivierung von unprivilegiertem eBPF und JIT-Hardening mit Constant Blinding (`net.core.bpf_jit_harden = 2`).
- **Dateisystem:** Schutz vor Symlink-, Hardlink- und FIFO-Angriffen in Shared-Verzeichnissen wie `/tmp`.
- **Systemstabilität:** Deaktivierung von `kexec` im laufenden Betrieb und Einschränkung von Magic SysRq auf sichere Aktionen (`kernel.sysrq = 176`).

### 20-network.conf
Netzwerksicherheit und High-Throughput / Low-Latency Tuning:
- **DDoS & Spoofing-Schutz:** TCP SYN Cookies (`tcp_syncookies = 1`), RFC 1337 TIME-WAIT Assassination Schutz und Reverse Path Filtering (`rp_filter = 1`).
- **ICMP-Härtung:** Ignorieren von Redirects und fehlerhaften ICMP-Meldungen.
- **TCP-Performance:** Aktivierung von Fair Queueing (`default_qdisc = fq`) und TCP BBR Stauregelung (`tcp_congestion_control = bbr`).
- **Verbindungsoptimierung:** TCP Fast Open (`tcp_fastopen = 3`), `tcp_tw_reuse = 1`, reduziertes FIN-Timeout und optimierte Keepalive-Intervalle.
- **Puffer & Backlog:** Maximale Socket-Puffer (`16 MB`) und vergrößerte Backlog-Warteschlangen (`somaxconn = 4096`, `netdev_max_backlog = 16384`).

### 30-memory.conf
Workstation-Speicherverwaltung und zRAM-Abstimmung:
- **zRAM & Swappiness:** `vm.swappiness = 180` zur aggressiven Ausnutzung von zRAM (zstd-RAM-Kompression) unter Vermeidung von Disk-I/O.
- **VFS Cache:** `vm.vfs_cache_pressure = 50` hält Inode- und Dentry-Caches länger im Speicher (schnellere `git`-Operationen und Dateizugriffe).
- **Writeback:** Frühzeitiges Flushen von Dirty Pages (`dirty_background_ratio = 5`, `dirty_ratio = 10`) zur Vermeidung von I/O-Lags auf NVMe/SSD.
- **Speichermappings:** `vm.max_map_count = 1048576` für speicherintensive Anwendungen wie Steam/Proton, Docker-Container und Elasticsearch/Wasm.

### 40-development.conf
Ressourcenlimits für Entwicklungsumgebungen und Build-Pipelines:
- **File Watcher:** Hohe Inotify-Limits (`max_user_watches = 524288`, `max_user_instances = 1024`, `max_queued_events = 32768`) für IDEs (VS Code, Neovim, JetBrains), Web-Watcher (Vite, Webpack) und Sync-Dienste.
- **Gleichzeitigkeit & Limits:** Hohes Limit für asynchrone I/O (`fs.aio-max-nr = 1048576`) und erhöhte maximale PID-Anzahl (`kernel.pid_max = 4194304`) für parallele Container-Workloads.
- **Debugging & Profiling:** Restriktiver `ptrace_scope = 1` für sicheres Debugging eigener Kindprozesse (`gdb`, `strace`, `valgrind`) sowie `perf`-Profiling ohne Root-Rechte.

### 99-local.conf
Lokale, hostspezifische Overrides:
- Aktivierung von IPv4-Routing (`net.ipv4.ip_forward = 1`) für Container-Netzwerke, Bridges oder VPNs.
- Vorbereitete Schalter für systemspezifische Ausnahmen.

---

## Deployment

Die Konfigurationsdateien werden als symbolische Links in `/etc/sysctl.d/` platziert. Dadurch bleiben Änderungen im Git-Repository sofort auf dem Zielsystem wirksam.

### Automatisiertes Deployment

```bash
bash deploy.sh
```

Das Skript führt folgende Schritte aus:
1. Erstellt Symlinks von allen `sysctl.d/*.conf` Dateien nach `/etc/sysctl.d/`.
2. Wendet die neuen Parameter sofort über `sudo sysctl --system` im laufenden Kernel an.

---

## Verifikation & Hilfsbefehle

### 1. Geladene Konfiguration und Status prüfen

```bash
# Alle Konfigurationsdateien in der Reihenfolge ihres Ladens anwenden
sudo sysctl --system

# Prüfen, welche Parameter aktuell im Kernel aktiv sind
sudo /usr/lib/systemd/systemd-sysctl --cat-config
```

### 2. Konfigurations-Deltas & Overrides analysieren

```bash
# Abweichungen und Overrides gegenüber den Distributions-Standards aufspüren
sudo systemd-delta sysctl.d

# Nur hinzugefügte oder überschriebene Dateien anzeigen
sudo systemd-delta --type=extended,overridden sysctl.d
```

### 3. Einzelne Kernel-Werte abfragen

```bash
# Wert eines spezifischen Parameters auslesen
sysctl vm.swappiness
sysctl net.ipv4.tcp_congestion_control

# Direkt aus dem procfs lesen
cat /proc/sys/fs/inotify/max_user_watches
```
