---
id: version-1.1.0-pilaga
title: SIU-Pilagá
sidebar_label: SIU-Pilagá
original_id: pilaga
---

## Configurar SIU-Pilagá
En este apartado se presenta la documentación para preparar una instalación de SIU-Pilagá existente para que pueda interoperar con Araí y Sudocu.

### Registrar SIU-Pilagá como Service Provider en Araí Usuarios

Para hacerlo debe acceder a manejador de usuarios y seguir estos pasos:

1. Ingrese a Araí-Usuarios (user `admin` y password seteado [anteriormente](../arai#bootstraping-del-proyecto))
1. Dirigirse al item Aplicaciones
1. Presionar el botón `Agregar +`
1. Completar de la siguiente manera el tab `Datos Generales`
   * Url: https://universidad.edu.ar/pilaga
   * Nombre: pilaga
   * Cómo ícono colocar esta imagen: https://hub.siu.edu.ar/siu/expedientes/-/blob/master/var/logos/pilaga.png
1. Completar de la siguiente manera el tab `SAML`
   * Chequear la opción `Activo`
   * Entity Id: https://universidad.edu.ar/pilaga/default-sp
   * Assertion Consumer Serv.: https://universidad.edu.ar/pilaga/?acs
   * Single Logout Serv.: https://universidad.edu.ar/pilaga/?sls
1. Presionar el botón `Guardar`

>La URL `https://universidad.edu.ar/pilaga` usada como ejemplo es la url de acceso a la instalación existente de SIU-Pilagá es la misma que se encuentra en el archivo `instancia.ini` como `full_url` 

### Sincronizar cuentas de usuarios

#### Exportar cuentas de usuarios de Pilagá
Para exportar las cuentas de usuario de SIU-Pilagá que luego serán importadas en Araí-Usuarios se debe ejecutar el siguiente comando sobre la instalación de Pilagá:

```bash
toba proyecto exportar_usuarios_arai -p pilaga -f usuarios_pilaga
```

Este comando genera un archivo JSON con las cuentas de usuario de Pilagá. Si se verifica que este archivo contiene los datos del nombre y apellido de forma incorrecta se puede usar el parámetro `--mascara` para modificar el formato de los datos exportados.
 
Por ejemplo:
```bash
toba proyecto exportar_usuarios_arai --mascara '<apellido> <nombres>' -p pilaga -f usuarios_pilaga
```

>Se debe verificar el JSON generado y tener en cuenta que en la sección `accounts` el valor del atributo `appName` debe coincidir con el nombre de la aplicación de SIU-Pilagá generado en el [paso anterior](pilaga#registrar-siu-pilaga-como-service-provider-en-araí-usuarios)
Si el valor no coincide, se recomienda modificar el nombre de la aplicación antes de realizar la importación, de lo contrario no se vincularán las cuentas correctamente.


#### Importar cuentas en Araí-Usuarios

En primer lugar es necesario correr el contenedor que permite realizar tareas administrativas sobre la instalación de Araí-Usuarios.
Para esto se debe realizar el deploy de [`usuarios_cmd.yml`](https://hub.siu.edu.ar/siu/expedientes/-/blob/master/prod/arai/util/usuarios_cmd.yml) de la sgte forma:

```bash
docker stack deploy  --with-registry-auth  -c prod/arai/util/usuarios_cmd.yml usr-cmd
```

Dicho servicio requiere que el nodo que ejecuta los comandos Docker y además tiene el contenido clonado del repositorio, agregarle el `labels.cmd=usuarios` para que el servicio `usuarios_cmd` se inicie y acceda al directorio `files`:

```bash
NODE_NAME=$(docker info --format '{{ .Name }}')
docker node update --label-add cmd=usuarios $NODE_NAME
```

Luego se debe copiar el JSON con las cuentas exportadas al directorio [`prod/arai/util/files`](https://hub.siu.edu.ar/siu/expedientes/-/blob/master/prod/arai/util/files) ya que este directorio es accesible desde dentro del contenedor.

Una vez copiado el JSON es necesario conectarse al contenedor.

```bash
docker exec -it ID_CONTENEDOR_USR_CMD bash
```

Dentro del contenedor se deben ejecutar los siguientes comandos para setear las variables de entorno y finalmente importar las cuentas a Araí-Usuarios

```bash
source /entrypoint.sh --export-secrets && set +e

./idm/bin/toba proyecto importar_usuarios_arai -f files/usuarios_pilaga.json -m 2  -p arai_usuarios
```

Para conocer en detalle el funcionamiento de la importación de cuentas y sus parámetros puede visitar la documentación de [`Araí-Usuarios`](https://documentacion.siu.edu.ar/usuarios/docs/cache/guia-importacion-usuarios-cuentas/)

### Configurar parámetros SAML en SIU-Pilagá

- Editar el archivo `instalador.env` las siguientes líneas:

```dotenv
###### CONFIG SP ONE LOGIN ######
SSO_SP_IDP_METADATA_URL=https://uunn.local/idp/saml2/idp/metadata.php
SSO_SP_IDP_URL_SERVICE=https://uunn.local/idp/saml2/idp/SSOService.php
SSO_SP_IDP_SINGLE_LOGOUT_URL_SERVICE=https://uunn.local/idp/saml2/idp/SingleLogoutService.php
SSO_SP_IDP_PUBLIC_KEY_FILE=/usr/local/siu/pilaga/temp/certificado_idp.crt
SSO_SP_ATRIBUTO_USUARIO=defaultUserAccount
SSO_SP_PERMITE_LOGIN_TOBA=0
SSO_SP_AUTH_SOURCE=default-sp
SSO_SP_COOKIE_NAME=TOBA_SESSID
SSO_SP_IDP_NAME=https://uunn.local
```

A continuación se explica cada parámetro:


* **`SSO_SP_IDP_METADATA_URL:`** URL del IDP donde estén accesibles los metadatos `https://service.example.com/idp.metadata`
* **`SSO_SP_IDP_URL_SERVICE:`** URL del IDP donde esté accesible el servicio `http://service.example.com/simplesaml/saml2/idp/SSOService.php`
* **`SSO_SP_IDP_SINGLE_LOGOUT_URL_SERVICE:`** URL para cerrar sesión en el IDP `http://service.example.com/simplesaml/saml2/idp/SingleLogoutService.php`
* **`SSO_SP_IDP_PUBLIC_KEY_FILE:`** Ruta al archivo del certificado público usado para firmar los tokens SAML en el IDP generado [aquí](../arai#generar-certificados)
* **`SSO_SP_ATRIBUTO_USUARIO:`** El atributo del IDP que contiene el identificador de usuario:  En este caso se debe usar `defaultUserAccount`
* **`SSO_SP_PERMITE_LOGIN_TOBA:`** Si se activa el login interno del proyecto vía Toba. Posibles valores `0 y 1` 
* **`SSO_SP_AUTH_SOURCE:`** El auth source del SP, por defecto suele ser `default-sp`
* **`SSO_SP_COOKIE_NAME:`** Nombre de la cookie manejada por OneLogin, por ej. `TOBA_SESSID` 
* **`SSO_SP_IDP_NAME:`** Nombre del IDP `service.example.com`

Luego de configurar las variables de entorno ejecutar el comando de reconfiguración del instalador:

```bash
./bin/instalador proyecto:reconfigurar sso
```

Luego de ejecutar el comando de reconfigurar nos tiene que quedar configurado de esta forma el archivo `instalacion/instalacion.ini`:

```bash
autenticacion = "saml_onelogin"
vincula_arai_usuarios = "1"
```

>Se debe agregar el parámetro `vincula_arai_usuarios = "1"` que no lo genera automáticamente.

También se genera el archivo de configuración `instalacion/saml_onelogin.ini` con la siguiente configuración: 

```bash
[basicos]
permite_login_toba = "0"
atributo_usuario = "defaultUserAccount"

[sp]
auth_source = "default-sp"
session.phpsession.cookiename = "TOBA_SESSID"
idp = "https://uunn.local/idp/saml2/idp/metadata.php"
proyecto_login = "pilaga"

[idp:https://uunn.local/idp/saml2/idp/metadata.php]
SingleSignOnService = "https://uunn.local/idp/saml2/idp/SSOService.php"
SingleLogoutService = "https://uunn.local/idp/saml2/idp/SingleLogoutService.php"
certFile = "/usr/local/siu/pilaga/instalacion/idp.crt"
```

>En la versión 3.6.1 o anterior no genera automáticamente el valor del `proyecto_login` y se debe configurar manualmente. En posteriores versiones se incluirá la automatización del mismo.

### Forzar uso de HTTPS

Se debe verificar que SIU-Pilagá este configurado para funcionar sobre HTTPS.

Para esto se deber verificar y modificar que el parámetro `TOBA_FORZAR_HTTPS` se encuentre en el archivo `instalador.env` con el valor en `on`.

```dotenv
TOBA_FORZAR_HTTPS=on
```

Luego regenerar la configuración de TOBA con el comando:

```bash
./bin/instalador proyecto:reconfigurar toba
```

Se puede verificar que se ha configurado correctamente chequeando en el archivo `instalacion/web_server.ini` que el parámetro `https` se encuentre en `on`.

```ini
[server_config]
https = "on"
```

### Habilitar API de Arai-Usuarios

Se debe agregar un nuevo usuario y contraseña para que Pilagá se autentifique contra la API de Araí-Usuarios.
Para esto se debe seguir los pasos indicados [aquí](../arai#habilitar-acceso-api-de-usuarios).

Como Pilagá es un sistema externo, se debe habilitar además el acceso desde afuera del cluster a dicha API de Araí-Usuarios.

### Configurar el cliente de usuarios en SIU-Pilagá

En la instalación de SIU-Pilagá se debe configurar el archivo `instalacion/i__produccion/p__toba_usuarios/rest/rest_arai_usuarios/cliente.ini` para indicar los datos de acceso a la API de Araí-Usuarios creados en el paso anterior.

Puede ser configurado mediante el comando de Toba o editando el archivo manualmente.

```bash
./bin/toba servicios_web cli_configurar -p toba_usuarios -s rest_arai_usuarios -u https://uunn.local/api-usuarios/v1/usuarios --usuario USR_API_USUARIOS --usuario_pwd PASSWORD_API_USUARIOS --tipo_ws rest
```

Luego de ejecutar el comando el archivo `cliente.ini` quedaría configurado de la siguiente forma:

```ini
[conexion]
to = "https://uunn.local/api-usuarios/v1/usuarios"
auth_tipo = "basic"
auth_usuario = "USR_API_USUARIOS"
auth_password = "PASSWORD_API_USUARIOS"
```

>Recuerde que es muy importante que las contraseñas utilizadas sean seguras.

A partir de la versión 3.6.0 de SIU-Pilagá se debe indicar el `appUniqueId` en el archivo `instalacion/instalacion.ini` como se indica a continuación:
```bash
vincula_arai_appID = 'APP_UNIQUE_ID_PILAGA'
```

- **`APP_UNIQUE_ID_PILAGA:`** Es el identificador de aplicación de SIU-Pilagá en Araí-Usuarios. Este valor se puede obtener desde el listado de Aplicaciones en Araí-Usuarios en la columna `appUniqueId`. 


### Habilitar el REST de notificaciones

Se debe verificar que SIU-Pilagá esté configurado el método de autenticación del servidor.

Para esto se debe verificar y modificar que el parámetro `REST_SERVIDOR_AUTH` que se encuentra en el archivo `instalador.env` con la opción que corresponda `basic|digest|ssl`.

```dotenv
REST_SERVIDOR_AUTH=basic
```
Luego regenerar la configuración de TOBA con el comando:

```bash
./bin/instalador proyecto:reconfigurar api-rest
```

Se puede verificar que se ha configurado correctamente chequeando en el archivo `instalacion/i__produccion/p__pilaga/rest/servidor.ini` 

```ini
autenticacion = "basic"
```

SIU-Pilagá dispone de un servicio REST utilizado por Araí-Documentos para informar cuando existen cambios en los estados de los documentos exportados.

Para que este servicio sea accesible se debe agregar la siguiente configuración en el archivo `instalacion/i__produccion/p__pilaga/rest/servidor.ini`
```ini
[settings]
formato_respuesta = "json"
url_protegida = "/(?=^((?!notificaciones).)+$)/xs"
encoding = "utf-8"
```

### Configurar los parámetros para Araí-Documentos en SIU-Pilagá

se debe configurar las siguientes variables de entorno en el archivo `instalacion.env`

##### CONFIG API DOCUMENTOS #####
DOCUMENTOS_HOST=https://uunn.local/docs
DOCUMENTOS_USUARIO=USUARIO_API_DOCUMENTOS
DOCUMENTOS_CLAVE=PASS_API_DOCUMENTOS

Se generaría el archivo `instalacion/arai_documentos.ini`:

A continuación se explica cada parámetro:

* **`DOCUMENTOS_HOST:`** Es la ruta a la API de **Araí-Documentos**
* **`DOCUMENTOS_USUARIO:`** Usuario de acceso a la API de **Araí-Documentos**  
* **`DOCUMENTOS_CLAVE:`** Contraseña de acceso a la API de **Araí-Documentos**

Luego de configurar las variables de entorno ejecutar el comando de reconfiguración del instalador:

```bash
./bin/instalador proyecto:reconfigurar api-rest
```

Luego de ejecutar el comando de reconfigurar nos tiene que quedar configurado de esta forma el archivo `instalacion/arai_documentos.ini`:


### Habilitar API Backend de Araí-Documentos

Se debe agregar un nuevo usuario y contraseña para que Pilagá se autentifique contra la API de Araí-Documentos.
Para esto se debe seguir los pasos indicados [aquí](../arai#habilitar-acceso-api-backend-de-documentos).

Como Pilagá es un sistema externo, se debe habilitar además el acceso desde afuera del cluster a dicha API de Araí-Documentos.

### Worker de Documentos

SIU-Pilagá dispone de un proceso que se encarga de enviar de forma asíncrona los documentos exportados, así como de actualizar el estado de los mismos.

Este proceso denominado "worker" se debe mantener corriendo continuamente. 
Para esto se puede utilizar un sistema de control de procesos como Supervisor (http://supervisord.org/).

El comando de Pilagá que inicia el worker de documentos es:
```bash
bin/toba proyecto iniciar_workers_documentos -p pilaga
```

A continuación se presenta un ejemplo de un archivo de configuración de Supervisor para correr el worker de documentos. Pero si se utilizará esta herramienta se recomienda leer su [`documentacion`](http://supervisord.org/) para configurarlo.


```
[program:pilaga-worker-documentos]
command=<path_instalacion_pilaga>/bin/toba proyecto iniciar_workers_documentos -p pilaga
autostart=true
autorestart=true
stderr_logfile=/var/log/pilaga-worker-documentos-err.log
stderr_logfile_maxbytes=2MB
stderr_logfile_backups=10
stderr_capture_maxbytes=1MB
stdout_logfile=/var/log/pilaga-worker-documentos-stdout.log
stdout_logfile_maxbytes=10MB
stdout_logfile_backups=10
stdout_capture_maxbytes=1MB
```

### Archivos de logs

#### Log de documentos-cli
Documentos-cli es el cliente que se encarga de la comunicación con Araí-Documentos.

Su archivo de log se configura la ubicación en el archivo `instalacion/arai_documentos.ini` en la entrada `logs_dir`, por defecto se encuentra en `/usr/local/siu/pilaga/logs/docs-cli.log`

#### Log de librería queue

La librería `queue` es la que se encarga de procesar las transacciones que ocurren entre SIU-Pilagá y Araí-Documentos.
Es el archivo de log más importante a analizar para detectar el origen de algún error.

Su archivo de log se encuentra en `instalacion/i__produccion/p__pilaga/logs/queue.log`
