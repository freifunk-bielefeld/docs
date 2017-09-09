# Batman-adv Patches ändern

# Einleitung

Bei den Freifunk Firmwares (gluon oder auch andere), gibt es im Quellcode im Repository ein Verzeichnis für Patches:
```
firmware$ tree patches/
patches/
|-- lede
|   |-- 0001-extend-small-flash-option.patch
|   |-- 0002-remove-default-selection-of-ppp.patch
|   |-- 0003-hostapd-prevent-channel-switch-for-5GHz.patch
|   |-- 0004-netifd-update-to-git-HEAD-version.patch
|   `-- 0005-mac80211-revert-upstream-change-breaking-AP-11s-VIF-.patch
`-- routing
    |-- 0001-batman-adv-update-to-2017.1.patch
    |-- 0002-alfred-update-to-2017.1.patch
    `-- 0003-alfred-adjust-intervals.patch

2 directories, 8 files
```
(Quelle: https://github.com/freifunk-bielefeld/firmware)

Die Dateien werden auf den Lede Quellcode mit `git am *.patch` angewendet um bestimmte Änderungen auf stabile Lede Veröffentlichungen vorzunehmen. Das können Bugfixes, Unterstützung für neue Routermodelle (sogenannte Backports) oder feste Einstellungen sein.

Die Patches sind hier ins zwei Verzeichnisse aufgeteilt, weil das Lede Verzeichnis ein git repository ist, das beim Bauen anderere Feeds als git repos herunterlädt. Daher sind die Patches in einem Verzeichnis jeweils immer für ein git Repo. Im Lede Quellcode liegt z.B. der routing-feed im Pfad feeds/routing/.

Um neue Patches hinzuzufügen oder zu ändern, müssen im Grunde die Patches zuerst mit `git am ...` angewendet werden. Jeder Patch ist dann ein Commit in der git Historie. Dann werden die die Commits geändert und wieder mit `git format-patch` als *.patch Datei exportiert.


## Vorbereitung

Im Firmware-Repository liegen unter files/patch/routing/ Patchdateien, die u.a. batman-adv aktualisieren.
In diesem howto soll gezeigt werden, wie diese aktualisiert werden.

## Alle nötigen Quellen herunterladen

Ein Arbeitsverzeichnis erstellen:
```
mkdir tmp
cd tmp
```

Auschecken:
```
git clone git://git.lede-project.org/source.git
git clone https://github.com/ffbsee/firmware.git
git clone https://git.open-mesh.org/batman-adv.git
```

## Lede vorbereiten

Lede feeds herunterladen/installieren
```
cd source
./scripts/feeds update -a
./scripts/feeds install -a

make defconfig
make menuconfig
```

Im Menü batman-adv auswählen unter "Kernel modules" => "Network Devices" => [x] kmod-batman-adv
"Advanced configuration options (for developers)" => "Enable package source tree override"
Irgendein Router unter "Target Profile" auswählen, daach Speichern & Exit.

Toolchain bauen. Das bauen eines Images ist nicht nötig, ich weiß aber gerade nicht wie. :-)
```
make -j 4
```

Das aus ausgecheckte batman-adv repo mit Lede-Paket verbinden. Dadurch werden die Quellen (genauer, commits) des batman-adv repos von Lede verwendet. Damit können wir live Änderungen vornehmen und testen:
```
ln -s  ~/tmp/batman-adv/.git ~/tmp/source/feeds/routing/batman-adv/git-src
```

## Batman-adv vorbereiten

Wir wollen das batman-adv Release bearbeiten, das in der source/feeds/routing/batman-adv/Makefile steht.
Das ist 2017.2.

```
cd ../batman-adv
git checkout tags/v2017.2
```

Jetzt werden die existierenden batman-adv Patches aus dem Routing-Feed von Lede angewendet.
Das ist sollte nie schiefgehen.

```
git am --whitespace=nowarn ../source/feeds/routing/batman-adv/patches/*.patch
```

Nun die bisherigen Patches aus der Freifunk Firmware als Commits anwenden.
```
git am --whitespace=nowarn ../firmware/patches/routing/*.patch
```

Das kann schiefgehen, in dem Fall müssen die Patches manuell angewenden werden und daraus commits gemacht werden.
Hier können jetzt neue Änderungen committed werden, oder einfach geändert werden, die dann als Patch mit in die Firmware einfließen!
Bitte bedenken, das das nur git commits beim Bauen verwendet werden. Einfache Dateiänderungen werden ignoriert. Da bin ich schon oft drauf reingefallen :>

Mit den commits in batman-adv/ kann immer wieder neu gebaut werden, um zu schauen ob der Code compiliert:
```
cd ../source/
make package/batman-adv/{clean,compile} V=s
```

Sind die Commits alle ok, dann können daraus Patches gemacht werden. Dazu wird wird folgender Befehl verwendet:
```
git format-patch -n <commit-id>
```
<commit-id> soll hier der Commit sein, nach dem die Patches aus dem Freifunk-Repo angewendet wurden. Am besten mit "git log" nachschauen. :-)


Jetzt wurden aus den Commit aktuelle *.patch Dateien erzeugt.

Die Patchdateien dann nach Lede kopieren:
```
cp *.patch ../source/feeds/routing/batman-adv/patches/*
```

Im Lede Source die patches platzieren, die vorherigen ersetzen, neue patches hinzufügen etc.
```
cd ../source/feeds/routing/
# Ändern/Hinzufügen
git add ...
# Commits machen; normalerweise werden hier die commits noch schön gemacht, separiert/zusammengefügt etc. weil jeder Commit zu einer Patch-Datei wird
git commit ...
# Commits als Patch-Datei ausschreiben
git format-patch -n <comit-id>
```

Die erzeugten Patchdateien kommen dann unter ./firmware/patches/routing/ und werden ausgegeben.
