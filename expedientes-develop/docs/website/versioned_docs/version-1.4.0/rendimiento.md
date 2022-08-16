---
id: version-1.4.0-rendimiento
title: Optimización del rendimiento y recurso
sidebar_label: Rendimiento y recursos
original_id: rendimiento
---

## Optimizar la plataforma

Antes de realizar cualquier ajuste, es recomendable realizar mediciones sobre el desempeño actual, ejerciendo cargas de trabajo 
en los diferentes procesos (subir un archivo de determinado tamaño, enviar a autorizar/firmar, incorporar a un expediente, previsualizar,
etc). 

Es fundamental lograr establecer los parámetros de operación para evitar asignar recursos exesivos y que esto provoque otros inconvenientes
(falta de memoria ram, paginación a disco, saturación de CPU, entre otros).

## Escalabilidad

La solución del ecosistema es escalable en diferentes formas:

* vertical, mediante el incremento de recursos disponibles (CPU, RAM, etc.) al servicio en particular
* horizontal, mediante el despliegue de instancias adicionales del servicio en particular

### Escalabilidad horizontal 

Se refiere a desplegar múltiples instancias de un mismo servicio de un módulo. Por ej, escalar el servicio
**idp** del módulo **arai-usuarios**. Normalmente no presenta límites en cuanto al número de nodos a escalar.

En Docker Swarm, se logra incrementando el número de contenedores para un servicio definido mediante una configuración 
del estilo:

```yaml
    ...
    deploy:
      mode: replicated
      replicas: 2
      restart_policy:
        condition: any
        delay: 10s
        max_attempts: 4
        window: 120s
```

La entrada `replicas` permite establecer la cantidad de contenedores a generar. También es posible hacerlo mediante un 
comando del estilo:

```bash
docker service scale usuarios_api=2
```

En cualquiera de los casos, el efecto se verá reflejado en el número de réplicas del servicio, o lo que es lo mismo la 
cantidad de contenedores en ejecución.

> Atención: no todos los servicios funcionan en forma correcta al ser escalados horizontalmente.

#### Servicios básicos

|servicio|escalable|condiciones requeridas|observaciones|
|--------|---------|----------------------|-------------|
|reverse proxy|si|solo corre en nodos "manager"| |


#### Arai-Usuarios

|servicio|escalable|condiciones requeridas|observaciones|
|--------|---------|----------------------|-------------|
|api|si|requiere storage compartido y sesiones en memcached| |
|idp|si|requiere storage compartido y sesiones en memcached| |
|idm|no|requiere storage compartido y sesiones en memcached | |
|memcached|no| |al escalar, el cliente tiene que apuntar a las nuevas IP del nodo, no es transparente|

#### Arai-documentos

|servicio|escalable|condiciones requeridas|observaciones|
|--------|---------|----------------------|-------------|
|api|si| | |
|worker|no| |requiere implementar un manejador de colas|

#### Huarpe

|servicio|escalable|condiciones requeridas|observaciones|
|--------|---------|----------------------|-------------|
|web|si|requiere sesiones en memcached| |
|memcached|no| |al escalar, el cliente tiene que apuntar a las nuevas IP del nodo, no es transparente|

### Sudocu

|servicio|escalable|condiciones requeridas|observaciones|
|--------|---------|----------------------|-------------|
|login| | | |			
|gestion| | | |
|cache| | | |		
|api-server| | | |
|mpc| | | |
|mpd| | | |
|pdf| | | |

### Escalabilidad vertical

Se logra modicando la asignación de los recursos de CPU y RAM para un servicio en particular. 

En Docker Swarm, se debe modificar los valores en las secciones similares a 

```yaml
    ...
    deploy:
      resources:
        limits:
          cpus: '0.25'
          memory: 128M
        reservations:
          cpus: '0.1'
          memory: 20M
```

La entrada `reservations` especifica los valores "iniciales" de recusos asignados, mientras que la entrada `limits` 
permite configurar el valor máximo. Docker Swarm no asigna recursos pasado este valor.

En esta [guía](guia-aumentando-recursos) se detallan los ajustes particulares a cada módulo para la configuración de recursos que utilizan.


## Alta Disponibilidad

Muchas veces se requiere que un servicio esté disponible sin importar si sufre inconvenientes. 

En parte, esto se logra:

* mediante [escalado horizontal](#escalabilidad-horizontal), desplegando múltiples instancias del mismo servicio
* disponiendo de diferentes nodos del cluster Docker Swarm, de modo que si uno cae otro pueda asumir el servicio
* tolerancia a caídas de diferentes servicios críticos, sin cortes del servicio o pérdidas de datos

> Actualmente lograr alta dispnibilidad o HA puede requerir cambios en el código principalmente en el manejo de sesiones
> de usuario distribuidas.
