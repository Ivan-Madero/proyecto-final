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

## Substituir el protocolo SMTP por Journal en Cron

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
administrar la red. La configuración por defecto que proporciona la 
herramienta `systemd-journal-remote` y `systemd-journal-upload` carga 
integramente el fichero de log de la maquina local (cliente), en la
maquina remota (servidor), esta ación esta pensada para ejecutarse una 
sola vez en el arranque de la maquina cliente. Si fuera necesario se 
podria ejecutar manualmente la carga del fichero en el cliente, pero no 
es recomendable lanzarlo periodicamente en plazos de tiempo cortos, 
podria provocar grandes saturaciones en la red de trabajo.

#### Configuración Servidor

Para configurar el ordenador el cual centralizará los logs del resto de
ordenadores debemos seguir los siguientes pasos:

1. Instalar el paquete `systemd-journal-remote`: `# dnf install -y 
systemd-journal-remote`.
2. Habilitar el puerto de escucha: `# systemctl enable 
systemd-journal-remote.socket`.
3. Revisar la configración del puerto de escucha. Podemos encontrar el 
fichero en: **/lib/systemd/system/systemd-journal-remote.socket**. El 
puerto por defecto es el 19532.
	```
	#  This file is part of systemd.
	#
	#  systemd is free software; you can redistribute it and/or modify it
	#  under the terms of the GNU Lesser General Public License as published by
	#  the Free Software Foundation; either version 2.1 of the License, or
	#  (at your option) any later version.

	[Unit]
	Description=Journal Remote Sink Socket

	[Socket]
	ListenStream=19532

	[Install]
	WantedBy=sockets.target

	```
4. Revisar el fichero de configuración del servicio, podemos encontrarlo
en: **/lib/systemd/system/systemd-journal-remote.service**. Si utilizamos
el servicio via http debemos substituir el parametro por defecto 
`--listen-https=-3` por `--listen-http=-3`.
	```
	#  This file is part of systemd.
	#
	#  systemd is free software; you can redistribute it and/or modify it
	#  under the terms of the GNU Lesser General Public License as published by
	#  the Free Software Foundation; either version 2.1 of the License, or
	#  (at your option) any later version.

	[Unit]
	Description=Journal Remote Sink Service
	Documentation=man:systemd-journal-remote(8) man:journal-remote.conf(5)
	Requires=systemd-journal-remote.socket

	[Service]
	ExecStart=/usr/lib/systemd/systemd-journal-remote \
			  --listen-http=-3 \
			  --output=/var/log/journal/remote/
	User=systemd-journal-remote
	Group=systemd-journal-remote
	PrivateTmp=yes
	PrivateDevices=yes
	PrivateNetwork=yes
	WatchdogSec=3min

	[Install]
	Also=systemd-journal-remote.socket
	```
5. Crear la carpeta definida en parametro `--output=` y cambair su 
propietario por **systemd-journal-remote**. 
`# mkdir /var/log/journal/remote ; 
chown systemd-journal-remote /var/log/journal/remote`.
6. Reinicia el socket: `# systemctl restart systemd-journal-remote.socket`.
7. Actualiza los cambion en los servicios: `# systemctl daemon-reload`.

#### Configuración Cliente

La configuración necesaria en el cliente es la siguiente:

1. Instalar el paquete `systemd-journal-remote`: `# dnf install -y 
systemd-journal-remote`.
2. Editar el archivo de configuración, lo podemos encontrar en: 
**/etc/systemd/journal-upload.conf**. Debemos configurar el destino en 
el parametro `URL=` con el protocolo http o https y la ip y puerto del 
servidor.
	```
	[Upload]
	 URL=http://10.250.100.150:19532
	# ServerKeyFile=/etc/ssl/private/journal-upload.pem
	# ServerCertificateFile=/etc/ssl/certs/journal-upload.pem
	# TrustedCertificateFile=/etc/ssl/ca/trusted.pem
	```
3. Habilitar `systemd-journal-upload` haciendo uso del siguiente comando: 
`# systemctl enable systemd-journal-upload.service`.

#### Resultado de la configuración

