# Substituir Cron por Systemd

`Systemd.timers` son unos temporizadores bajo el control de `Systemd`,
estos pueden sustituir el uso de `Cron`. Sus archivos de configuración
terminan en **.timer** y controlan los archivos o eventos de **.service**.
Los temporizadores tienen soporte incorporado para eventos de tiempo de
calendario, eventos de tiempo monótonos y se puede ejecutar de forma 
asíncrona.

Como cualquier tecnología tiene sus ventajas y desventajas:

**Ventajas**
- Se pueden iniciar fácilmente independientemente de los temporizadores.
- Se pueden configurar para ejecutarse en un entorno específico.
- Se pueden adjuntar trabajos a **cgroups**.
- Se pueden configurar para depender de otras unidades `Systemd`.
- Los trabajos se registran en el diario de `Systemd` para facilitar la
depuración.

**Desventajas**
- Algunas cosas que son fáciles con `Cron` son muy complejas con 
`Systemd`.
- Complejidad: Se deben configurar 2 ficheros, **.timers** y **.service**.
- No hay equivalentes incorporados a MAILTO de `Cron`.

Para poder configurar las tareas que realizamos en `Cron` con `Systemd`
debemos aprender a definir los archivos **.service** y los **.timer**. 

## Archivos .service

Crearemos estos ficheros en el directorio: **/etc/systemd/system/**.

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

### \[Unit\]

Contiene información genérica sobre la unidad independientemente del 
tipo de unidad que sea.

Algunos elementos que pueden definirse en este apartado son:
- **Description=** Una cadena de texto que describe la unidad, la
descripción debe contener un nombre que signifique algo para el usuario
final. Ej. "Apache2 Web Server" es un buen ejemplo, no es demasiado 
genérico y tampoco demasiado específico.
- **Documentation=** Una lista de URLs separados por espacios 
referenciando la documentación o la configuración de la unidad.
- **Requires=** Configura dependencias de otras unidades, si estas no 
están activadas la unidad no podrá activarse.
- **OnFailure=** Lista de unidades que se activarán cuando esta entre
en estado fallido.
- **SourcePath=** Una ruta de acceso a un archivo de configuración de 
esta unidad.

Para más información recomiendo consultar el `man 5 systemd.unit` o 
[Manual Web](https://www.freedesktop.org/software/systemd/man/systemd.unit.html#%5BUnit%5D%20Section%20Options).

### \[Service\]

Este apartado es específico de los achivos de unidades **.service**. Y 
puede contener algunos de los siguientes elementos:
- **ExecStart=** Comandos con sus argumentos que se ejecutan cuando se 
inicia este servicio.
- **ExecStartPre=** Comando adicional que se ejecutará antes del 
`ExecStart=`.
- **ExecStartPost=** Comando adicional que se ejecutará después del 
`ExecStart=`.
- **ExecReload=** Comando que se ejecutará cuando se realice un reload.
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

Para más información recomiendo consultar el `man systemd.service` o 
[Manual Web](https://www.freedesktop.org/software/systemd/man/systemd.service.html#Options).

### \[Install\]

Los archivos de unidades pueden incluir este apartado, que contiene 
información de la instalación de la unidad. Esta sección no es 
interpretada por `Systemd` durante el tiempo de ejecución, es 
interpretada al usarse los comandos `# systemctl enable/disbale`.

La lista de elementos que puede contener este apartado es el siguiente:
- **Alias=** Una lista separada por espacios de los nombres que tendrá
la unidad al instalarse. No compatible con las unidades de tipo: mount, 
slice, swap y automount. 
- **WantedBy=** Se creará un enlace simbólico de la unidad en los .wants
especificados, puede aparecer más de una vez o contener una lista 
separada por espacios.
- **RequiredBy=** Se creará un enlace simbólico de la unidad en los 
.requires especificados, puede aparecer más de una vez o contener una 
lista separada por espacios.
- **Also=** Lista de las unidades adicionales que se instalarán/desintalarán
juntamente con esta unidad.

Para más información recomiendo consultar el `man 5 systemd.unit` o 
[Manual Web](https://www.freedesktop.org/software/systemd/man/systemd.unit.html#%5BInstall%5D%20Section%20Options).

## Archivos .timer

Crearemos estos ficheros en el directorio: **/etc/systemd/system/**.

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
10min desde que la máquina fue arrancada, y posteriormente cada 60min (1h).

Los ficheros de unidades de tipo **.timer** se componen de tres 
apartados \[Unit\], \[Timer\] y \[Install\].

### \[Timer\]

Los archivos de unidades de tipo **.timer** deben contener el apartado 
\[Timer\] que define las configuraciones de los temporizadores, esto 
tienen unos elementos específicos, algunos de esto son:

- **OnActiveSec=** Define un tiempo en relación con el momento en que se
activa el temporizador; `# systemctl start .timer`.
- **OnBootSec=** Define un tiempo en relación a cuando la máquina 
arranca.
- **OnStartupSec=** Define un tiempo en relación a la primera vez que se
arrancó systemd.
- **OnUnitActiveSec=** Define un tiempo en relación a la última vez que 
se activó.
- **OnUnitInactiveSec=** Define un tiempo en relación a la última vez en
que se desactivó.
- **OnCalendar=** Define temporizadores en tiempo real con expresiones
de eventos de calendario. Para más información sombre la sintaxis
consultar el `man 7 systemd.time`o 
[Manual Web](https://www.freedesktop.org/software/systemd/man/systemd.time.html)
- **AccuracySec=** Define el tiempo en el que debe transcurir, el tiempo
que permanecerá encendido.
- **Unit=** La unidad se activará cuando transcurra este temporizador,
la unidad no puede ser **.timer**, si no se especifica la unidad, este
valor pretederminado es un servicio que tiene el mismo nombre de la
unidad del temporizador.
- **Persistent=** Es una valor booleano, si este es `true` cuando se 
active el temporizador si el tiempo de activación ya ha transcurrido se 
ejecutará immediatamente. Al usar `OnCalendar=` el valor por defecto es 
`false`.
- **WakeSystem=** Toma un argumento booleano. Si es cierto, un 
temporizador transcurrido hará que el sistema reanude su suspensión, 
si se suspende y si el sistema lo admite. El valor por defecto es 
`false`.

Para más información consulte el `man sytemd.timer` o 
[Manual Web](https://www.freedesktop.org/software/systemd/man/systemd.timer.html#Options).

## Gestión de los temporizadores

Una vez creados los temporizadores, podemos ponerlos en marcha usando el
comando `# systemctl start name.timer`, cuando la máquina se apague este 
temporizador será apagado, si queremos que sea permanente deberemos 
realizar el siguiente comando, para cada vez que la máquina se encienda 
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

Con este comando podemos ver la próxima activación, cuánto queda para 
esta, la última activación, cuánto ha pasado desde esta, el `.timer` y 
el `.service`.

## Transformar tareas de Cron a Systemd

Para poder transformar una tarea definida por `Cron` a `Systemd` debemos
analizar la tarea y dividarla en qué tiene que hacer y cuándo lo debe 
hacer. Lo que debe hacer se tendrá que definir en un fichero de unidad
de tipo **.service**, mientras que, el cuándo lo debe hacer, debe
definirse en un fichero de unidad tipo **.timer**. A continuación
expondré algunos ejemplos:

### Ejemplo1

En este primer ejemplo obaservaremos un caso muy simple, un `echo` que
cada 2 min escribe en un fichero que se encuentra en **/tmp/date.log**,
una línea con la fecha y hora, el usuario y la palabra cron. Esta tarea
está configurada en el cron personal de un usuario, usaremos el comando 
`crontab -e` para editarlo.

