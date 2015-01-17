# SSH-Zugriff per Public Key

Das anmelden auf einem Server per ssh mit einem öffentlichen Schlüssel ist
einfacher als sich ein Passwort merken zu müssen und auch sicherer.
Um sich auf einen Server per SSH und ohne Passwort anzumelden muss zuerst
ein Private-/Public Schlüsselpaar erzeugt werden:

```
ssh-keygen -t rsa
```

Der Schlüssel liegt nun in ~/.ssh/id_rsa (privater Schlüssel) und
~/.ssh/id_rsa.pub (öffentlicher Schlüssel).

Als nächstes muss der Schlüssel auf alle Server kopiert werden,
auf die man mit diesem Schlüssel Zugang haben möchte:

```
ssh-copy-id -i ~/.ssh/id_rsa.pub user@remote-system
```

Nun kann man sich per `ssh user@remote-system"` auf dem Server anmelden.
Den Zugang per Passwort kann nun auf dem Server ausgeschaltet werden (in /etc/ssh/sshd_config):
```
PasswordAuthentication no
UsePAM no
```

Den Neustart des SSH Servers nicht vergessen:
```
/etc/init.d/sshd restart
```
