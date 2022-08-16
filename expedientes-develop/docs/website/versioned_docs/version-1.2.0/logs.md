---
id: version-1.2.0-logs
title: Logs
sidebar_label: Logs
original_id: logs
---

Sin importar el tipo de aplicación que se esté desplegando los logs siempre son una pieza importante de la solución.
En entornos de microservicios son todavía más importantes. 

La forma más popular de resolver el problema de centralización y visualización de logs es a través del stack [ELK](https://www.elastic.co/what-is/elk-stack). Esta solución es muy robusta y provee muchas features, pero su operación, en especial Elastic Search, es bastante compleja. Por eso, si no se cuenta con un stack ELK como servicio, quizá sea mejor analizar otras opciones.

Otra solución que está ganando tracción es [Grafana Loki](https://grafana.com/oss/loki/). Esta solución hace foco en la facilidad de operación a costa de indexar los logs sobre labels en vez de hacer full-text-search.

A continuación se muestra una forma de realizar una instalación funcional mínima de Loki y Grafana, ya que es la herramienta con la que venimos trabajando. Vale la pena aclarar, que si en su institución se decide ir por alguna otra solución sería bueno que comparta su experiencia con la comunidad.

### Modificación de dominio base
Ejecute el siguiente comando para hacer el cambio de dominio base desde el directorio `prod/servicios`:
```bash
export DOMAIN_NAME_URL=universidad.edu.ar
sed -i "s/uunn\.local/${DOMAIN_NAME_URL}/g" \
    loki.yml
```
### Crear secret
La clave de grafana se puede generar con
```bash
printf 'grafanapassword' | docker secret create grafana_pass -
```
o mediante el `./arai/secrets.sh.dist` con el resto de las claves

### Acceso desde otras redes
Por default Grafana solo soporta acceso local. para setear las redes desde las cuales necesita acceder puede editar `loki.yml` la sección
```bash
        - "traefik.http.middlewares.grafana-ipwhitelist.ipwhitelist.sourcerange=127.0.0.1/32,<IP-RED/MASCARA>"
```
reemplace <IP-RED/MASCARA> por la IP o RED a autorizar el acceso

## Instalación mínima de Loki
En el directorio `servicios` se incluye un stack mínimo de deploy de Loki. Para utilizarlo, ejecute:
```bash
docker stack deploy -c loki.yml loki
```
Esto dejará disponibles en el puerto `3000` una instancia de Grafana y en el puerto `3100` una instancia de Loki.
> El puerto 3100 no se debe poder acceder desde fuera de la red local ya que por defecto no tiene autenticación.

Es importante notar que incluye un volumen llamado `log-data`. Este volumen es el que se debe backupear para salvar
la historia de logs.  
Y un volumen llamado `grafana-data`. Este volumen es el que debe backupear para salvar la configuración, usuarios y dashboards de Grafana.

## Acceso a la app
Para puede acceder a la aplicación desde el navegador `universidad.edu.ar/metricas` con usuario admin y la clave seteada como secret

Siga las instrucciones en https://github.com/grafana/loki/blob/v1.5.0/docs/getting-started/grafana.md#loki-in-grafana para poder ver los logs a través de Grafana.

### Configurar daemon de Docker
La forma más simple de empezar a alimentar a Loki es instalando el plugin provisto por Grafana y haciendo que Docker envíe todos los logs hacia la instancia de Loki anteriormente creada. Siga la siguiente documentación para hacerlo: https://github.com/grafana/loki/blob/v1.5.0/docs/clients/docker-driver/README.md.

Esta configuración hay que hacerla en *cada nodo del cluster*. Una vez realizada la configuración puede comenzar a utilizar la UI provista por Grafana para inspeccionar los logs.

> Esta instalación **NO** es escalable horizontalmente ya que utiliza un backend de Storage (BoltDB) que no lo soporta. Es decir, no puede haber más de 1 replica del servicio. Si esto es deseable, por el momento puede referirse a la documentación de Loki: https://github.com/grafana/loki/tree/v1.5.0/docs.


### Visualización de logs
Si todo funcionó correctamente, a medida que vaya interactuando con los contenedores de su clúster los logs empezarán a aparecer en Grafana. Por defecto se puede filtrar por las siguientes categorías:
![Log Labels](assets/loki1.jpeg)

También puede construir queries bastante más ricas utilizando el lenguaje provisto por la herramienta, llamado [LogQL](https://github.com/grafana/loki/blob/master/docs/logql.md)
