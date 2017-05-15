# Systemd puede substituir a cron?

**Autor**: Ivan Madero Fernandez\
**Fecha de creación**: 18/04/2017\
**Curso**: 2º de ASX

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

## Tabla de contenidos

1. [Cron y atd](Systemd_puede_substituir_a_cron.md#cron-y-atd)\
	1.1. [Cron](Systemd_puede_substituir_a_cron.md#cron)\
	1.2. [At](Systemd_puede_substituir_a_cron.md#atd)
2. [Substituir el protocolo SMTP por Journal en Cron](Systemd_puede_substituir_a_cron.md#substituit-el-protocolo-smtp-por-journal-en-cron)\
	2.1. [Configurar el output de cron en journal](Systemd_puede_substituir_a_cron.md#configurar-el-output-de-cron-en-journal)\
	2.2. [Centralizar los logs](Systemd_puede_substituir_a_cron.md#centralizar-los-logs)
3. [Substituir Cron por Systemd.timers](Systemd_puede_substituir_a_cron.md#substituir-cron-por-systemdtimers)\
	3.1. [Archivos .service](Systemd_puede_substituir_a_cron.md#archivos-service)\
	3.2. [Archivos .timer](Systemd_puede_substituir_a_cron.md#archivos-timer)\
	3.3. [Gestión de los temporizadores](Systemd_puede_substituir_a_cron.md#gesti%C3%B3n-de-los-temporizadores)\
	3.4. [Transformar tareas de Cron a Systemd](Systemd_puede_substituir_a_cron.md#transformar-tareas-de-cron-a-systemd)

EXTRA. [WebGrafia](WebGrafia.md#webgrafia)
	
