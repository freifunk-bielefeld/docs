# Ein Freifunk Release fertig machen

Diese Anleitung baut alle Images für OpenWrt mit einer Freifunk Konfiguration.

Ein Release besteht aus drei Schritten:
 * Images bauen
 * Manifest-Datei erstellen
 * Dateien auf den Update-Server kopieren

## Images bauen

Wie ein Image gebaut wird, wurde bereits beschrieben. Anstatt für jede Platform "Target Profile" und eventuell "Subtarget"
per "make menuconfig" von Hand zu selektieren, kann dies auch per Script geschehen:


```
#!/bin/sh

# dumpinfo.pl is used to get all targets configurations:
# https://git.openwrt.org/?p=buildbot.git;a=blob;f=phase1/dumpinfo.pl

pkgarch_prev=""

./dumpinfo.pl targets | while read arch pkgarch; do

  # Debug output
  echo "arch: $arch, pkgarch: $pkgarch"

  # Only clear space if the package architecture changes
  if [ "$pkgarch_prev" != "$pkgarch" ]; then
    rm -rf build_dir/toolchain-*
    rm -rf build_dir/target-*
  fi

  rm -rf tmp/

  echo "CONFIG_TARGET_${arch%/*}=y" > .config
  echo "CONFIG_TARGET_${arch%/*}_${arch#*/}=y" >> .config

  echo "CONFIG_TARGET_MULTI_PROFILE=y" >> .config
  echo "CONFIG_TARGET_ALL_PROFILES=y" >> .config
  echo "CONFIG_TARGET_PER_DEVICE_ROOTFS=y" >> .config
  echo "CONFIG_PACKAGE_freifunk-basic=y" >> .config

  make defconfig
  make -j4

  pkgarch_prev="$pkgarch"
done
```

Dieses obige Script selektiert folgende Optionen und nachfolgend jede Platform einzeln:

 * "Target Profile" => "Multiple Devices"
 * "Target Devices" =>  "Enable all profiles by default" 
 * "Target Devices" => "Use a per-device root filesystem ..."

Die Images sollten dann irgendwann fertig sein.
Ein [Script](release_rename_images.sh) ermöglichst es, in den Namen der Image-Dateien z.B. ein 0.4.4-ffbi einzubauen.

Wenn der Linux Kernel vom Image startet, wird im Kernel Log (`dmesg`) der Name des Benutzer und Systems angezeigt, auf dem die Images
gebaut wurden. Mit einer [Änderung am System](kernel_email.md) kann dies z.B. auf die e-Mail-Adresse der Freifunk-Community gesetzt werden.


# Manifest-Datei erstellen

Die Manifest-Datei ist eine Textdatei und enthält den Namen der Imagedateien, die Firmwareversion, die Prüfsummen der Images
und digitale Unterschriften. Die digitalen Unterschriften stellen sicher, dass die Images autorisiert sind und nicht jemand
alle Router im Netz mit einem anderen Image flasht und damit kompromittiert.

## Erstellen der digitalen Signatur

Der Autoupdater Programm läuft auf dem Router und sucht in Intervallen unter angegebenen Adressen nach neuen Versionen der Firmware.
Wird eine gefunden, wird diese neue Firmware heruntergeladen und installiert. Die Router-Einstellungen bleiben erhalten. Ein Update sollte daher selten auffallen.

Um zu verhinden, dass andere Leute ein fremdes Images ins Netz stellen, werden die Images von einer oder mehreren Personen signiert.
Jede dieser Personen muss einen geheimen (secret key) und den dazugehörigen öffentlichen Schlüssel (public key) generieren.
Der öffentliche Schlüssel muss auf dem Router in der /etc/config/autoupdater eingetragen sein.

Zum Generieren eines Schlüsselpaares wird ecdsautils verwendet.

