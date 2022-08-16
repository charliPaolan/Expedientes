---
id: version-1.4.0-diaguita
title: SIU-Diaguita
sidebar_label: SIU-Diaguita
original_id: diaguita
---

## Configurar SIU-Diaguita 
En este apartado se presenta la documentación para preparar una instalación de SIU-Diaguita existente para que pueda interoperar con Araí y Sudocu.

### Registrar SIU-Diaguita como Service Provider en Araí Usuarios

Para hacerlo debe acceder al manejador de usuarios y seguir estos pasos:

1. Ingrese a Araí-Usuarios (user `admin` y password seteado [anteriormente](../arai#bootstraping-del-proyecto))
1. Dirigirse al item Aplicaciones
1. Presionar el botón `Agregar +`
1. Completar de la siguiente manera el tab `Datos Generales`
   * Url: https://universidad.edu.ar/diaguita
   * Nombre: diaguita
   * Cómo ícono colocar esta imagen: https://hub.siu.edu.ar/siu/expedientes/-/blob/master/var/logos/diaguita.png
1. Completar de la siguiente manera el tab `SAML`
   * Chequear la opción `Activo`
   * Entity Id: https://universidad.edu.ar/diaguita/default-sp
   * Assertion Consumer Serv.: https://universidad.edu.ar/diaguita/?acs
   * Single Logout Serv.: https://universidad.edu.ar/diaguita/?sls
1. Presionar el botón `Guardar`

> *La URL `https://universidad.edu.ar/diaguita` usada como ejemplo es la url de acceso a la instalación existente de SIU-Diaguita*

### Sincronizar cuentas de usuarios

#### Exportar cuentas de usuarios de Diaguita
Para exportar las cuentas de usuario de SIU-Diaguita que luego serán importadas en Araí-Usuarios se debe ejecutar el siguiente comando sobre la instalación de Diaguita:

```bash
toba proyecto exportar_usuarios_arai -p diaguita -f usuarios_diaguita
```

Este comando genera un archivo JSON con las cuentas de usuario de Diaguita. Si se verifica que este archivo contiene los datos del nombre y apelllido de forma incorrecta se puede usar el parámetro `--mascara` para modificar el formato de los datos exportados.
 
Por ejemplo:
```bash
toba proyecto exportar_usuarios_arai --mascara '<apellido> <nombres>' -p diaguita -f usuarios_diaguita
```

> Se debe verificar el JSON generado y tener en cuenta que en la sección `accounts` el valor del atributo `appName` debe coincidir con el nombre de la aplicación de SIU-Diaguita generado en el [paso anterior](diaguita#registrar-siu-diaguita-como-service-provider-en-araí-usuarios).
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

Dentro del contenedor de deben ejecutar los siguientes comandos para setear las variables de entorno y finalmente importar las cuentas a Araí-Usuarios

```bash
source /entrypoint.sh --export-secrets && set +e

./idm/bin/toba proyecto importar_usuarios_arai -f files/usuarios_diaguita.json -m 2  -p arai_usuarios
```

Para conocer en detalle el funcionamiento de la importación de cuentas y sus parámetros puede visitar la documentación de [`Araí-Usuarios`](https://documentacion.siu.edu.ar/usuarios/docs/cache/guia-importacion-usuarios-cuentas/)


### Configurar parámetros SAML en SIU-Diaguita

- Editar en el archivo `instalador.env` las siguientes líneas:

```bash
###### CONFIG SP ONE LOGIN ######
SSO_SP_IDP_METADATA_URL=https://uunn.local/idp/saml2/idp/metadata.php
SSO_SP_IDP_URL_SERVICE=https://uunn.local/idp/saml2/idp/SSOService.php
SSO_SP_IDP_SINGLE_LOGOUT_URL_SERVICE=https://uunn.local/idp/saml2/idp/SingleLogoutService.php
SSO_SP_IDP_PUBLIC_KEY_FILE=/usr/local/siu/diaguita/temp/certificado_idp.crt
SSO_SP_ATRIBUTO_USUARIO=defaultUserAccount
SSO_SP_PERMITE_LOGIN_TOBA=0
SSO_SP_AUTH_SOURCE=default-sp
SSO_SP_COOKIE_NAME=TOBA_SESSID
SSO_SP_IDP_NAME=https://uunn.local
```



A continuación se explica cada parámetro:  
- **`SSO_SP_IDP_METADATA_URL:`** URL del IDP donde estén accesibles los metadatos. Por ej: `https://service.example.com/idp.metadata `  
- **`SSO_SP_IDP_URL_SERVICE:`** URL del IDP donde esté accesible el servicio. Por ej: `http://service.example.com/simplesaml/saml2/idp/SSOService.php`  
- **`SSO_SP_IDP_SINGLE_LOGOUT_URL_SERVICE:`** URL para cerrar sesión en el IDP. Por ej: `http://service.example.com/simplesaml/saml2/idp/SingleLogoutService.php`  
- **`SSO_SP_IDP_PUBLIC_KEY_FILE:`** Ruta al archivo del certificado público usado para firmar los tokens SAML en el IDP generado [aquí](../arai#generar-certificados)  
- **`SSO_SP_ATRIBUTO_USUARIO:`** El atributo del IDP que contiene el identificador de usuario: En este caso se debe usar `defaultUserAccount`  
- **`SSO_SP_PERMITE_LOGIN_TOBA:`** Si se activa el login interno del proyecto vía Toba. Posibles valores `0` y `1 `  
- **`SSO_SP_AUTH_SOURCE:`** El auth source del SP, por defecto es `default-sp `  
- **`SSO_SP_COOKIE_NAME:`** Nombre de la cookie manejada por OneLogin. Por ej: `TOBA_SESSID`  
- **`SSO_SP_IDP_NAME:`** Nombre del IDP. Por ej: `service.example.com` 



Luego de configurar las variables de entorno ejecutar el comando de reconfiguración del instalador:

```bash
./bin/instalador proyecto:reconfigurar sso
```

Al finalizar debemos verificar el archivo `instalacion/instalacion.ini` donde se incorporan las sgtes lineas:

```bash
 autenticacion = "saml_onelogin"
 vincula_arai_usuarios = "1"
```

> *Se debe agregar el parámetro `vincula_arai_usuarios = "1"` ya que este no se genera automáticamente.*

También se genera el archivo `instalacion/saml_onelogin.ini` con la siguiente configuración: 

```bash
[basicos]
permite_login_toba = "0"
atributo_usuario = "defaultUserAccount"


[sp]
auth_source = "default-sp"
session.phpsession.cookiename = "TOBA_SESSID"
idp = "https://uunn.local/idp/saml2/idp/metadata.php"

proyecto_login = "diaguita"

[idp:https://uunn.local/idp/saml2/idp/metadata.php]
name = "SIU-Diaguita"
SingleSignOnService = "https://uunn.local/idp/saml2/idp/SSOService.php"
SingleLogoutService = "https://uunn.local/idp/saml2/idp/SingleLogoutService.php"
certFile = "/usr/local/siu/diaguita/instalacion/idp.crt"
```

> *En versiones de SIU-Diaguita 3.0.1 o anterior no se genera automáticamente el valor del parámetro `proyecto_login` y por lo tanto se debe configurar manualmente. En posteriores versiones se incluirá la automatización del mismo.*


### Forzar uso de HTTPS

Se debe verificar que SIU-Diaguita este configurado para funcionar sobre HTTPS.

Para esto se deber verificar, y modificar de ser necesario, para que el parámetro `TOBA_FORZAR_HTTPS` se encuentre en el archivo `instalador.env` con el valor en `on`.

```bash
TOBA_FORZAR_HTTPS=on
```

Luego regenerar la configuración de TOBA con el comando:

```bash
./bin/instalador proyecto:reconfigurar toba
```

Se puede verificar que se ha configurado correctamente chequeando en el archivo `instalacion/web_server.ini` que el parámetro `https` se encuentre en `on`.

```bash
[server_config]
https = "on"
```

### Habilitar API de Arai-Usuarios

Se debe agregar un nuevo usuario y contraseña para que Diaguita se autentifique contra la API de Araí-Usuarios.
Para esto se debe seguir los pasos indicados [aquí](../arai#habilitar-acceso-api-de-usuarios).

Como Diaguita es un sistema externo, se debe habilitar además el acceso desde afuera del cluster a dicha API de Araí-Usuarios.


### Configurar el cliente de usuarios en SIU-Diaguita

En la instalación de SIU-Diaguita se debe configurar el archivo `instalacion/i__produccion/p__toba_usuarios/rest/rest_arai_usuarios/cliente.ini` para indicar los datos de acceso a la API de Araí-Usuarios creados en el paso anterior.

Puede ser configurado mediante el comando de Toba o editando el archivo manualmente.

```bash
./bin/toba servicios_web cli_configurar -p toba_usuarios -s rest_arai_usuarios -u https://uunn.local/api-usuarios/v1/ --usuario USR_API_USUARIOS --usuario_pwd PASSWORD_API_USUARIOS --tipo_ws rest
```


```bash
[conexion]
to = "https://uunn.local/api-usuarios/v1/"
auth_tipo = "basic"
auth_usuario = "USR_API_USUARIOS"
auth_password = "PASSWORD_API_USUARIOS"
```

> *Recuerde que es muy importante que las contraseñas utilizadas sean seguras.*

> Recuerde que el dominio `uunn.local` debe ser reemplazado por el que definio en [este](https://expedientes.siu.edu.ar/docs/redes/#modificaci%C3%B3n-de-dominio-base) paso

A partir de la versión 3.0.1 de SIU-Diaguita se debe indicar el `appUniqueId` en el archivo `instalacion/instalacion.ini` como se indica a continuación:
```bash
vincula_arai_appID = 'APP_UNIQUE_ID_DIAGUITA'
```

- **`APP_UNIQUE_ID_DIAGUITA:`** Es el identificador de aplicación de SIU-Diaguita en Araí-Usuarios. Este valor se puede obtener desde el listado de Aplicaciones en Araí-Usuarios en la columna `appUniqueId`. 

### Habilitar el REST de notificaciones
SIU-Diaguita dispone de un servicio REST utilizado por Araí-Documentos para informar cuando existen cambios en los estados de los documentos exportados.
Para que este servicio sea accesible se debe modificar el parámetro `url_protegida` en el archivo `instalacion/i__produccion/p__diaguita/rest/servidor.ini` y tener en cuenta que los demás parámetros se encuentre descomentados como se muestra a continuación.

```bash
[settings]
formato_respuesta = "json"
url_protegida = "/(?=^((?!convocatorias-publicas|notificaciones).)+$)/xs"
encoding = "utf-8"
```
> *Si la universidad no utiliza la APP de Licitaciones de SIU-Diaguita puede eliminar `convocatorias-publicas` de la expresión regular del parámetro quedando de la sgte forma:*  
`url_protegida = "/(?=^((?!notificaciones).)+$)/xs"`



### Configurar los parámetros para Araí-Documentos en SIU-Diaguita

Se debe crear el archivo `instalacion/arai_documentos.ini` con los siguientes valores:

```bash
host_arai="https://uunn.local/docs"
usr_arai="USUARIO_API_DOCUMENTOS"
pass_arai="PASS_API_DOCUMENTOS"
queue_path="/usr/local/app/temp"
queue_temp_dir = "/tmp"
db_queue = "DB_DIAGUITA"
dbq_host = "HOST_POSTGRES"
dbq_port = PUERTO_POSTGRES
dbq_user = "USER_POSTGRES"
dbq_password = "PASSWORD_POSTGRES"
dbq_table_name = "queue.queue"
polling_interval = 1000
rest_diaguita = "https://universidad.edu.ar/diaguita/rest/notificaciones/documento"

```

A continuación se explica cada parámetro: 
- **`host_arai:`** Es la ruta a la API de **Araí-Documentos**  
- **`usr_arai:`** Usuario de acceso a la API de **Araí-Documentos**  
- **`pass_arai:`** Contraseña de acceso a la API de **Araí-Documentos**  
- **`queue_path:`** Directorio usado por la librería **queue** para escribir archivos internos  
- **`queue_temp_dir:`** Directorio usado por la librería **queue** para escribir archivos temporales  
- **`db_queue:`** Nombre de la base de datos donde se encuentra el schema queue. Corresponde a la base de negocio de SIU-Diaguita  
- **`dbq_host:`** Ruta al host donde se encuentra la base `db_queue`  
- **`dbq_port:`** Puerto de PostgreSQL donde se encuentra la base `db_queue`  
- **`dbq_user:`** Usuario de PostgreSQL donde se encuentra la base `db_queue`  
- **`dbq_password:`** Contraseña de PostgreSQL donde se encuentra la base `db_queue`  
- **`dbq_table_name:`** Tabla usada por la librería queue. Se debe mantener el valor `queue.queue`  
- **`polling_interval:`** No se debe modificar  
- **`rest_diaguita:`** URL de acceso al REST de notificaciones de Diaguita. Se debe reemplazar por la URL de la instalación existente, manteniendo `/rest/notificaciones/documento`  

### Habilitar API Backend de Araí-Documentos

Se debe agregar un nuevo usuario y contraseña para que Diaguita se autentifique contra la API de Araí-Documentos.
Para esto se debe seguir los pasos indicados [aquí](../arai#habilitar-acceso-externo-de-api-backend-de-documentos).

Como Diaguita es un sistema externo, se debe habilitar además el acceso desde afuera del cluster a dicha API de Araí-Documentos.

### Worker de Documentos

SIU-Diaguita dispone de un proceso que se encarga de enviar de forma asíncrona los documentos exportados, así como de actualizar el estado de los mismos.

Este proceso denominado "worker" se debe mantener corriendo continuamente. 
Para esto se puede utilizar un sistema de control de procesos como Supervisor (http://supervisord.org/).

El comando de Diaguita que inicia el worker de documentos es:
```bash
bin/toba proyecto iniciar_workers_arai_documentos -p diaguita
```

A continuación se presenta un ejemplo de un archivo de configuración de Supervisor para correr el worker de documentos. Pero si se utilizará esta herramienta se recomienda leer su [`documentación`](http://supervisord.org/) para configurarlo.


```bash
[program:diaguita-worker-documentos]
command=<path_instalacion_diaguita>/bin/toba proyecto iniciar_workers_arai_documentos -p diaguita
autostart=true
autorestart=true
stderr_logfile=/var/log/diaguita-worker-documentos-err.log
stderr_logfile_maxbytes=2MB
stderr_logfile_backups=10
stderr_capture_maxbytes=1MB
stdout_logfile=/var/log/diaguita-worker-documentos-stdout.log
stdout_logfile_maxbytes=10MB
stdout_logfile_backups=10
stdout_capture_maxbytes=1MB
```

### Habilitar Bundle de Solicitudes de bienes y servicios

Para habilitar el bundle de Solicitudes de bienes y servicios se debe seguir los siguientes pasos:

En primer lugar se recomienda generar un secret (seguro) para almacenar la contraseña de la API de SIU-Diaguita.

```bash
printf "diaguita123" | docker secret create diaguita_api_client_pass -
```

En el archivo `prod/arai/huarpe.yml` se deben descomentar (o agregar) los items en las secciones que se detallan a continuación.
```bash
webapp
  secrets:
    diaguita_api_client_pass

secrets:
  diaguita_api_client_pass:
    external: true    
```

Finalmente se deben definir valores para las restantes variables de entorno necesarias en el archivo `huarpe.env`:

```ini
API_DIAGUITA_USR=huarpe
API_DIAGUITA_URL=http://localhost:9191/siu/diaguita/rest/v1/
BUNDLE_COMPRAS_ACTIVO=1
BUNDLE_PATRIMONIO_ACTIVO=1
```

- **`BUNDLE_COMPRAS_ACTIVO:`** Indica que se deben activar los bundles de Compras de SIU-Diaguita
- **`BUNDLE_PATRIMONIO_ACTIVO:`** Indica que se deben activar el bundle de Patrimonio de SIU-Diaguita
- **`API_DIAGUITA_USR:`** Usuario para acceder a la API de SIU-Diaguita.
- **`API_DIAGUITA_URL:`** URL de la API de SIU-Diaguita. Ej: `https://universidad.edu.ar/diaguita/rest/vX/` 
- **`DIAGUITA_URL_COMPRAS:`** URL de la operación en SIU-Diaguita. Ej: `https://universidad.edu.ar/diaguita/aplicacion.php?ai=diaguita||nro` 
- **`DIAGUITA_APP_UNIQUE_ID:`** Es el identificador de aplicación de SIU-Diaguita en Araí-Usuarios. Este valor se puede obtener desde el listado de Aplicaciones en Araí-Usuarios en la columna `appUniqueId`. 

Luego de realizar los cambios en el archivo de configuración se debe actualizar el servicio de **Huarpe**, eliminando en primer lugar el stack y luego realizando nuevamente el deploy de la siguiente manera:

```bash
docker stack rm huarpe
docker stack deploy --with-registry-auth -c huarpe.yml huarpe
```

### Archivos de logs

#### Log de documentos-cli
Documentos-cli es el cliente que se encarga de la comunicación con Araí-Documentos.

Su archivo de log se encuentra en `instalacion/i__produccion/p__diaguita/logs/docs-cli.log`

#### Log de libreria queue

La librería `queue` es la que se encarga de procesar las transacciones que ocurren entre SIU-Diaguita y Araí-Documentos.
Es el archivo de log mas importante a analizar para detectar el origen de algún error.

Su archivo de log se encuentra en `instalacion/i__produccion/p__diaguita/logs/queue.log`
