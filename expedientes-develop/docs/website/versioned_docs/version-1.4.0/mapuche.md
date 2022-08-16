---
id: version-1.4.0-mapuche
title: SIU-Mapuche
sidebar_label: SIU-Mapuche
original_id: mapuche
---

## Configurar SIU-Mapuche
En este apartado se presenta la documentación para preparar una instalación de SIU-Mapuche existente para que pueda interoperar con los demas módulos del ecosistema.

### Registrar SIU-Mapuche como Service Provider en Araí Usuarios

Para hacerlo debe acceder a manejador de usuarios y seguir estos pasos:

1. Ingrese a Araí-Usuarios (user `admin` y password seteado [anteriormente](../arai#bootstraping-del-proyecto))
1. Dirigirse al item Aplicaciones
1. Presionar el botón `Agregar +`
1. Completar de la siguiente manera el tab `Datos Generales`
   * Url: https://universidad.edu.ar/mapuche
   * Nombre: mapuche
   * Cómo ícono colocar esta imagen: https://hub.siu.edu.ar/siu/expedientes/-/blob/master/var/logos/mapuche.png
1. Completar de la siguiente manera el tab `SAML`
   * Chequear la opción `Activo`
   * Entity Id: https://universidad.edu.ar/mapuche/default-sp
   * Assertion Consumer Serv.: https://universidad.edu.ar/mapuche/?acs
   * Single Logout Serv.: https://universidad.edu.ar/mapuche/?sls
1. Presionar el botón `Guardar`

>La URL `https://universidad.edu.ar/mapuche` usada como ejemplo es la url de acceso a la instalación existente de SIU-Mapuche

### Sincronizar cuentas de usuarios

#### Exportar cuentas de usuarios de Mapuche
Para exportar las cuentas de usuario de SIU-Mapuche que luego serán importadas en Araí-Usuarios se debe ejecutar el siguiente comando sobre la instalación de Mapuche:

```bash
toba proyecto exportar_usuarios_arai -p mapuche -f usuarios_mapuche
```

Este comando genera un archivo JSON con las cuentas de usuario de Mapuche. Si se verifica que este archivo contiene los datos del nombre y apellido de forma incorrecta se puede usar el parámetro `--mascara` para modificar el formato de los datos exportados.
 
Por ejemplo:
```bash
toba proyecto exportar_usuarios_arai --mascara '<apellido> <nombres>' -p mapuche -f usuarios_mapuche
```

>Se debe verificar el JSON generado y tener en cuenta que en la sección `accounts` el valor del atributo `appName` debe coincidir con el nombre de la aplicación de SIU-Mapuche generado en el [paso anterior](mapuche#registrar-siu-mapuche-como-service-provider-en-araí-usuarios)
Si el valor no coincide, se recomienda modificar el nombre de la aplicación antes de realizar la importación, de lo contrario no se vincularán las cuentas correctamente.


#### Importar cuentas en Araí-Usuarios

En primer lugar es necesario correr el contenedor que permite realizar tareas administrativas sobre la instalación de Araí-Usuarios.
Para esto se debe realizar el deploy de [`usuarios_cmd.yml`](https://hub.siu.edu.ar/siu/expedientes/-/blob/master/prod/arai/util/usuarios_cmd.yml) de la siguiente forma:

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

./idm/bin/toba proyecto importar_usuarios_arai -f files/usuarios_mapuche.json -m 2  -p arai_usuarios
```

Para conocer en detalle el funcionamiento de la importación de cuentas y sus parámetros puede visitar la documentación de [`Araí-Usuarios`](https://documentacion.siu.edu.ar/usuarios/docs/cache/guia-importacion-usuarios-cuentas/)

### Configurar parámetros SAML en SIU-Mapuche

- Editar el archivo `instalador.env` las siguientes líneas:

```dotenv
###### CONFIG SP ONE LOGIN ######
SSO_SP_IDP_METADATA_URL=https://uunn.local/idp/saml2/idp/metadata.php
SSO_SP_IDP_URL_SERVICE=https://uunn.local/idp/saml2/idp/SSOService.php
SSO_SP_IDP_SINGLE_LOGOUT_URL_SERVICE=https://uunn.local/idp/saml2/idp/SingleLogoutService.php
SSO_SP_IDP_PUBLIC_KEY_FILE=/usr/local/siu/mapuche/temp/certificado_idp.crt
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
proyecto_login = "mapuche"

[idp:https://uunn.local/idp/saml2/idp/metadata.php]
SingleSignOnService = "https://uunn.local/idp/saml2/idp/SSOService.php"
SingleLogoutService = "https://uunn.local/idp/saml2/idp/SingleLogoutService.php"
certFile = "/usr/local/siu/mapuche/instalacion/idp.crt"
```

>En la versión 3.12.2 o anterior no genera automáticamente el valor del `proyecto_login` y se debe configurar manualmente. En posteriores versiones se incluirá la automatización del mismo.

### Forzar uso de HTTPS

Se debe verificar que SIU-Mapuche este configurado para funcionar sobre HTTPS.

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

Se debe agregar un nuevo usuario y contraseña para que Mapuche se autentifique contra la API de Araí-Usuarios.
Para esto se debe seguir los pasos indicados [aquí](../arai#habilitar-acceso-api-de-usuarios).

Como Mapuche es un sistema externo, se debe habilitar además el acceso desde afuera del cluster a dicha API de Araí-Usuarios.


### Configurar el cliente de usuarios en SIU-Mapuche

En la instalación de SIU-Mapuche se debe configurar el archivo `instalacion/i__produccion/p__toba_usuarios/rest/rest_arai_usuarios/cliente.ini` para indicar los datos de acceso a la API de Araí-Usuarios creados en el paso anterior.

Puede ser configurado mediante el comando de Toba o editando el archivo manualmente.

```bash
./bin/toba servicios_web cli_configurar -p toba_usuarios -s rest_arai_usuarios -u https://uunn.local/api-usuarios/v1/ --usuario USR_API_USUARIOS --usuario_pwd PASSWORD_API_USUARIOS --tipo_ws rest
```

Luego de ejecutar el comando el archivo `cliente.ini` quedaría configurado de la siguiente forma:

```ini
[conexion]
to = "https://uunn.local/api-usuarios/v1/usuarios"
auth_tipo = "basic"
auth_usuario = "USR_API_USUARIOS"
auth_password = "PASSWORD_API_USUARIOS"
```

> Recuerde que es muy importante que las contraseñas utilizadas sean seguras.

> Recuerde que el dominio `uunn.local` debe ser reemplazado por el que definio en [este](https://expedientes.siu.edu.ar/docs/redes/#modificaci%C3%B3n-de-dominio-base) paso

### Configurar los parámetros para Araí-Documentos en SIU-Mapuche

Se debe crear el archivo `instalacion/arai_documentos.ini` con los siguientes valores:

```ini
[arai_documentos_config]
host_arai="https://uunn.local/docs"
usr_arai="USUARIO_API_DOCUMENTOS"
pass_arai="PASS_API_DOCUMENTOS"
logs_dir="/usr/local/siu/mapuche/logs"
sistema_origen = "mapuche"
queue_path=""
queue_temp_dir=""
db_queue=""
dbq_host=""
dbq_port=""
dbq_user=""
dbq_password=""
dbq_table_name=""
rest_mapuche=""
id_usuario_sso = "admin"
cuenta_usuario = "admin"
id_instalacion = "mapuche"

```

A continuación se explica cada parámetro:

* **`host_arai:`** Es la ruta a la API de **Araí-Documentos**
* **`usr_arai:`** Usuario de acceso a la API de **Araí-Documentos**  
* **`pass_arai:`** Contraseña de acceso a la API de **Araí-Documentos**
* **`logs_dir:`** Directorio usado para generar el archivo de logs de **Documentos Cli**
* **`queue_path:`** Directorio usado por la librería **queue** para escribir archivos internos  
* **`queue_temp_dir:`** Directorio usado por la librería **queue** para escribir archivos temporales  
* **`db_queue:`** Nombre de la base de datos donde se encuentra el schema queue. Corresponde a la base de negocio de SIU-Mapuche  
* **`dbq_host:`** Ruta al host donde se encuentra la base `db_queue`
* **`dbq_port:`** Puerto de PostgreSQL donde se encuentra la base `db_queue`
* **`dbq_user:`** Usuario de PostgreSQL donde se encuentra la base `db_queue`  
* **`dbq_password:`** Contraseña de PostgreSQL donde se encuentra la base `db_queue`
* **`dbq_table_name:`** Tabla usada por la librería queue. Se debe mantener el valor `queue.queue`
* **`rest_mapuche:`** URL de acceso al REST de notificaciones de Mapuche. Se debe reemplazar por la URL de la instalación existente, manteniendo `/rest/notificaciones/documento`
* **`id_usuario_sso:`**
* **`cuenta_usuario:`**
* **`id_instalacion:`**

### Habilitar API Backend de Araí-Documentos

Se debe agregar un nuevo usuario y contraseña para que Mapuche se autentifique contra la API de Araí-Documentos.
Para esto se debe seguir los pasos indicados [aquí](../arai#habilitar-acceso-externo-de-api-backend-de-documentos).

Como Mapuche es un sistema externo, se debe habilitar además el acceso desde afuera del cluster a dicha API de Araí-Documentos.


### Habilitar Bundle de Recursos Humanos

> Recuerde: deberá tener configurado el acceso a la API de SIU-Mapuche, mediante un usuario y clave respectivo.
 
Para habilitar el bundle de *Recursos Humanos* se debe seguir los siguientes pasos:

En primer lugar se recomienda generar un secret (seguro) para almacenar la contraseña de acceso a la API de SIU-Mapuche.

```bash
printf "mapuche123" | docker secret create mapuche_api_client_pass -
```

En el archivo `prod/arai/huarpe.yml` se deben descomentar (o agregar) los items en las secciones que se detallan a continuación.
```bash
webapp
  secrets:
    mapuche_api_client_pass

secrets:
  mapuche_api_client_pass:
    external: true
```

Finalmente se deben definir valores para las restantes variables de entorno necesarias en el archivo `huarpe.env`:

```ini
API_MAPUCHE_USR=huarpe
API_MAPUCHE_URL=http://localhost:9191/siu/mapuche/rest/
BUNDLE_MAPUCHE_ACTIVO=1
```

- **`BUNDLE_MAPUCHE_ACTIVO:`** Indica que se deben activar el bundle de Recursos Humanos de SIU-Mapuche
- **`API_MAPUCHE_USR:`** Usuario para acceder a la API de SIU-Mapuche.
- **`API_MAPUCHE_URL:`** URL de la API de SIU-Mapuche. Ej: `https://universidad.edu.ar/mapuche/rest/`


Luego de realizar los cambios en el archivo de configuración se debe actualizar el servicio de **Huarpe**, eliminando en primer lugar el stack y luego realizando nuevamente el deploy de la siguiente manera:

```bash
docker stack rm huarpe
docker stack deploy --with-registry-auth -c huarpe.yml huarpe
```


### Archivos de logs

#### Log de documentos-cli
Documentos-cli es el cliente que se encarga de la comunicación con Araí-Documentos.

Su archivo de log se configura la ubicación en el archivo `instalacion/arai_documentos.ini` en la entrada `logs_dir`, por defecto se encuentra en `/usr/local/siu/mapuche/logs/docs-cli.log`

### Configurar conexión entre SIU-Mapuche y SIU-Pilagá

Cuando se configure la opción para utilizar el servicio REST puede que al momento de guardar les de un error advirtiendo que falta un archivo llamado cliente.ini, el mismo hay que crearlo dentro de la instalación de mapuche en la carpeta /instalacion/i__produccion/p__mapuche/rest/, aquí se debe crear una carpeta con el nombre pilaga y dentro un archivo de texto plano con le nombre y extensión cliente.ini. Dentro del archivo cliente.ini deben agregar las siguientes lineas:

```
[conexion]
to = "{URL_REST_PILAGA}/" ;; ejemplo https://uunn.local/pilaga/rest/ Recuerde dejar una barra (/) al finalizar la URL
auth_tipo = digest  ;; tipo de autentificacion configurada en pilaga
auth_usuario = USUARIO  ;; Usuario configurado en pilaga
auth_password = CLAVE  ;; clave configurada en pilaga para el usuario

```

También se debe verificar los permisos de la carpeta {PATH_MAPUCHE}/instalacion/logs_procesos, la carpeta deberá tener permisos de escritura y lectura.
