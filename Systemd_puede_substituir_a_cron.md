# Systemd puede substituir a cron?

## Cron y atd

**Cron** :
Es la herramienta encargada de ejecutar tareas programadas y recurrentes
(todos los dias, todas las semanas, etc.).

**Atd** :
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
- Con una lista blanca, /etc/cron.allow, donde solo los usuarios
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

##### Formato crontab

```
# Archivo crontab / formato
# min  hora  dia  mes  dds [usuario] programa

# Ejemplos
# Hace algo todas las noches a las 22:30
30  20  *  *  *  /bin/hacealgo

# Hace algo de Lunes a Viernes a las 08:00
00  08  *  *  1-5  /bin/hacealgo

# Hacer algo el Lunes, Miercoles y Viernes a las 12:30
30  12  *  *  1,3,5  /bin/hacealgo

# Hacer algo los dias pares a las 09:00
00  09  */2  *  *  /bin/hacealgo

# Hacer algo después de cada reinicio
@reboot  /bin/hacealgo
```

**Campos:**
- el valor del minuto (0 a 59)
- el valor de la hora (0 a 23)
- el valor del dia del mes (1 a 31)
- el valor del mes (1 a 12)
- el valor de los días de la semana ( 0 a 7 [domingo = 0/7, lunes = 1, 
etc.]; Sun, Mon, etc. )
- el nombre de usuario bajo el que se ejecutará el programa
- el programa a ejecutar

**Abreviaciones:**
- **@yearly**: Una vez por año (1 de Enero a las 00:00)
- **@monthly**: Una vez por mes (1r día del mes a las 00:00)
- **@weekly**: Una vez por semana (Domingo a las 00:00)
- **@daily**: Una vez por dia (a las 00:00)
- **@hourly**: Una vez por hora (al principio de cada hora)
- **@reboot**: Justo después de iniciar el equipo

#### Atd

Su funcionalidad es muy parecida a la del `Cron`, la diferencia es que
esta diseñado para ejecutar una tarea programada de un solo uso.

Las tareas programadas se almacenan en **/var/spool/at/**, sin importar
el usuario que las ha configurado, estas se ejecutaran en nombre del
usuario que las ha configurado.

A diferencia del `Cron`, `at` no tiene un archivo general para todo el
sistema, y para configurar las nuevas tareas se deben hacer através de
la orden `$at`, aun así tiene la misma funcionalidad referente a los 
privilegios de uso de los usurios que tiene `Cron` ( **/etc/at.deny** ; 
**/etc/at.allow** ).

##### Formato atd

```
$ at [hora] [fecha]
at> orden1
at> orden2
at> etc ( Fin = Ctrl + D )

# Ejemplos
$ at 09:52		# La proxima vez que el reloj marque las 09:52
at> echo "algo" >> /tmp/algo.txt

$ at 00:01 01.01.2018		# Se ejecutará el 1 de Enero del 2018 a las 10.
at > echo "Feliz Año Nuevo" >> /dev/tty1
```

- **Hora**: La hora se puede indicar en diferentes formatos; **HH:MM**, 
**HHMM**, **HH.MM**, **HH,MM**, **Hpm**, **Ham**, **midnight**(00:00), 
**noon**(12:00), **now**(actual), **teatime**(16:00).

- **Fecha**: La fecha se puede indicar en diferentes formatos; 
**DD.MM.AA**, **MMDDAA**, **MM/DD/AA**, **AA-MM-DD**, fechas en ingles
( mes dia año: **june 17 2018** ), **today**, **tomorrow**, dias de la
semana ( **monday**, **sunday**, etc. ). 

## Substituit el protocolo SMTP por Journal en Cron

`Cron` por defecto usa el protocolo SMTP para generar el log de los
resultados de sus tareas programadas. Creo que este sistema es un poco 
anticuado y debe actualizarse, para ello redirigiremos la salida de sus
resultados a Journal, y finalmente para adecuarlo a un entorno de trabajo
centralizaremos el log de diferentes host en uno solo.

### Configurar el OUTPUT de Cron en Journal

En las anteriores versiones de `Cron` se redirigia el output al syslog 
mediante el uso de `logger`.

```
# Ejemplo tradicional de redirección del output al syslog
*/2 * * * * echo $USER 2>&1 >> /tmp/date.log | logger
```

Actualmente en las versiones actuales de `Cron` este esta preparado para
que el **daemon** pueda ser configurado para redirigir el output a
syslog, sigue sin conocer la existencia del `Journal`, pero como este
escucha por el puerto que lo hacia syslog cara a los programas es como
si lo siguieran haciendo. La configuración necesaria actual es muy
simple.

Modificaremos el fichero **/etc/sysconfig/crond**, este contiene la
configuracion de `Cron Daemon`.
En el argumento `CRONDARGS=` añadiremos la opción **-s** para que la
salida se redirija al syslog y añadiremso **-m off** para deshabilitar
la salida por mail. Tras modificar el archivo reiniciaremos el servicio
del `Cron`.

```
[root@hostname ~]# vim /etc/sysconfig/crond

# Settings for the CRON daemon.
# CRONDARGS= :  any extra command-line startup arguments for crond
CRONDARGS= -s -m off

[root@hostname ~]# systemctl restart crond.service
```

### Centralizar los logs

Una vez realizada la tarea de configurar el **output** de `Cron` al 
`Journal`, toca configurar las maquinas para un entorno de trabajo
adequado, con esto me refiero a centralizar los logs del `Journal` en
un solo host de la red, para facilitar al administrador el trabajo de
administrar la red.

## Substituir Cron por Systemd.timers
`Systemd.timers` son unos temporizadores bajo el control de `Systemd`,
estos pueden sustituir el uso de `Cron`. Sus archivos de configuración
terminan en **.timer** y controlan los archivos o eventos de **.service**.
Los temporizadores tienen soporte incorporado para eventos de tiempo de
calendario, eventos de tiempo monótonos y se puede ejecutar de forma 
asíncrona.

Como cualquier tecnologia tiene sus ventajas y desventajas:\
**Ventajas**
- Se pueden iniciar fácilmente independientemente de los temporizadores.
- Se pueden configurar para ejecutarse en un entorno especifico.
- Se pueden adjuntar trabajos a **cgroups**.
- Se pueden configurar para depender de otras unidades `Systemd`.
- Los trabajos se registran en el diario de `Systemd` para facilitat la
depuración.

**Desventajas**
- Algunas cosas que son fáciles con `Cron` son muy complejas con 
`Systemd`.
- Complejidad: Se deben configurar 2 ficheros, **.timers** y **.service**.
- No hay equivalentes incorporados a MAILTO de `Cron`.
