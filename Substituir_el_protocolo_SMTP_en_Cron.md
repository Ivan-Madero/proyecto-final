# Substituir el protocolo SMTP por Journal en Cron

`Cron` por defecto usa el protocolo SMTP para generar el log de los
resultados de sus tareas programadas. Creo que este sistema es un poco 
anticuado y debe actualizarse, para ello redirigiremos la salida de sus
resultados a Journal, y finalmente para adecuarlo a un entorno de trabajo
centralizaremos el log de diferentes host en uno solo.

## Configurar el OUTPUT de Cron en Journal

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

## Centralizar los logs

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

### Configuración Servidor

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

### Configuración Cliente

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

### Resultado de la configuración

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
