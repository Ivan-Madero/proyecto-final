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

## Tabla de contenidos

1. [Cron y atd](https://github.com/Ivan-Madero/proyecto-final/blob/master/borrador.md#cron-y-atd)\
	1.1. [Archivos de configuración](https://github.com/Ivan-Madero/proyecto-final/blob/master/borrador.md#archivos-de-configuración)\
	1.1.1. [Cron](https://github.com/Ivan-Madero/proyecto-final/blob/master/borrador.md#cron)\
	1.1.2. [At](https://github.com/Ivan-Madero/proyecto-final/blob/master/borrador.md#atd)
2. [Substituit el protocolo SMTP por Journal en Cron](https://github.com/Ivan-Madero/proyecto-final/blob/master/borrador.md#substituit-el-protocolo-smtp-por-journal-en-cron)\
	2.1. [Configurar el output de cron en journal](https://github.com/Ivan-Madero/proyecto-final/blob/master/borrador.md#configurar-el-output-de-cron-en-journal)
3. [Substituir Cron por Systemd.timers](https://github.com/Ivan-Madero/proyecto-final/blob/master/borrador.md#substituir-cron-por-systemdtimers)