- **Cron**

	```
	[user@hostname ~]# crontab -e
	*/2 * * * * /usr/bin/echo "$(/usr/bin/date) - $USER - cron" >> /tmp/date.log
	```

- **Systemd**

	Para hacer la conversión de `Cron` a `Systemd` crearemos dos ficheros en
	**/etc/systemd/system/**, con el nombre de **echo_date.service** y 
	**echo_date.timer**.

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

### Ejemplo2

En este segundo ejemplo observaremos un caso en que se ejecutará un script,
el cual realizará algunas acciones, cada mes a las 12:00, si alguno de 
los cuatro primeros días del mes caen en lunes.

- **Cron**

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
	**/etc/crontab**. Simplemente para dejar constancia que ambas prácticas 
	son posibles, la utilización de una u otra dependerá de las necesidades 
	y criterios de trabajo. He decidido almacenar este script en un directorio
	que yo he creado, **/etc/crond.jobs** y ha consecuencia he añadido dicho
	directorio al **PATH** del `crontab`.

- **Systemd**

	- **File: /etc/systemd/system/exec-script.service**

		```
		# Servicio creado para sustituir la tarea en Cron con la siguiente 
		# sintaxis: 00 12 1..4 * Mon root script.sh

		[Unit]
		Description=Ejecuta un script.

		[Service]
		Type=oneshot
		ExecStart=/usr/bin/sh -c '/etc/cron.jobs/script.sh'
		```

	- **File: /etc/systemd/system/exec-script.timer**

		```
		# Temporizador para ejecutar cada principio de mes, cuando uno de los 4
		# primeros días cae en Lunes.

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

- **Resultado**

	```
	# Nota: Podría falsear los datos o cambiar los parámetros de ejecución,
	pero creo que no es necesario. Mostraré cuándo está prevista la próxima
	ejecución y la ejecutaré manualmente.

	# Próxima ejecución: Lunes 03/07/2017 a las 12:00:00
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