Para acceder a los logs del journal de las otras maquinas cliente 
deberemos llamar a `journalctl` con el paramentro `--directory 
/var/log/journal/remote`, que es el directorio que hemos definido en 
**/lib/systemd/system/systemd-journal-remote.service** anteriormente.
```
# NOTA: Para visualizar el de la maquina local(servidor) en la misma atacada 
he creado un symbolic link del log en la carpeta /var/log/journal/remote.

[root@serverf25 ~]# journalctl _COMM=crond --since today  --directory /var/log/journal/remote/ 
-- Logs begin at vie 2016-01-22 09:15:49 CET, end at lun 2017-05-15 09:36:50 CEST. --
may 15 09:09:42 serverf25 crond[706]: (CRON) INFO (RANDOM_DELAY will be scaled with factor 12% if used.)
may 15 09:09:42 serverf25 crond[706]: (CRON) INFO (running with inotify support)
may 15 09:09:45 f25 crond[721]: (CRON) INFO (RANDOM_DELAY will be scaled with factor 9% if used.)
may 15 09:09:45 f25 crond[721]: (CRON) INFO (running with inotify support)
may 15 09:10:01 f25 CROND[1412]: (root) CMDOUT (hola, soy root desde f25)
may 15 09:10:01 serverf25 CROND[1396]: (root) CMD (/usr/bin/echo "hola, soy $USER desde $HOSTNAME")
may 15 09:10:01 serverf25 CROND[1395]: (root) CMDOUT (hola, soy root desde serverf25)
may 15 09:12:01 serverf25 CROND[1560]: (root) CMDOUT (hola, soy root desde serverf25)
may 15 09:14:01 f25 CROND[1634]: (root) CMDOUT (hola, soy root desde f25)
may 15 09:14:01 serverf25 CROND[1563]: (root) CMDOUT (hola, soy root desde serverf25)
may 15 09:16:01 f25 CROND[1653]: (root) CMDOUT (hola, soy root desde f25)
may 15 09:16:01 serverf25 CROND[1572]: (root) CMD (/usr/bin/echo "hola, soy $USER desde $HOSTNAME")
may 15 09:16:01 serverf25 CROND[1571]: (root) CMDOUT (hola, soy root desde serverf25)
may 15 09:18:01 serverf25 CROND[1575]: (root) CMD (/usr/bin/echo "hola, soy $USER desde $HOSTNAME")
may 15 09:18:01 serverf25 CROND[1574]: (root) CMDOUT (hola, soy root desde serverf25)
may 15 09:22:01 f25 CROND[1680]: (root) CMDOUT (hola, soy root desde f25)
may 15 09:22:01 serverf25 CROND[1621]: (root) CMDOUT (hola, soy root desde serverf25)
may 15 09:24:01 f25 CROND[1682]: (root) CMDOUT (hola, soy root desde f25)
may 15 09:24:01 serverf25 CROND[1664]: (root) CMD (/usr/bin/echo "hola, soy $USER desde $HOSTNAME")
may 15 09:24:01 serverf25 CROND[1663]: (root) CMDOUT (hola, soy root desde serverf25)
may 15 09:28:01 f25 CROND[1693]: (root) CMDOUT (hola, soy root desde f25)
may 15 09:28:01 serverf25 CROND[1733]: (root) CMDOUT (hola, soy root desde serverf25)
may 15 09:30:01 f25 CROND[1699]: (root) CMD (/usr/bin/echo "hola, soy $USER desde $HOSTNAME")
may 15 09:30:01 serverf25 CROND[1779]: (root) CMD (/usr/bin/echo "hola, soy $USER desde $HOSTNAME")
may 15 09:30:01 serverf25 CROND[1778]: (root) CMDOUT (hola, soy root desde serverf25)
may 15 09:32:01 f25 CROND[1701]: (root) CMDOUT (hola, soy root desde f25)
may 15 09:33:46 f25 crond[721]: (CRON) INFO (Shutting down)
may 15 09:33:55 f25 crond[720]: (CRON) INFO (RANDOM_DELAY will be scaled with factor 86% if used.)
may 15 09:33:55 f25 crond[720]: (CRON) INFO (running with inotify support)
may 15 09:34:01 f25 CROND[1485]: (root) CMD (/usr/bin/echo "hola, soy $USER desde $HOSTNAME")
may 15 09:34:01 f25 CROND[1484]: (root) CMDOUT (hola, soy root desde f25)
may 15 09:36:01 serverf25 CROND[1855]: (root) CMD (/usr/bin/echo "hola, soy $USER desde $HOSTNAME")
may 15 09:36:01 serverf25 CROND[1854]: (root) CMDOUT (hola, soy root desde serverf25)
```

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

