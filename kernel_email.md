
# Die EMail-Adresse im Kernel setzen

Wenn ein Linux Kernel bootet, wie bei LEDE, wir in der ersten Zeile des Kernel-Logs (`dmesg`)
eine EMail angezeigt die aus dem Benutzernamen und dem Namen des System besteht, auf dem
das Image gebaut wurde.

Damit der Kernel beim Booten die EMail-Adresse info@freifunk-bielefeld.de anzeigt anstatt z.B.
user@hostname des eigenen Systems, müssen zwei Wrapper unter /usr/local/bin erstellt werden:

/usr/local/bin/whoami:
```
#!/bin/sh

# username to return to the kernel build scripts/mkcompile_h
LINUX_COMPILE_BY="info"

# get the current path and remove the directory containing this script so the real
# command can be called and its output filtered
DIRNAME=$(dirname $0)
NEWPATH=$(IFS=:; for dir in $PATH; do if [ "$dir" != "$DIRNAME" ]; then echo -n "${dir}:"; fi; done)

# calling process ID, required to see if it is the kernel build calling or not
if ps -p $PPID -o args= | grep -q mkcompile_h; then
  echo $LINUX_COMPILE_BY
  exit 0
fi

# execute the system command otherwise
PATH=$NEWPATH whoami "$@"
```

/usr/local/bin/hostname:
```
#!/bin/sh

# username to return to the kernel build scripts/mkcompile_h
LINUX_COMPILE_HOST="freifunk-bielefeld.de"

# get the current path and remove the directory containing this script so the real
# command can be called and its output filtered
DIRNAME=$(dirname $0)
NEWPATH=$(IFS=:; for dir in $PATH; do if [ "$dir" != "$DIRNAME" ]; then echo -n "${dir}:"; fi; done)

# calling process ID, required to see if it is the kernel build calling or not
if ps -p $PPID -o args= | grep -q mkcompile_h; then 
  echo $LINUX_COMPILE_HOST
  exit 0
fi

# execute the system command otherwise
PATH=$NEWPATH hostname
```

Zuletzt noch beide Dateien ausführbar machen:
```
chmod a+x /usr/local/bin/whoami
chmod a+x /usr/local/bin/hostname
```

Jetzt das LEDE-Image bauen. :-)

Quelle: http://tjworld.net/wiki/Linux/Kernel/Build/CustomiseVersionString
