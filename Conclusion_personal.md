# Conclusión personal

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