Para poder configurar las tareas que realizamos en `Cron` con `Systemd`
debemos aprender a definir los archivos **.service** y los **.timer**. 

### Archivos .service

Crearemos estos fichero en el directorio: **/etc/systemd/system/**.

```
# Ejemplo de fichero .service

[user@hostname system]# cat /usr/lib/systemd/system/dnf-makecache.service
 
[Unit]
Description=dnf makecache

[Service]
Type=oneshot
Nice=19
IOSchedulingClass=2
IOSchedulingPriority=7
Environment="ABRT_IGNORE_PYTHON=1"
ExecStart=/usr/bin/dnf makecache timer
```

El anterior ejemplo es un archivo por defecto del sistema, ejecuta la
orden **/usr/bin/dnf** con los argumentos *makecache* y *timer*, y es de
tipo "oneshot", esto quiere decir que se ejecutará y una vez finalizada
la acción se detendrá.

Los ficheros de las unidades de tipo **.service** se componen de tres 
apartados: \[Unit\], \[Service\] y \[Install\].

#### \[Unit\]

Contiene información genérica sobre la unidad independientemente del 
tipo de unidad que sea.

Algunos elementos que pueden definirse en este apartado son:
- **Description=** Una cadena de texto que describe la unidad, la
descripción debe contener un nombre que signifique algo para el usuario
final. Ej. "Apache2 Web Server" es un buen ejemplo, no es demasiado 
genérico y tampoco demasiado especifico.
- **Documentation=** Una lista de URLs separados por espacios 
referenciando la documentación o la configuración de la unidad.
- **Requires=** Configura dependencias de otras unidades, si estas no 
estan activadas la unidad no podra activarse.
- **OnFailure=** Lista de unidades que se activaran cuando esta entre
en estado fallido.
- **SourcePath=** Una ruta de acceso a un archivo de configuración de 
esta unidad.

