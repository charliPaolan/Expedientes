---
id: version-1.3.0-guia-aumentando-recursos
title: Aumentando Recursos
sidebar_label: Aumentando recursos
original_id: guia-aumentando-recursos
---

# Aumentar tamaño de memoria para Araí Docs

Para los entornos productivos de SEEI, es necesario ampliar los valores `memory_limit` y `post_max_size` en PHP para el servicio de Arai-documentos ya que en ocasiones pueden resultar demasiado contenidos. 

El objetivo es modificar el parámetro `memory-limit` de PHP en el deploy de Arai-Documentos. 

A tal efecto vamos a crear la carpeta `./prod/arai/config` y dentro esa carpeta creamos el archivo de texto `custom_php.ini`.

El contenido del archivo `custom_php.ini` debe ser:

```ìni
memory_limit = 1024M
post_max_size = 256M
```

(Debe estar expresado siempre en megas, y pueden ser estos valores o el límite que necesite).

> Nota: Los recursos que se modifican en esta guia tienen como tope los asignados al contenedor durante la definición del servicio.


Luego de guardar el archivo y dentro de la carpeta `./prod` vamos a crear el config de docker para poder modificar la configuración del deploy.

```bash
docker config create php_memory_limit ./config/custom_php.ini
```

Luego vamos a editar el archivo `docs.yml` y al final del mismo vamos a agregar las siguientes líneas para vincular el config creado con el deploy (respetando la indentación, siempre con espacios y no con tabs).

```yaml
configs:
  php_memory_limit:
    external: true
```

En el mismo archivo para el servicio `api`, vamos a agregar la vinculación del config con el archivo de configuración de PHP respetando la indentación igual que en el caso anterior.

```yaml
services:
 api:
  configs:
    source: php_memory_limit
    target: /etc/php7/conf.d/app.ini
```

El último paso va a ser re-deployar el stack de arai-documantos, para que se actualice el contenedor.

En caso de querer modificar algún otro parámetro de php, la secuencia sería la siguiente:

 - Modificar el archivo creado `custom_php.ini` agregando el parámetro deseado
 - Borrar el config creado mediante `docker config rm php_memory_limit`
 - Crear nuevamente el config con el archivo modificado como se indico anteriormente 
 - Volver a deployar el stack