### Ejemplo3

Este último ejemplo que expongo será útil para entornos de trabajo, para 
que no se queden encendidas las máquinas de los trabajadores después de 
la jornada laboral. La tarea se ejecutará los días laborales 
(lunes - viernes) a las 9:00 PM.

- **Cron**

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

- **Systemd**

	- **File: /etc/systemd/system/shutdown.service**

		```
		# Servicio creado para sustituir la tarea en Cron con la siguiente 
		# sintaxis: 00 21 * * 1..5 root /usr/sbin/shutdown

		[Unit]
		Description=Apaga de forma segura el equipo.

		[Service]
		Type=oneshot
		ExecStart=/usr/sbin/shutdown
		```
	
	- **File: /etc/systemd/system/shutdown.timer**

		```
		# Temporizador para ejecutar en días laborables, de lunes a viernes, a las
		# 21:00.

		[Unit]
		Description=Temporizador de shutdown para los días laborales (Mon-Fri) a 9PM.

		[Timer]
		OnCalendar=Mon-Fri *-*-* 21:00:00
		Unit=shutdown.service

		[Install]
		WantedBy=basic.target
		```

- **Resultado**

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

## Herramientas

### systemd-cron-next

[Pagina Web Oficial](https://github.com/systemd-cron/systemd-cron-next)

En la página web oficial contiene el material y la información necesaria
para la instalación y utilización de este herramienta que su función es 
analizar las tareas definidas en `Crond`, y adecuarlas para que sean 
ejecutadas por `Systemd`. Para su completo funcionamiento requiere de
`run-parts` que normalmente viene incluido con el paquete `crontabs`.

Es la versión actualizada del paquete `systemd-crontab-generator`. 

**NOTA**: Es una versión beta, el autor advierte que no se hace cargo si 
funciona erroneamente.

Hay dos formas de utilizar esta herramienta:

- **Manual**: Puedes usarla de forma manual llamando al comando 
`# /usr/local/lib/systemd/system-generators/systemd-crontab-generator outuput_folder`.
Este analiza los ficheros de tareas de `Cron` y genera su conversión para
`Systemd`. Es recomendable usar rutas absolutas para que los archivos 
generados funcionen correctamente, y la mejor ruta para que el sistema 
pueda hacer uso de ellos es: **/etc/systemd/system/**. El autor recomienda
no usarlo manualmente.

- **Automáticamente**: Para usarlo de esta forma simplemente
ejecutamos el comando: `# systemctl enable cron.target`. Cuando inicie 
el sistema activará todos los **.timer** definidos en 
**/run/systemd/generator/**. Los ficheros que contiene este directorio 
son creados de forma automática por el ejecutable 
`systemd-crontab-generator`, esto sucede cuando el sistema inicia o se 
produce un `systemctl daemon-reload`. Esto es posible gracias a una 
herramienta que contine `Systemd`, `systemd.generator`, que cualquier 
fichero binario que se encuentre en uno de sus directorios asignados se 
ejecutará en el inicio o cada vez que se produzca un 
`systemctl daemon-reload`. Para más información acerca de esta 
herramienta consultar el `man systemd.generator` o 
[Manual Web](https://www.freedesktop.org/software/systemd/man/systemd.generator.html).

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

---

[Volver a la tabla de contenidos](README.md#tabla-de-contenidos)