Installation:
```
sudo apt install cmake pkg-config g++

wget https://git.universe-factory.net/libuecc/snapshot/libuecc-7.zip
unzip libuecc-7.zip
cd libuecc-7
cmake .
make
sudo make install
cd ..
rm -rf libuecc*

apt install pkg-config

wget https://github.com/tcatm/ecdsautils/archive/v0.3.2.zip -O ecdsautils-0.3.2.zip
unzip ecdsautils-0.3.2.zip
cd ecdsautils-0.3.2/
PKG_CONFIG_PATH=/usr/local/lib/pkgconfig cmake .
make
sudo make install
cd ..
rm -rf ecdsautils*

sudo ldconfig
```

Nun kann ein neues Schlüsselpaar (bestehend aus zwei Dateien) generiert werden:
```
ecdsakeygen -s > secret.key
ecdsakeygen -p < secret.key > public.key
```

Auf dem Router sind in der Konfigurationsdatei /etc/config/autoupdater im Eintrag "mirror" die Adresse und Pfad eingetragen, unter dem die Images (und das sogenannte manifest) zu finden sein sollen.

# Manifest-Datei erstellen

Die Datei `manifest` sieht z.B. folgendermaßen aus:

```
BRANCH=stable

# model version sha512sum filename
tp-link-tl-wdr4300-v1 0.4 c300c2b80a8863506cf3b19359873c596d87af3183c4826462dfb5aa69bec7ce65e3db23a9f6f779fd0f3cc50db5d57070c2b62942abf4fb0e08ae4cb48191a0 gluon-0.4-tp-link-tl-wdr4300-v1-sysupgrade.bin

# after three dashes follow the ecdsa signatures of everything above the dashes
---
49030b7b394e0bd204e0faf17f2d2b2756b503c9d682b135deea42b34a09010bff139cbf7513be3f9f8aae126b7f6ff3a7bfe862a798eae9b005d75abbba770a
```
Zuerst müssen die drei Bindestriche und alles danach entfernt werden. Dann wird die Signatur dieser "rohen" Manifest-Datei erzeugt.

```
ecdsasign manifest < secret.key
```

Jede Signatur wird an das Manifest angehängt (eine Signatur pro Zeile).
Es muss eine ausreichende Anzahl von Signaturen (zwei oder mehr) vorliegen.
Nach der letzten Signatur folgt eine abschließende leere Zeile.
Um in Zukunft das Manifest zu aktualisieren, gibt es auch ein [Script](release_update_manifest.sh).

Hinweis:
 * Die Spalten im Manifest dürfen nur mit *einem* Leerzeichen getrennt werden.
 * Der Zeilenumbruch vor den drei Bindestrichen darf nicht entfernt werden, viele Editoren zeigen das nicht korrekt an.
 * Die Bezeichnung des Routermodells im Manifest (z.B. "tp-link-tl-wdr4300-v1") wird mit folgender Zeile erstellt:  
   ```cat /tmp/sysinfo/model | tr '[A-Z]' '[a-z]' | sed -r 's/[^a-z0-9]+/-/g;s/-$//'```
 * sollte libuecc.so.0 nicht gefunden werden, dann funktioniert eventuell folgendes:  
   ```LD_PRELOAD="/usr/local/lib/libuecc.so" ecdsasign manifest < secret.key```

# Dateien auf den Update-Server kopieren

Die Datei `manifest` und die `*sysupgrade.bin` Dateien liegen alle in dem Verzeichnis,
das in der Firmware der Router in der Datei /etc/config/autoupdater angegeben wurde.

Ein Router wird mehrmals am Tag prüfen, ob unter der angegebenen Stelle ein manifest
verfügbar ist (siehe auch /etc/crontabs/root). Falls das der Fall ist und wenn die Versionsnummer höher ist, wird geschaut ob die Mindestanzahl
der geforderten Unterschriften vorhanden ist und mit den Unterschriften übereinstimmen. Stimmt alles, dann wird das passende image heruntergeladen,
die Prüfsumme überprüft und das Update angewendet. Der Router startet dann neu.
