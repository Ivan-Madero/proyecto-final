# Systemd puede sustituir a cron?

**Autor**: Ivan Madero Fernandez\
**Fecha de creación**: 18/04/2017\
**Curso**: 2º de ASX

## Introducción

Veremos el funcionamiento de las herramientas `Crond` y `atd`, cómo
cambiar la configuración de los LOGS por `SMTP` a `journal` 
centralizando estos en un solo host de la red. Y finalmente estudiaremos
si `Systemd` puede sustituir completamente su uso, y en tal caso, cómo 
hacerlo. 

Para ello documentaré la información de uso de `Cron` y `atd`, donde
se almacenan los archivos de configuración, la sintaxis para su uso y
qué configuración es necesaria para substiruir el protocolo `SMTP` por 
`journal`, y centralizando los **logs** en un solo host de la red.

Para poder llevar acabo la conversión de `Cron` a `Systemd` deberé 
explicar la sintaxis que utiliza `Systemd` y hacer uso de algún que otro 
ejemplo práctico para comprender mejor la transformación.

## Tabla de contenidos

1. [Cron y atd](cron_y_atd.md#cron-y-atd)\
	1.1. [Cron](cron_y_atd.md#cron)\
	1.2. [At](cron_y_atd.md#atd)
2. [Sustituir el protocolo SMTP por Journal en Cron](Substituir_el_protocolo_SMTP_en_Cron.md#substituir-el-protocolo-smtp-por-journal-en-cron)\
	2.1. [Configurar el output de cron en journal](Substituir_el_protocolo_SMTP_en_Cron.md#configurar-el-output-de-cron-en-journal)\
	2.2. [Centralizar los logs](Substituir_el_protocolo_SMTP_en_Cron.md#centralizar-los-logs)
3. [Sustituir Cron por Systemd](Systemd_puede_substituir_a_cron.md#substituir-cron-por-systemd)\
	3.1. [Archivos .service](Systemd_puede_substituir_a_cron.md#archivos-service)\
	3.2. [Archivos .timer](Systemd_puede_substituir_a_cron.md#archivos-timer)\
	3.3. [Gestión de los temporizadores](Systemd_puede_substituir_a_cron.md#gesti%C3%B3n-de-los-temporizadores)\
	3.4. [Transformar tareas de Cron a Systemd](Systemd_puede_substituir_a_cron.md#transformar-tareas-de-cron-a-systemd)\
	3.5. [Herramienta para transformar tareas de Cron a Systemd](Systemd_puede_substituir_a_cron.md#herramientas)
4. [Conclusión Personal](Conclusion_personal.md#conclusión-personal)

EXTRA. [WebGrafia](WebGrafia.md#webgrafia)
