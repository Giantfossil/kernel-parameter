# README.md - Kernel_parameter

## Übersicht

Beschreibung und Zweck
<!-- vim-markdown-toc Marked -->

- [Architektur](#architektur)
  - [Warum geht das nicht direkt?](#warum-geht-das-nicht-direkt?)
  - [Ausnahme: Docker Systemd-Services](#ausnahme:-docker-systemd-services)
  - [Welche Alternativen gibt es für Dateien in /etc/?](#welche-alternativen-gibt-es-für-dateien-in-/etc/?)
    - [1. Auf Arch Linux: Paketmanager-Prüfung (pacman)](<#1.-auf-arch-linux:-paketmanager-prüfung-(pacman)>)
    - [2. pacdiff (für Arch Linux Konfigurations-Updates)](<#2.-pacdiff-(für-arch-linux-konfigurations-updates)>)
    - [3. etckeeper (Empfohlen für Versionsverwaltung von /etc/)](<#3.-etckeeper-(empfohlen-für-versionsverwaltung-von-/etc/)>)
  - [Wie das Überschreiben konkret auf deinem System funktioniert](#wie-das-überschreiben-konkret-auf-deinem-system-funktioniert)
- [Deployment](#deployment)
- [Hilfsbefehle](#hilfsbefehle)

<!-- vim-markdown-toc -->

---

## Architektur

**Erklärung**

1. /etc/sysctl.d/*.conf ➔ Höchste Priorität (Benutzer-/Admin-Einstellungen)
2. /run/sysctl.d/*.conf ➔ Mittlere Priorität (Laufzeit-Dateien)
3. /usr/lib/sysctl.d/*.conf ➔ Niedrigste Priorität (Paket- & Distributions-Standards von Arch Linux)
   ──────

Nein, nicht direkt für beliebige Einzeldateien wie /etc/docker.conf oder /etc/docker/daemon.json.
──────

### Warum geht das nicht direkt?

systemd-delta durchsucht nur Konfigurationspfade, die der systemd/freedesktop-Hierarchie folgen:

1. /etc/ (Höchste Priorität: Deine lokalen Änderungen)
2. /run/ (Mittlere Priorität: Flüchtige Laufzeit-Änderungen)
3. /usr/lib/ (Niedrigste Priorität: Werks-Standards vom OS/Paketmanager)

Damit systemd-delta einen Unterschied (Delta) erkennen kann, muss die ursprüngliche Standard-Datei unter /usr/lib/ existieren. Die meisten Anwendungen (wie Docker mit /etc/docker/daemon.json oder klassische
Programme mit Einzeldateien in /etc/) legen dort jedoch keine Gegenpart-Dateien ab.
──────

### Ausnahme: Docker Systemd-Services

Wenn du den Docker-Daemon selbst über systemd anpasst (z. B. über einen Service-Override unter /etc/systemd/system/docker.service.d/override.conf), erkennt systemd-delta diese Änderung sofort:

systemd-delta systemd/system
──────

### Welche Alternativen gibt es für Dateien in /etc/?

Um manuelle Änderungen an normalen Konfigurationsdateien in /etc/ aufzuspüren, eignen sich folgende Werkzeuge wesentlich besser:

#### 1. Auf Arch Linux: Paketmanager-Prüfung (pacman)

Prüft alle installierten Pakete und zeigt Dateien an, deren Inhalt, Rechte oder Modifikationsdatum von den Paket-Standards abweichen:

# Zeigt modifizierte Konfigurationsdateien im System an

pacman -Qkk 2>&1 | grep -v '0 altered files'

#### 2. pacdiff (für Arch Linux Konfigurations-Updates)

Findet Unterschiede zwischen deinen aktuellen Dateien in /etc/ und den neuen Standard-Dateien vom Paketmanager (.pacnew / .pacsave):

pacdiff

#### 3. etckeeper (Empfohlen für Versionsverwaltung von /etc/)

Verwandelt dein gesamtes /etc/-Verzeichnis in ein Git-Repository. Damit kannst du jederzeit exakt sehen, wer was wann geändert hat:

    cd /etc && sudo git diff

freedesktop-Hierarchie

1. /etc/ (Höchste Priorität: Deine lokalen Änderungen)
2. /run/ (Mittlere Priorität: Flüchtige Laufzeit-Änderungen)
3. /usr/lib/ (Niedrigste Priorität: Werks-Standards vom OS/Paketmanager)

Sysctl-Parameter (/proc/sys)

### Wie das Überschreiben konkret auf deinem System funktioniert

Auf dem System liegen folgende Dateien:

• In /usr/lib/sysctl.d/: 10-arch.conf, 50-coredump.conf, 50-default.conf, etc.
• In /etc/sysctl.d/: 10-hardening.conf, 20-network.conf, 30-memory.conf, 40-development.conf, 99-local.conf

Nur die doppelten Parameter werden überschrieben.

[Wie ist das Verzeichnis aufgebaut? Welche Dateien steuern was?]

| Pfad        | Beschreibung                             |
| :---------- | :--------------------------------------- |
| `sysctl.d/` | Konfigurationsvariablen                  |
| `README.md` | Statischer Ist-Zustand der Dokumentation |

---

## Deployment

Die Konfigurationen für der Kernel Parameter werden von der Repo in das Zielverzeichnis verlinkt.

```bash
bash deploy.sh
```

---

## Hilfsbefehle

```bash
sudo sysctl /usr/lib/systemd/systemd-sysctl --cat-config #konkreten Werte im Kernel aktiv sind
sudo sysctl --system # Abfrage
sudo systemd-delta # Snowflakes
sudo systemd-delta --type=addended sysctl.d
```
