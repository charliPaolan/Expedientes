---
id: version-1.1.0-redes
title: Configurar redes y Traefik
sidebar_label: Redes y Traefik
original_id: redes
---

Para desplegar la solucion se necesitan 2 redes: una para el proxy y otra para la comunicación interna entre contenedores que no necesitan acceso a Internet.


### Red del proxy

Todos los contenedores que se conecten a esta red pueden ser publicados. Ejecute:

```bash
docker network create --driver=overlay traefik-public
```
El nombre de la red `traefik-public` está referenciado en los stacks de Docker Swarm que se utilizan mas adelente. Si necesita cambiarlo refleje la modificacion en dicho lugar también.

### Red interna
Para la comunicacion entre los contenedores del cluster. Ejecute:
```bash
docker network create --driver=overlay red-siu
```
El nombre de la red `red-siu` está referenciado en los stacks de Docker Swarm que se utilizan mas adelente. Si necesita cambiarlo refleje la modificacion en dicho lugar también.

## Traefik, Proxy Reverso
Se eligió Traefik 2.2 como proxy reverso. Las razones detrás de esta elección fue su facilidad de uso y su potencial escalabilidad.

En la solución presentada es el que maneja todo el tráfico que ingresa al clúster y provee la terminación de TLS.

Este componente es probablemente el que más customización necesite para adaptarse a la realidad de cada institución. Es importante conocer sobre su funcionamiento. La documentación del proxy es un buen lugar para comenzar https://docs.traefik.io/.

### Rutas por defecto
En esta instalación de referencia se provee un mapeo de rutas que asume que todo está detrás de un sólo dominio, llamado `uunn.local`.

Estas son las rutas levantadas por defecto:
 * `/usuarios`: Araí-Usuarios IdM
 * `/idp`: Araí-Usuarios IdP
 * `/sudocu`: Sudocu
 * `/docs/rest/frontend`: Endpoints públicos de Araí-Documentos
 * `/`: Huarpe

La configuración se hace parte en el archivo `prod/servicios/traefik.yml` y la que es específica de cada módulo como labels dentro del stack que corresponda.

Este mapeo es configurable y adaptable a los requerimientos de su institución. 

### Modificación de dominio base
Ejecute el siguiente comando para hacer el cambio de dominio base desde el directorio `prod/servicios`:
```bash
export DOMAIN_NAME_URL=universidad.edu.ar
sed -i "s/uunn\.local/${DOMAIN_NAME_URL}/g" \
    traefik.le.yml \
    traefik.yml
```

### TLS
La instalación asume que toda la interacción externa con el cluster es realizada sobre TLS. Se proveen dos templates [traefik.yml](https://hub.siu.edu.ar/siu/expedientes/-/blob/master/prod/servicios/traefik.yml) y [traefik.le.yml](https://hub.siu.edu.ar/siu/expedientes/-/blob/master/prod/servicios/traefik.le.yml). El primero es para utilizar certificados provistos a través del sistema de archivos y el segundo es una configuración básica de [generación automática de certificados](https://docs.traefik.io/https/acme/) utilizando [Let's Encrypt](https://letsencrypt.org/). 

#### Certificados existentes
Para utilizar sus certificados pre-existentes es necesario cargar la clave pública como una `config` y la key como un `secret`:
```bash
docker config create traefik_tls_cert servicios/certs/${DOMAIN_NAME_URL}.crt
docker secret create traefik_tls_key servicios/certs/${DOMAIN_NAME_URL}.key
```

> NOTA: Para una prueba rápida se pueden generar certificados [autofirmados](autofirmados.md), sin embargo recuerde revertir tanto `config` como `secret` previo a un deploy productivo. Es responsabilidad del lector la creación y administración de estas claves. Recuerde no comitear la key

#### Let's Encrypt
La instalación utilizando Let's Encrypt asume que se van a obtener certificados para dos dominios, `uunn.local` y `traefik.uunn.local`. Es muy importante entender la [configuración de Traefik](https://docs.traefik.io/https/acme/) en este punto.

> **Por defecto se utiliza la CA de prueba de Let's Encrypt**

De esta manera, se puede probar sin preocuparse por llegar al límite de pedidos. Una vez que vea que el certificado de prueba se expidió correctamente, es momento de comentar las siguientes líneas para utilizar la CA real:

* `certificatesresolvers.le-uunn-local.acme.caserver=https://acme-staging-v02.api.letsencrypt.org/directory`
* `certificatesresolvers.le-traefik-uunn-local.acme.caserver=https://acme-staging-v02.api.letsencrypt.org/directory`

### Headers de Seguridad
Por defecto se incluye un conjunto de headers que dan un comportamiento razonable por defecto. Los headers definidos se pueden ver en el archivo [security.toml](https://hub.siu.edu.ar/siu/expedientes/-/blob/master/prod/servicios/security.toml).

El header `HTTP Strict Transport Security` puede traer algún problema cuando se están obteniendo los certificados de Let's Encrypt la primera vez. Si esto le está sucediendo, lo más simple es comentar estos headers hasta que la obtención se haya realizado con éxito.

### Dashboard
El dashboard de Traefik viene desactivado por defecto. 

Para habilitarlo hay que cambiar la línea `api.dashboard=false` por `api.dashboard=true` en el archivo yml de Traefik que se esté utilizando.

También debe generar una nueva contraseña con el siguiente comando:
```bash
openssl passwd -apr1 unpassseguro
```
Y luego cargarla en el archivo `servicios/traefik.yml` en el label `traefik.http.middlewares.auth.basicauth.users`, escapando los `$`.

Por ejemplo, si el pass generado fue `$apr1$PqXl.pwR$wByD8SWOmiLRuTu9mKUCS/` en el label cargar `$$apr1$$PqXl.pwR$$wByD8SWOmiLRuTu9mKUCS/`.

Por defecto se accede desde `traefik.uunn.local`, si desea, esto también puede modificarlo en el mismo `yml`.

### Desplegar Traefik con certificados propios
```bash
docker stack deploy -c servicios/traefik.yml traefik
```

### Desplegar Traefik con Let's Encrypt
```bash
docker stack deploy -c servicios/traefik.le.yml traefik
```

## Problemas comunes
Las redes creadas a continuación son de tipo `overlay`, es importante notar que debido a limitaciones de Swarm, estas redes están limitadas a 256 IPs. Si el cluster crece es posible que se acaben las IPs disponibles, en especial en la red de Traefik. El comportamiento observado cuando esto sucede es que el servicio nunca se inicia. Una solución es agregar más redes y conectarlas a Traefik.

Más información sobre este tema:
 * https://docs.docker.com/engine/reference/commandline/network_create/#overlay-network-limitations

