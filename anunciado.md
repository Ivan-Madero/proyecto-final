# 2. Systemd pot substituir cron?

Tecnologies: systemd, cron, syslog

Systemd té la voluntat d’assumir cada vegada més i més dels serveis que 
tradicionalment proporcionaven sistemes independents. Un cas interessant 
és del de `cron`, que en el futur sembla por desapareixer completament. 
De moment aquesta transició no s’ha realitzat però podem explorar dues 
possibilitats:

- No usar SMTP amb `crond` i redirigir els seus missatges a syslog o al 
journal centralitzant els missatges de diferents hosts en un sol host.

- Convertir crontabs a systemd units, substituint `crond` i `atd` 
totalment per `systemd`.
