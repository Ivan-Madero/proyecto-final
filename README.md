# Systemd puede substituir a cron?

## Introducción

Veremos el funcionamiento de las herramientas `Crond` y `atd`, como
cambiar la configuracion de los **logs** por `SMTP` a `journal` 
centralizando estos en un solo host de la red. Y finalmente estudiaremos
si `Systemd` puede substituir completamente su uso, y en tal caso, como 
hacerlo.

Para ello documentaremos la información de uso de `Cron` y `atd`, donde
se almacenan los archivos de configuración, la sintaxis para su uso y
que configuración es necesaria para substiruir el protocolo `SMTP` por 
`journal` centralizando los **logs** en un solo host de la red. Para 
apoyar a la documentación elaboraremos un conjunto de dockers con dichas
configuraciones. 

## Tabla de contenidos

1. [Cron y atd](https://github.com/Ivan-Madero/proyecto-final/blob/master/borrador.md#cron-y-atd)
1. [Archivos de configuración](https://github.com/Ivan-Madero/proyecto-final/blob/master/borrador.md#archivos-de-configuración)
