---
id: version-1.2.2-sq-nucleo
title: SIU-Sanavirón-Quilmes-Núcleo
sidebar_label: SQ-Núcleo
original_id: sq-nucleo
---

## Configurar SIU SQ-Núcleo
En este apartado se presenta la documentación para preparar una instalación de SIU-SQ-Núcleo existente para que pueda interoperar con Araí.

### Registrar SIU SQ-Núcleo como Service Provider en Araí Usuarios

Para hacerlo debe acceder a manejador de usuarios y seguir estos pasos:

1. Ingrese a Araí-Usuarios (user `admin` y password seteado [anteriormente](../arai#bootstraping-del-proyecto))
1. Dirigirse al item Aplicaciones
1. Presionar el botón `Agregar +`
1. Completar de la siguiente manera el tab `Datos Generales`
   * Url: https://universidad.edu.ar/sq_nucleo
   * Nombre: sq_nucleo
   * Cómo ícono colocar esta imagen: https://hub.siu.edu.ar/siu/expedientes/-/blob/master/var/logos/sq_nucleo.png
1. Completar de la siguiente manera el tab `SAML`
   * Chequear la opción `Activo`
   * Entity Id: https://universidad.edu.ar/sq_nucleo/default-sp
   * Assertion Consumer Serv.: https://universidad.edu.ar/sq_nucleo/?acs
   * Single Logout Serv.: https://universidad.edu.ar/sq_nucleo/?sls
1. Presionar el botón `Guardar`

>La URL `https://universidad.edu.ar/sq_nucleo` usada como ejemplo es la url de acceso a la instalación existente de SIU SQ-Núcleo

### Sincronizar cuentas de usuarios

#### Exportar cuentas de usuarios de SQ-Núcleo
Para exportar las cuentas de usuario de SIU SQ-Núcleo que luego serán importadas en Araí-Usuarios se debe ejecutar el siguiente comando sobre la instalación de SQ-Núcleo:

```bash
toba proyecto exportar_usuarios_arai -p sq_nucleo -f usuarios_sq_nucleo
```

Este comando genera un archivo JSON con las cuentas de usuario de SQ-Núcleo. Si se verifica que este archivo contiene los datos del nombre y apellido de forma incorrecta se puede usar el parámetro `--mascara` para modificar el formato de los datos exportados.
 
Por ejemplo:
```bash
toba proyecto exportar_usuarios_arai --mascara '<apellido> <nombres>' -p sq_nucleo -f usuarios_sq_nucleo
```

>Se debe verificar el JSON generado y tener en cuenta que en la sección `accounts` el valor del atributo `appName` debe coincidir con el nombre de la aplicación de SQ-Núcleo generado en el [paso anterior](sq-nucleo#registrar-siu-sq-núcleo-como-service-provider-en-araí-usuarios)
Si el valor no coincide, se recomienda modificar el nombre de la aplicación antes de realizar la importación, de lo contrario no se vincularán las cuentas correctamente.


#### Importar cuentas en Araí-Usuarios

En primer lugar es necesario correr el contenedor que permite realizar tareas administrativas sobre la instalación de Araí-Usuarios.
Para esto se debe realizar el deploy de [`usuarios_cmd.yml`](https://hub.siu.edu.ar/siu/expedientes/-/blob/master/prod/arai/util/usuarios_cmd.yml) de la sgte forma:

```bash
docker stack deploy  --with-registry-auth  -c prod/arai/util/usuarios_cmd.yml usr-cmd
```

>Se debe tener en cuenta que en clusters con más de un nodo es importante utilizar el constraint `constraints: [ node.hostname == hostname-actual ]` para lograr que el contenedor se ejecute en el mismo nodo que se ejecuta el stack deploy. Sin embargo en clusters con sólo un nodo esto no es necesario y puede ser eliminado del archivo `usuarios_cmd.yml` antes de realizar el deploy

Luego se debe copiar el JSON con las cuentas exportadas al directorio [`prod/arai/util/files`](https://hub.siu.edu.ar/siu/expedientes/-/blob/master/prod/arai/util/files) ya que este directorio es accesible desde dentro del contenedor.

Una vez copiado el JSON es necesario conectarse al contenedor.

```bash
docker exec -it ID_CONTENEDOR_USR_CMD bash
```

Dentro del contenedor se deben ejecutar los siguientes comandos para setear las variables de entorno y finalmente importar las cuentas a Araí-Usuarios

```bash
source /entrypoint.sh --export-secrets && set +e

./idm/bin/toba proyecto importar_usuarios_arai -f files/usuarios_sq_nucleo.json -m 2  -p arai_usuarios
```

Para conocer en detalle el funcionamiento de la importación de cuentas y sus parámetros puede visitar la documentación de [`Araí-Usuarios`](https://documentacion.siu.edu.ar/usuarios/docs/cache/guia-importacion-usuarios-cuentas/)

### Configurar parámetros SAML en SIU SQ-Núcleo

- Editar el archivo `instalador.env` las siguientes líneas:

```dotenv
###### CONFIG SP ONE LOGIN ######
SSO_SP_IDP_METADATA_URL=https://uunn.local/idp/saml2/idp/metadata.php
SSO_SP_IDP_URL_SERVICE=https://uunn.local/idp/saml2/idp/SSOService.php
SSO_SP_IDP_SINGLE_LOGOUT_URL_SERVICE=https://uunn.local/idp/saml2/idp/SingleLogoutService.php
SSO_SP_IDP_PUBLIC_KEY_FILE=/usr/local/siu/sq_nucleo/temp/certificado_idp.crt
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
* **`SSO_SP_IDP_PUBLIC_KEY_FILE:`** Ruta al archivo del certificado público usado para firmar los tokens SAML en el IDP generado [aquí](../arai#generar-certificados) `/usr/local/app/idp.key` 
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
verifyPeer = "0"

[sp]
auth_source = "default-sp"
session.phpsession.cookiename = "TOBA_SESSID"
idp = "https://uunn.local/idp/saml2/idp/metadata.php"
proyecto_login = "sq_nucleo"

[idp:https://uunn.local/idp/saml2/idp/metadata.php]
SingleSignOnService = "https://uunn.local/idp/saml2/idp/SSOService.php"
SingleLogoutService = "https://uunn.local/idp/saml2/idp/SingleLogoutService.php"
certFile = "/usr/local/siu/sq_nucleo/config/idp.crt"
```

>Se debe agregar el parámetro `verifyPeer = "0"` en la sección de `basicos` ya que no lo genera automáticamente.

 
### Forzar uso de HTTPS

Se debe verificar que SQ-Núcleo este configurado para funcionar sobre HTTPS.

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

Se debe agregar un nuevo usuario y contraseña para que SQ-Núcleo se autentifique contra la API de Araí-Usuarios.
Para esto se debe seguir los pasos indicados [aquí](../arai#habilitar-acceso-api-de-usuarios).

Como SQ-Núcleo es un sistema externo, se debe habilitar además el acceso desde afuera del cluster a dicha API de Araí-Usuarios.

### Configurar el cliente de usuarios en SIU SQ-Núcleo

En la instalación de SQ-Núcleo se debe configurar el archivo `config/i__produccion/p__toba_usuarios/rest/rest_arai_usuarios/cliente.ini` para indicar los datos de acceso a la API de Araí-Usuarios creados en el paso anterior.

Puede ser configurado mediante el comando de Toba o editando el archivo manualmente.

```bash
./bin/toba servicios_web cli_configurar -p toba_usuarios -s rest_arai_usuarios -u https://uunn.local/api-usuarios/v1/ --usuario USR_API_USUARIOS --usuario_pwd PASSWORD_API_USUARIOS --tipo_ws rest
```

Luego de ejecutar el comando el archivo `cliente.ini` quedaría configurado de la siguiente forma:

```ini
[conexion]
to = "https://uunn.local/api-usuarios/v1/"
auth_usuario = "USR_API_USUARIOS"
auth_password = "PASSWORD_API_USUARIOS"
auth_tipo = "digest"
```

> Recuerde que es muy importante que las contraseñas utilizadas sean seguras.

> Recuerde que el dominio `uunn.local` debe ser reemplazado por el que definio en [este](https://expedientes.siu.edu.ar/docs/redes/#modificaci%C3%B3n-de-dominio-base) paso

A partir de la versión 2.0.0 de SIU SQ-Núcleo se debe indicar el `appUniqueId` en el archivo `config/instalacion.ini` como se indica a continuación:
```bash
vincula_arai_appID = "APP_UNIQUE_ID_SQ_NÚCLEO"
```

- **`APP_UNIQUE_ID_SQ_NÚCLEO:`** Es el identificador de aplicación de SIU SQ-Núcleo en Araí-Usuarios. Este valor se puede obtener desde el listado de Aplicaciones en Araí-Usuarios en la columna `appUniqueId`. 


### Configurar los parámetros para Araí-Documentos en SIU SQ-Núcleo

Para poder realizar un resguardo de comprobantes en SIU Araí-Documentos, se creó el parámetro de sistema `USARAIDOCU` para habilitar la exportación a SIU-Araí Documentos.

Se debe configurar el archivo `instalador.env` con los siguientes valores:

```dotenv
##### ARAI DOCUMENTOS #####
ARAIDOC_HOST                = "https://uunn.local/docs"
ARAIDOC_USER                = "USUARIO_API_DOCUMENTOS"
ARAIDOC_PASS                = "PASS_API_DOCUMENTOS"
ARAIDOC_LOGS_DIR            = "/usr/local/siu/sq_nucleo/logs"
ARAIDOC_QUEUE_PATH          = "/usr/local/siu/sq_nucleo/toba/temp"
ARAIDOC_SISTEMA_ORIGEN      = "sq_nucleo"
ARAIDOC_QUEUE_TEMP_DIR      = "/usr/local/siu/sq_nucleo/toba/temp"
ARAIDOC_DB_QUEUE            = "DB_SQ_NUCLEO"
ARAIDOC_DB_HOST             = "HOST_POSTGRES"
ARAIDOC_DB_PORT             = "PUERTO_POSTGRES"
ARAIDOC_DB_USER             = "USER_POSTGRES"
ARAIDOC_DB_PASS             = "PASSWORD_POSTGRES"
ARAIDOC_DB_TABLE            = "queue.queue"
ARAIDOC_POLLING_INVERVAL    = "1000"
ARAIDOC_REST_NUCLEO         = "https://universidad.edu.ar/sq_nucleo/rest/notificaciones/documento"
ARAIDOC_TIPO_DOCUMENTO      = "TIPO_DOC_API_DOCUMENTOS"
ARAIDOC_USUARIO_ARAI        = "USUARIO_API_DOCUMENTOS"
ARAIDOC_USUARIO_SSO         = "USUARIO_SSO_API_DOCUMENTOS"
ARAIDOC_USUARIO_CUENTA      = "USUARIO_CUENTA_API_DOCUMENTOS"
```

Esto genera la siguiente configuración luego de instalar o actualizar en el archivo `config/sq.ini` con los siguientes valores:

```ini
[AraiDocumentos]
HOST                = "https://uunn.local/docs"
USER                = "USUARIO_API_DOCUMENTOS"
PASS                = "PASS_API_DOCUMENTOS"
LOGS_DIR            = "/usr/local/siu/sq_nucleo/logs"
QUEUE_PATH          = "/usr/local/siu/sq_nucleo/toba/temp"
SISTEMA_ORIGEN      = "sq_nucleo"
QUEUE_TEMP_DIR      = "/usr/local/siu/sq_nucleo/toba/temp"
DB_QUEUE            = "DB_SQ_NUCLEO"
DB_HOST             = "HOST_POSTGRES"
DB_PORT             = "PUERTO_POSTGRES"
DB_USER             = "USER_POSTGRES"
DB_PASS             = "PASSWORD_POSTGRES"
DB_TABLE            = "queue.queue"
POLLING_INVERVAL    = "1000"
REST_NUCLEO         = "https://universidad.edu.ar/sq_nucleo/rest/notificaciones/documento"
TIPO_DOCUMENTO      = "TIPO_DOC_API_DOCUMENTOS"
USUARIO_ARAI        = "USUARIO_API_DOCUMENTOS"
USUARIO_SSO         = "USUARIO_SSO_API_DOCUMENTOS"
USUARIO_CUENTA      = "USUARIO_CUENTA_API_DOCUMENTOS"
```

A continuación se explica cada parámetro:

* **`HOST:`** Es la ruta a la API de **Araí-Documentos**
* **`USER:`** Usuario de acceso a la API de **Araí-Documentos**  
* **`PASS:`** Contraseña de acceso a la API de **Araí-Documentos**
* **`LOGS_DIR:`** Directorio usado para generar el archivo de logs de **Documentos Cli**
* **`QUEUE_PATH:`** Directorio usado por la librería **queue** para escribir archivos internos
* **`QUEUE_TEMP_DIR:`** Directorio usado por la librería **queue** para escribir archivos temporales
* **`DB_QUEUE:`** Nombre de la base de datos donde se encuentra el schema queue. Corresponde a la base de negocio de SIU SQ Núcleo
* **`DB_HOST:`** Ruta al host donde se encuentra la base `db_queue`
* **`DB_PORT:`** Puerto de PostgreSQL donde se encuentra la base `db_queue`
* **`DB_USER:`** Usuario de PostgreSQL donde se encuentra la base `db_queue`
* **`DB_PASS:`** Contraseña de PostgreSQL donde se encuentra la base `db_queue`
* **`DB_TABLE:`** Tabla usada por la librería queue. Se debe mantener el valor `queue.queue`
* **`REST_NUCLEO:`** URL de acceso al REST de notificaciones de SQ-Núcleo. Se debe reemplazar por la URL de la instalación existente, manteniendo `/rest/notificaciones/documento`
* **`TIPO_DOCUMENTO:`** Tipo de documento válido en **Araí-Documentos**
* **`USUARIO_ARAI:`** Usuario que autoriza el documento en **Araí-Documentos**
* **`USUARIO_SSO:`** Usuario que envía el documento a **Araí-Documentos**
* **`USUARIO_CUENTA:`** Cuenta de usuario que envía el documento a **Araí-Documentos**


### Habilitar API Backend de Araí-Documentos

Se debe agregar un nuevo usuario y contraseña para que SQ-Núcleo se autentifique contra la API de Araí-Documentos.
Para esto se debe seguir los pasos indicados [aquí](../arai#habilitar-acceso-api-de-documentos).

Como SQ-Núcleo es un sistema externo, se debe habilitar además el acceso desde afuera del cluster a dicha API de Araí-Documentos.

### Archivos de logs

#### Log de documentos-cli
Documentos-cli es el cliente que se encarga de la comunicación con Araí-Documentos.

Su archivo de log se configura la ubicación en el archivo `config/sq.ini` en la entrada `LOGS_DIR`, por defecto se encuentra en `/usr/local/siu/nucleo/logs/docs-cli.log`
