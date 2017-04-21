`Borrador`

# Systemd puede substituir a cron?

## Introducción

Veremos el funcionamiento de las herramientas `Crond` y `atd`, como
cambiar la configuracion de los LOGS por `SMTP` a `journal` 
centralizando estos en un solo host de la red. Y finalmente estudiaremos
si `Systemd` puede substituir completamente su uso, y en tal caso, como 
hacerlo.

Para ello documentaremos la información de uso de `Cron` y `atd`, donde
se almacenan los archivos de configuración, la sintaxis para su uso y
que configuración es necesaria para substiruir el protocolo `SMTP` por 
`journal` centralizando los **logs** en un solo host de la red. Para 
apoyar a la documentación elaboraremos un conjunto de dockers con dichas
configuraciones. 

## Cron y atd

Cron :
 Es la herramienta encargada de ejecutar tareas programadas y recurrentes
(todos los dias, todas las semanas, etc.).

Atd :
 Es la herramienta encargada que ejecuta una sola vez en un momento 
especifico un programa concreto.

### Archivos de configuración

#### Cron
De forma predeterminada, todos los usuarios pueden programar tareas para
ejecutar. Cada usuario tiene su propio `crontab`, se puede editar usando
el comando `$crontab -e`, se almacena en 
**/var/spool/cron/crontabs/$USER**.

```
Se puede configurar que usuarios tiene privilegios para poder usar cron,
hay dos formas posibles:
- Con una lista blanca, **/etc/cron.allow**, donde solo los usuarios
indicados podran usar cron.
- O con una lista negra, donde todos menos los usuarios indicados podran 
usar cron.
```

El usuario **root** tiene su propio `crontab`, pero puede definir el
archivo **/etc/crontab** o escribir diferentes archivos en el directorio
**/etc/cron.d**. Tienen la ventaja de poder especificar el usuario bajo
el que se ejecutará el programa.

Archivos y directorios que incluye el paquete `cron`.
```
# ls /etc/cron
cron.d/       cron.deny     cron.monthly/ cron.weekly/  
cron.daily/   cron.hourly/  crontab       
```

#### Atd

## Substituir Cron por Systemd.timers
