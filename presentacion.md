# ¿Systemd puede sustituir Cron?

**Ivan Madero Fernandez**\
Escola del treball\
2º ASIX

---

## 1. Cron y Atd

---

### 1.1 Sintaxis Cron

- **Cron**
	```
	# Example of job definition:
	# .---------------- minute (0 - 59)
	# |  .------------- hour (0 - 23)
	# |  |  .---------- day of month (1 - 31)
	# |  |  |  .------- month (1 - 12) OR jan,feb,mar,apr ...
	# |  |  |  |  .---- day of week (0 - 6) (Sunday=0 or 7)
	# |  |  |  |  |
	# *  *  *  *  * user-name  command to be executed
	```

---

### 1.2 Sintaxis Atd

- **Atd**
	```
	$ at [hora] [fecha]
	at> orden1
	at> orden2
	...
	```

---

### 1.3 Configurar el OUTPUT

Para configurar el **output** hacia **"Journal"** de **Cron** debemos 
modificar con los parámetros que **Cron** se ejecuta.

File: **/etc/sysconfig/crond**

```
# Settings for the CRON daemon.
# CRONDARGS= :  any extra command-line startup arguments for crond
CRONDARGS= -s -m off
```

---

## 2. Centralizar logs de Journal

---

### 2.1 Configuración Cliente

Para configurar los hosts para que envien sus logs a otro con la 
finalidad de centralizarlos, se deben realizar los siguientes pasos:

1. **1-.** Instalar el paquete **systemd-journal-remote**.

2. **2-.** Editar el fichero **/etc/systemd/journal-upload.conf**, deberemos 
configurar el parámetro "URL=". Ej. **URL=http://10.250.100.150:19532**.

3. **3-.** Habilitar el servicio usando el siguiente comando 
**# systemctl enable systemd-journal-upload.service**.

---

### 2.2 Configuración Servidor

Para configurar el host que debe recibir todos los logs, debemos realizar 
los sigueintes pasos:

1. **1-.** Instalar el paquete **systemd-journal-remote**.

2. **2-.** Revisar la configuración del socket del servicio en el fichero: 
**/lib/systemd/system/systemd-journal-remote.socket**.

3. **3-.** Editar la configuración del servicio en el fichero: 
**/lib/systemd/system/systemd-journal-remote.service**, debemos remplazar 
la configuración que por defecto es https por http.

---

### 2.2 Configuración Servidor

4. **4-.** Crear la carpeta definida en parámetro --output= y cambiar su 
propietario por systemd-journal-remote.

5. **5-.** Habilitar el socket con el siguiente comando: 
**# systemctl enable systemd-journal-remote.socket**.

---

## 3. ¿Systemd puede sustituir Cron?

---

### 3.1 Sintaxis Systemd

Para generar las tareas con `Systemd` necesitamos configurar como
minimo 2 ficheros:

- Un fichero **.service**, con sus elementos:
	- **\[Unit\]**
	- **\[Service\]**
	- **\[Install\]**

---

### 3.1 Sintaxis Systemd

- Un fichero **.timer**, con sus elementos:
	- **\[Unit\]**
	- **\[Timer\]**
	- **\[Install\]**
	
---

### 3.2 Ventajas y Desventajas

**Ventajas**

- Se pueden iniciar fácilmente independientemente de los temporizadores.

- Se pueden configurar para ejecutarse en un entorno específico.

- Se pueden configurar para depender de otras unidades Systemd.

---

### 3.2 Ventajas y Desventajas

**Desventajas**

- Algunas cosas que son fáciles con Cron son muy complejas con Systemd.

- Complejidad: Se deben configurar 2 ficheros, .timers y .service.

- No hay equivalentes incorporados a MAILTO de Cron.
 
---

### 3.3 Conversión de Systemd a Cron

Para convertir las tareas de **Cron** a **Systemd** debemos dividir:

- "el que hace": Este apartado lo definiremos en el fichero 
**.service**

- "cuando lo hace": Lo definieremos en el fichero **.timer**

---

### 3.4 systemd-cron-next

La herramienta que he encontrado que automatiza esta tarea se llama 
**systemd-cron-next**

El autor la ha documentado en su github: [link](https://github.com/systemd-cron/systemd-cron-next)

---

### 3.4 systemd-cron-netx

Se puede utilizar de forma manual o automática:

- **Manual**: no es recomendada por el autor, simplemente debemos ejecutar
el ejecutable **# /usr/local/lib/systemd/system-generators/systemd-crontab-generator outuput_folder**.

- **Automática**: Para usar dicha configuración simplemente ejecutas, 
**# systemctl enable cron.target**. Se encarga de hacerle el 'start' a 
los fichero **.timer** situados en el directorio **/run/systemd/generator/**.

---