Para mas información recomiendo consultar el `man 5 systemd.unit` o 
[Manual Web](https://www.freedesktop.org/software/systemd/man/systemd.unit.html#%5BUnit%5D%20Section%20Options).

#### \[Service\]

Este apartado es especifico de los achivos de unidades **.service**. Y 
puede contener algunos de los siguientes elementos:
- **ExecStart=** Comandos con sus argumentos que se ejecutan cuando se 
inicia este servicio.
- **ExecStartPre=** Comando adicional que se ejecutará antes del 
`ExecStart=`.
- **ExecStartPost=** Comando adicional que se ejecutará después del 
`ExecStart=`.
- **ExecReload=** Comando que se ejecutará cuando se realize un reload.
- **ExecStop=** Comandos a ejecutar para detener el servicio iniciado.
- **Type=** Configura el tipo de arranque del proceso para esta unidad 
de servicio. `simple`, `forking`, `oneshot`, `dbus`, `notify` o `idle`.
- **TimeoutSec=** Una abreviatura para configurar `TimeoutStartSec=` y 
`TimeoutStopSec=` con el valor especificado.
- **Restart=** Configura si el servicio se reiniciará cuando se cierre 
el proceso de servicio, se muera o se alcance un tiempo de espera.
- **SuccessExitStatus=** Toma una lista de las definiciones de estado de 
salida que, cuando son devueltas por el proceso de servicio principal, 
se considerarán terminación exitosa, además del código de salida normal 
exitoso 0 y las señales SIGHUP, SIGINT, SIGTERM y SIGPIPE. 
- **FailureAction=** Configura la acción a realizar cuando el servicio 
entra en un estado fallido. 

Para mas información recomiendo consultar el `man systemd.service` o 
[Manual Web](https://www.freedesktop.org/software/systemd/man/systemd.service.html#Options).

#### \[Install\]

Los archivos de unidades pueden incluir este apartado, que contiene 
información de la instalación de la unidad. Esta sección no es 
interpretada por `Systemd` durante el tiempo de ejecución, es 
interpretada al usarse los comandos `# systemctl enable/disbale`.

La lista de elementos que puede contener este apartado es el siguiente:
- **Alias=** Una lista separada por espacios de los nombres que tendra
la unidad al instalarse. No compatible con las unidades de tipo: mount, 
slice, swap y automount. 
- **WantedBy=** Se creara un enlace simbolico de la unidad en los .wants
especificados, puede aparecer mas de una vez o contener una lista 
separada por espacios.
- **RequiredBy=** Se creara un enlace simbolico de la unidad en los 
.requires especificados, puede aparecer mas de una vez o contener una 
lista separada por espacios.
- **Also=** Lista de las unidades adicionales que se instalaran/desintalaran
juntamente con esta unidad.

Para mas información recomiendo consultar el `man 5 systemd.unit` o 
[Manual Web](https://www.freedesktop.org/software/systemd/man/systemd.unit.html#%5BInstall%5D%20Section%20Options).

### Archivos .timer

Crearemos estos fichero en el directorio: **/etc/systemd/system/**.

```
# Ejemplo de fichero .timer

[user@hostname system]# cat /usr/lib/systemd/system/dnf-makecache.timer

[Unit]
Description=dnf makecache timer
ConditionKernelCommandLine=!rd.live.image

[Timer]
OnBootSec=10min
OnUnitInactiveSec=1h
Unit=dnf-makecache.service

[Install]
WantedBy=basic.target
```

Como observar este temporizador pertenece al ejemplo mostrado del fichero
**.service**. En este se indica que se ejecutará por primera vez a los
10min desde que la maquina fue arrancada, y posteriormente cada 60min (1h).

Los ficheros de unidades de tipo **.timer** se componen de tres 
apartados \[Unit\], \[Timer\] y \[Install\].

#### \[Timer\]

Los archivos de unidades de tipo **.timer** deben contener el apartado 
\[Timer\] que define las configuraciones de los temporizadores, esto 
tienen unos elementos especificos, algunos de esto son:

- **OnActiveSec=** Define un tiempo en relación con el momento en que se
activa el temporizador; `# systemctl start .timer`.
- **OnBootSec=** Define un tiempo en relación a cuando la maquina 
arranca.
- **OnStartupSec=** Define un tiempo en relación a la primera vez que se
arranco systemd.
- **OnUnitActiveSec=** Define un tiempo en relación a la ultima vez que 
se activo.
- **OnUnitInactiveSec=** Define un tiempo en relación a la ultima vez en
que se desactivo.
- **OnCalendar=** Define temporizadores en tiempo real con expresiones
de eventos de calendario. Para mas información sombre la sintaxis
consultar el `man 7 systemd.time`o 
[Manual Web](https://www.freedesktop.org/software/systemd/man/systemd.time.html)
- **AccuracySec=** Define el tiempo en el que debe transcurir, el tiempo
que permanecera encendido.
- **Unit=** La unidad se activará cuando transcurra este temporizador,
la unidad no puede ser **.timer**, si no se especifica la unidad, este
valor pretederminado es un servicio que tiene el mismo nombre de la
unidad del temporizador.
- **Persistent=** Es una valor booleano, si este es `true` cuando se 
active el temporizador si el tiempo de activación ya ha transcurrido se 
ejecutara immediatamente. Al usar `OnCalendar=` el valor por defecto es 
`false`.
- **WakeSystem=** Toma un argumento booleano. Si es cierto, un 
temporizador transcurrido hará que el sistema reanude su suspensión, 
si se suspende y si el sistema lo admite. El valor por defecto es 
`false`.

Para mas información consulte el `man sytemd.timer` o 
[Manual Web](https://www.freedesktop.org/software/systemd/man/systemd.timer.html#Options).

### Gestión de los temporizadores

Una vez creados los temporizadores, podemos ponerlos en marcha usando el
comando `# systemctl start name.timer`, cuando la maquina se apague este 
temporizador será apagado, si queremos que sea permanente deberemos 
realizar el siguiente comando, para cada vez que la maquina se encienda 
se active el temporizador: `# systemctl enable name.timer`.

Para detenerlo usaremos: `# systemctl stop name.timer`. Y para deshabilitar 
el arranque permanente usaremos: `# systemctl disable name.timer`.

Podemos obserbar los temporizadores activos con el comando `# systemctl 
list-timers`

```
[user@hostname ~]# systemctl list-timers 
NEXT                          LEFT       LAST                          PASSED       UNIT                         ACTIVATES
Mon 2017-05-08 13:00:35 CEST  35s left   Mon 2017-05-08 12:58:35 CEST  1min 24s ago echo_date.timer              echo_date.service
Mon 2017-05-08 13:35:25 CEST  35min left Mon 2017-05-08 12:35:23 CEST  24min ago    dnf-makecache.timer          dnf-makecache.service
Tue 2017-05-09 00:00:00 CEST  11h left   Mon 2017-05-08 09:06:24 CEST  3h 53min ago mlocate-updatedb.timer       mlocate-updatedb.service
Tue 2017-05-09 00:00:00 CEST  11h left   Mon 2017-05-08 09:06:24 CEST  3h 53min ago unbound-anchor.timer         unbound-anchor.service
Tue 2017-05-09 09:40:01 CEST  20h left   Mon 2017-05-08 09:40:01 CEST  3h 19min ago systemd-tmpfiles-clean.timer systemd-tmpfiles-clean.service
```

Con este comando podemos ver la proxima activación, cuanto queda para 
esta, la ultima activación, cuanto ha pasado desde esta, el `.timer` y 
el `.service`.

### Transformar tareas de Cron a Systemd

Para poder transformar una tarea definida por `Cron` a `Systemd` debemos
analizar la tarea y dividarla en que tiene que hacer y cuando lo debe 
hacer. Lo que debe hacer se tendrá que definir en un fichero de unidad
de tipo **.service**, mientras que, el cuando lo debe hacer, debe
definirse en un fichero de unidad tipo **.timer**. A continuación
expondré algunos ejemplos:

#### Ejemplo1

En este primer ejemplo obaservaremos un caso muy simple, un `echo` que
cada 2 min escribe en un fichero que se encuentra en **/tmp/date.log**,
una linea con la fecha y hora, el usuario y la palabra cron. Esta tarea
esta configurada en el cron personal de un usuario, usaremos el comando 
`crontab -e` para editarlo.

- **Cron**

	```
	[user@hostname ~]# crontab -e
	*/2 * * * * /usr/bin/echo "$(/usr/bin/date) - $USER - cron" >> /tmp/date.log
	```

	Para hacer la conversion de `Cron` a `Systemd` crearemos dos ficheros en
	**/etc/systemd/system/**, con el nombre de **echo_date.service** y 
	**echo_date.timer**.

- **Systemd**

	- **File: /etc/systemd/system/echo_date.service**
		```
		# Servicio creado para sustituir la tarea en Cron con la siguiente 
		# sintaxis:
		# */2 * * * * /usr/bin/echo "$(/usr/bin/date) - $USER - cron" >> /tmp/date.log
		#

		[Unit]
		Description=Insertar fecha y usuario en un fichero en tmp.

		[Service]
		Type=oneshot
		ExecStart=/usr/bin/sh -c '/usr/bin/echo "$(/usr/bin/date) - $USER - Systemd" >> /tmp/date.log'
		```
	- **File: /etc/systemd/system/echo_date.timer**
		```		
		# Temporizador para ejecutarla cada 2 min

		[Unit]
		Description=Temporizador de echo_date cada 2 min.

		[Timer]
		OnBootSec=2min
		OnUnitActiveSec=2min
		Unit=echo_date.service

		[Install]
		WantedBy=basic.target
		```

	Como podemos observar siempre que tengamos que redirigir la salida a un 
	fichero o expandir un $, deberemos llamar a un shell para que realize 
	esta tarea.

- **Resultado**

	```
	[user@hostname ~]# tail -f /tmp/date.log
	Mon May  8 12:26:02 CEST 2017 - root - Cron
	Mon May  8 12:26:32 CEST 2017 -  - Systemd
	Mon May  8 12:28:01 CEST 2017 - root - Cron
	Mon May  8 12:28:33 CEST 2017 -  - Systemd
	Mon May  8 12:30:01 CEST 2017 - root - Cron
	Mon May  8 12:30:33 CEST 2017 -  - Systemd
	Mon May  8 12:32:01 CEST 2017 - root - Cron
	Mon May  8 12:32:33 CEST 2017 -  - Systemd
	Mon May  8 12:34:01 CEST 2017 - root - Cron
	Mon May  8 12:34:33 CEST 2017 -  - Systemd
	Mon May  8 12:36:01 CEST 2017 - root - Cron
	Mon May  8 12:36:33 CEST 2017 -  - Systemd
	```

#### Ejemplo2

En este segundo ejemplo observaremos un caso en que se ejecura un script,
el cual realizará algunas acciones, cada mes a las 12:00, si alguno de 
los cuatro primeros dias del mes caen en lunes.

**Cron**

```
[user@hostname ~]# vim /etc/crontab
SHELL=/bin/bash
PATH=/etc/crond.jobs:/sbin:/bin:/usr/sbin:/usr/bin
MAILTO=root

# For details see man 4 crontabs

# Example of job definition:
# .---------------- minute (0 - 59)
# |  .------------- hour (0 - 23)
# |  |  .---------- day of month (1 - 31)
# |  |  |  .------- month (1 - 12) OR jan,feb,mar,apr ...
# |  |  |  |  .---- day of week (0 - 6) (Sunday=0 or 7) OR sun,mon,tue,wed,thu,fri,sat
# |  |  |  |  |
# *  *  *  *  * user-name  command to be executed

# Tarea para ejecutar un script a principio de mes.
00 12 1..4 * Mon root script.sh
```

Esta vez he obtado por defenir la tarea en el fichero general del `Cron`, 
**/etc/crontab**. Simplemente para dejar constancia que ambas practicas 
son posibles, la utilización de una o otra dependera de las necesidades 
y criterios de trabajo. He decidido almacenar este script en un directrio
que yo he creado, **/etc/crond.jobs** y ha consecuencia he añadido dicho
directorio al **PATH** del `crontab`.

**Systemd**

```
File: /etc/systemd/system/exec-script.service
# Servicio creado para sustituir la tarea en Cron con la siguiente 
# sintaxis: 00 12 1..4 * Mon root script.sh

[Unit]
Description=Ejecuta un script.

[Service]
Type=oneshot
ExecStart=/usr/bin/sh -c '/etc/cron.jobs/script.sh'

///////////////////////////////////////////////////////////////////////

File: /etc/systemd/system/exec-script.timer
# Temporizador para ejecutar cada principio de mes, cuando uno de los 4
# primeros dias cae en Lunes.

[Unit]
Description=Temporizador de exec-script cada princio de mes.

[Timer]
OnCalendar=Mon *-*-01..04 12:00:00
Unit=exec-script.service

[Install]
WantedBy=basic.target
```

En este ejemplo cabe destacar el parametro **OnCalendar=**, el cual 
usaremos cuando quedramos concretar la ejecución de la tarea en una 
fecha concreta.

**Resultado**

```
# Nota: Podria falsear los datos o cambiar los parametros de ejecución,
pero creo que no es necesario. Mostrare cuando esta prevista la proxima
ejecución y la ejecutaré manualmente.

# Proxima ejecución: Lunes 03/07/2017 a las 12:00:00
[root@hostname ~]# systemctl list-timers 
NEXT                          LEFT                  LAST                          PASSED       UNIT                         ACTIVATES
lun 2017-07-03 12:00:00 CEST  1 months 18 days left n/a                           n/a          exec-script.timer            exec-script.service

# Ejecución manual:
[root@hostname ~]# systemctl start exec-script.service

# Resultado de la ejecución:
[root@hostname ~]# journalctl -f
may 15 12:48:56 localhost.localdomain systemd[1]: Starting Ejecuta un script....
may 15 12:48:56 localhost.localdomain sh[2477]: Hello World!
may 15 12:48:56 localhost.localdomain sh[2477]: Today is 05/15/17.
may 15 12:48:56 localhost.localdomain kernel: audit: type=1130 audit(1494845336.948:253): pid=1 uid=0 auid=4294967295 ses=4294967295 msg='unit=exec-script com
may 15 12:48:56 localhost.localdomain kernel: audit: type=1131 audit(1494845336.948:254): pid=1 uid=0 auid=4294967295 ses=4294967295 msg='unit=exec-script com
may 15 12:48:56 localhost.localdomain audit[1]: SERVICE_START pid=1 uid=0 auid=4294967295 ses=4294967295 msg='unit=exec-script comm="systemd" exe="/usr/lib/sy
may 15 12:48:56 localhost.localdomain audit[1]: SERVICE_STOP pid=1 uid=0 auid=4294967295 ses=4294967295 msg='unit=exec-script comm="systemd" exe="/usr/lib/sys
may 15 12:48:56 localhost.localdomain systemd[1]: Started Ejecuta un script..
```

#### Ejemplo3

Este ultimo ejemplo que expongo será útil para entornos de trabajo, para 
que no se queden encendidas las maquinas de los trabajadores después de 
la jornada laboral. La tarea se ejecutará los dias laborales 
(lunes - viernes) a las 9:00 PM.

**Cron**

```
SHELL=/bin/bash
PATH=/etc/cron.jobs:/sbin:/bin:/usr/sbin:/usr/bin
MAILTO=root

# For details see man 4 crontabs

# Example of job definition:
# .---------------- minute (0 - 59)
# |  .------------- hour (0 - 23)
# |  |  .---------- day of month (1 - 31)
# |  |  |  .------- month (1 - 12) OR jan,feb,mar,apr ...
# |  |  |  |  .---- day of week (0 - 6) (Sunday=0 or 7) OR sun,mon,tue,wed,thu,fri,sat
# |  |  |  |  |
# *  *  *  *  * user-name  command to be executed

00 21 * * 1..5 root /usr/sbin/shutdown
```

**Systemd**

```
File: /etc/systemd/system/shutdown.service
# Servicio creado para sustituir la tarea en Cron con la siguiente 
# sintaxis: 00 21 * * 1..5 root /usr/sbin/shutdown

[Unit]
Description=Apaga de forma segura el equipo.

[Service]
Type=oneshot
ExecStart=/usr/sbin/shutdown

///////////////////////////////////////////////////////////////////////

File: /etc/systemd/system/shutdown.timer
# Temporizador para ejecutar en dias laborables, de lunes a viernes, a las
# 21:00.

[Unit]
Description=Temporizador de shutdown para los dias laborales (Mon-Fri) a 9PM.

[Timer]
OnCalendar=Mon-Fri *-*-* 21:00:00
Unit=shutdown.service

[Install]
WantedBy=basic.target

```

**Resultado**

```
# NOTA: Mostraré su proxima ejecución y el registro del journalctl.

# Proxima ejecución:
[root@hostname ~]# systemctl list-timers 
NEXT                           LEFT                  LAST                          PASSED    UNIT                         ACTIVATES
mar 2017-05-16 21:00:00 CEST   11h left              n/a                           n/a       shutdown.timer               shutdown.service

# Registro journalctl:
[root@hostname ~]# journalctl -f
may 16 09:41:21 localhost.localdomain systemd[1]: Starting Apaga de forma segura el equipo....
may 16 09:41:21 localhost.localdomain systemd-logind[636]: Creating /run/nologin, blocking further logins...
may 16 09:41:21 localhost.localdomain audit[1]: SERVICE_START pid=1 uid=0 auid=4294967295 ses=4294967295 msg='unit=shutdown comm="systemd" exe="/usr/lib/syste
may 16 09:41:21 localhost.localdomain audit[1]: SERVICE_STOP pid=1 uid=0 auid=4294967295 ses=4294967295 msg='unit=shutdown comm="systemd" exe="/usr/lib/system
may 16 09:41:21 localhost.localdomain shutdown[1857]: Shutdown scheduled for dt 2017-05-16 09:42:21 CEST, use 'shutdown -c' to cancel.
may 16 09:41:21 localhost.localdomain systemd[1]: Started Apaga de forma segura el equipo..
```

### Herramientas

#### systemd-cron-next

[Pagina Web Oficial](https://github.com/systemd-cron/systemd-cron-next)

En la pagina web oficial contiene el material y la información necesaria
para la instalación y utilización de este herramienta que su función es 
analizar las tareas definidas en `Crond`, y adecuarlas para que sean 
ejecutadas por `Systemd`. Para su completo funcionamiento requiere de
`run-parts` que normalmente viene incluido con el paquete `crontabs`.

Es la version actualizada del paquete `systemd-crontab-generator`. 

**NOTA**: Es una versión beta, el autor advierte que no se hace cargo si 
funciona erroneamente.

Hay dos formas de utilizar esta herramienta:

- **Manual**: Puedes usarla de forma manual llamando al comando 
`# /usr/local/lib/systemd/system-generators/systemd-crontab-generator outuput_folder`.
Este analiza los ficheros de tareas de `Cron` y genera su conversion para
`Systemd`. Es recomendable usar rutas absolutas para que los archivos 
generados funcionen correctamente, y la mejor ruta para que el sistema 
pueda hacer uso de ellos es: **/etc/systemd/system/**. El autor recomienda
no usarlo manualmente.

- **Automaticamente**: Para usarlo de esta forma simplemente
ejecutamos el comando: `# systemctl enable cron.target`. Cuando inicie 
el sistema activará todos los **.timer** definidos en 
**/run/systemd/generator/**. Los ficheros que contiene este directorio 
son creados de forma automatica por el ejecutable 
`systemd-crontab-generator`, esto sucede cuando el sistema inicia o se 
produce un `systemctl daemon-reload`. Esto es posible gracias a una 
herramienta que contine `Systemd`, `systemd.generator`, que cualquier 
fichero binario que se encuentre en uno de sus directorios assignados se 
ejecutará en el inicio o cada vez que se produzca un 
`systemctl daemon-reload`. Para mas información acerca de esta 
herramienta consultar el `man systemd.generator` o 
[Manual Web](https://www.freedesktop.org/software/systemd/man/systemd.generator.html)

**Ejemplo de los resultados generados**

- **Cron**
	```
	# Archivo /etc/crontab
	[root@hostname ~]# cat /etc/crontab 
	SHELL=/bin/bash
	PATH=/etc/cron.jobs:/sbin:/bin:/usr/sbin:/usr/bin
	MAILTO=root

	# For details see man 4 crontabs

	# Example of job definition:
	# .---------------- minute (0 - 59)
	# |  .------------- hour (0 - 23)
	# |  |  .---------- day of month (1 - 31)
	# |  |  |  .------- month (1 - 12) OR jan,feb,mar,apr ...
	# |  |  |  |  .---- day of week (0 - 6) (Sunday=0 or 7) OR sun,mon,tue,wed,thu,fri,sat
	# |  |  |  |  |
	# *  *  *  *  * user-name  command to be executed

	*/2 * * * * root /usr/bin/echo "$(/usr/bin/date) - $USER - cron" >> /tmp/date.log
	```
- **Systemd**

	- **File: .service**
		```
		[Unit]
		Description=[Cron] "*/2 * * * * root /usr/bin/echo "$(/usr/bin/date) - $USER - cron" >> /tmp/date.log"
		Documentation=man:systemd-crontab-generator(8)
		RefuseManualStart=true
		RefuseManualStop=true
		SourcePath=/etc/crontab
		OnFailure=cron-failure@%i.service

		[Service]
		Type=oneshot
		IgnoreSIGPIPE=false
		ExecStart=/run/systemd/generator/cron-e4d207c1785ce315b682c502550a0b47.sh
		Environment="MAILTO=root"
		Environment="PATH=/etc/cron.jobs:/sbin:/bin:/usr/sbin:/usr/bin"
		Environment="SHELL=/bin/bash"
		```
	- **File: .timer**
		```
		[Unit]
		Description=[Timer] "*/2 * * * * root /usr/bin/echo "$(/usr/bin/date) - $USER - cron" >> /tmp/date.log"
		Documentation=man:systemd-crontab-generator(8)
		PartOf=cron.target
		RefuseManualStart=true
		RefuseManualStop=true
		SourcePath=/etc/crontab

		[Timer]
		Unit=cron-e4d207c1785ce315b682c502550a0b47.service
		OnCalendar= *-*-* *:0,2,4,6,8,10,12,14,16,18,20,22,24,26,28,30,32,34,36,38,40,42,44,46,48,50,52,54,56,58,59:00
		```
	- **File: .sh**
		```
		#!/bin/bash
		/usr/bin/echo "$(/usr/bin/date) - $USER - cron" >> /tmp/date.log
		```

## Conclusión personal

He creido conveniente elaborar un pequeño escrito final en el que daba a 
conocer mi opinion personal sobre la utilidad de substituir `Cron` por 
`Systemd`. Ya que en este momento es totalmente posible que `Systemd` 
substituya a `Cron`, pero personalmente después de realizar la 
investigación y dedicarle horas en comprender como hacer la conversión 
de una tecnologia a la otra he llegado a la conclusión que cara al 
adminsitrador del sistema es mucho mas sencillo y comodo seguir usando 
`Cron`. Tiene una sintaxis mas simple en comparación a `Systemd` y 
a diferencia que `Systemd` que necesita como minimo configurar 2 
ficheros, `Cron` puede configurar tareas usando solamente una linea en 
un fichero. He encontrado una aplicación que te convierte las tareas de 
`Cron` a `Systemd`, creo que puede ser útil para sacarte de un apuro. En 
mi opinion si debes usar `Systemd` deberías conocer la sintaxis y 
generar tu los archivos manualmente, para evitar errores y malos 
funcionamientos.
