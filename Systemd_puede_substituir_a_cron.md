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
administrar la red.

#### Configuración Servidor

#### Configuración Cliente

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
esta configurada en el personal de un usuario, usaremos el comando 
`crontab -e` para editarlo.

**Cron**

```
[user@hostname ~]# crontab -e
*/2 * * * * /usr/bin/echo "$(/usr/bin/date) - $USER - cron" >> /tmp/date.log
```

Para hacer la conversion de `Cron` a `Systemd` crearemos dos ficheros en
**/etc/systemd/system/**, con el nombre de **echo_date.service** y 
**echo_date.timer**.

**Systemd**

```
File: /etc/systemd/system/echo_date.service
# Servicio creado para sustituir la tarea en Cron con la siguiente 
# sintaxis:
# */2 * * * * /usr/bin/echo "$(/usr/bin/date) - $USER - cron" >> /tmp/date.log
#

[Unit]
Description=Insertar fecha y usuario en un fichero en tmp.

[Service]
Type=oneshot
ExecStart=/usr/bin/sh -c '/usr/bin/echo "$(/usr/bin/date) - $USER - Systemd" >> /tmp/date.log'

///////////////////////////////////////////////////////////////////////

File: /etc/systemd/system/echo_date.timer
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

#### Ejemplo2
