---
id: version-1.0.9-tehuelche
title: SIU-Tehuelche
sidebar_label: SIU-Tehuelche
original_id: tehuelche
---

## Configurar SIU-Tehuelche
En este apartado se presenta la documentación para preparar una instalación de SIU-Tehuelche existente para que pueda interoperar con Araí.

### Forzar uso de HTTPS

Se debe verificar que SIU-Tehuelche este configurado para funcionar sobre HTTPS.

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

### Registrar SIU-Tehuelche como Service Provider en Araí Usuarios

Para hacerlo debe acceder a manejador de usuarios y seguir estos pasos:

1. Ingrese a Araí-Usuarios (user `admin` y password seteado [anteriormente](../arai#bootstraping-del-proyecto))
1. Dirigirse al item Aplicaciones
1. Presionar el botón `Agregar +`
1. Completar de la siguiente manera el tab `Datos Generales`
   * Url: https://universidad.edu.ar/tehuelche
   * Nombre: tehuelche
   * Cómo ícono colocar esta imagen: https://hub.siu.edu.ar/siu/expedientes/-/blob/master/var/logos/tehuelche.png
1. Completar de la siguiente manera el tab `SAML`
   * Chequear la opción `Activo`
   * Entity Id: https://universidad.edu.ar/tehuelche/default-sp
   * Assertion Consumer Serv.: https://universidad.edu.ar/tehuelche/?acs
   * Single Logout Serv.: https://universidad.edu.ar/tehuelche/?sls
1. Presionar el botón `Guardar`

>La URL `https://universidad.edu.ar/tehuelche` usada como ejemplo es la url de acceso a la instalación existente de SIU-Tehuelche

### Sincronizar cuentas de usuarios

#### Exportar cuentas de usuarios de Tehuelche
Para exportar las cuentas de usuario de SIU-Tehuelche que luego serán importadas en Araí-Usuarios se debe ejecutar el siguiente comando sobre la instalación de Tehuelche:

```bash
toba proyecto exportar_usuarios_arai -p tehuelche -f usuarios_tehuelche
```



>Se debe verificar el JSON generado y tener en cuenta que en la sección `accounts` el valor del atributo `appName` debe coincidir con el nombre de la aplicación de SIU-Tehuelche generado en el [paso anterior](tehuelche#registrar-siu-tehuelche-como-service-provider-en-araí-usuarios)
Si el valor no coincide, se recomienda modificar el nombre de la aplicación antes de realizar la importación, de lo contrario no se vincularán las cuentas correctamente.

>Se debe verificar que las cuentas exportadas cuenten con un valor válido en el atributo `mail` ya que las cuentas que no cuenten con ese valor no se importarán.


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

./idm/bin/toba proyecto importar_usuarios_arai -f files/usuarios_tehuelche.json -m 2 -p arai_usuarios
```

Para conocer en detalle el funcionamiento de la importación de cuentas y sus parámetros puede visitar la documentación de [`Araí-Usuarios`](https://documentacion.siu.edu.ar/usuarios/docs/cache/guia-importacion-usuarios-cuentas/)

### Configurar parámetros SAML en SIU-Tehuelche

- Editar el archivo `instalador.env` las siguientes líneas:

```dotenv
###### CONFIG SP ONE LOGIN ######
SSO_SP_IDP_METADATA_URL=https://uunn.local/idp/saml2/idp/metadata.php
SSO_SP_IDP_URL_SERVICE=https://uunn.local/idp/saml2/idp/SSOService.php
SSO_SP_IDP_SINGLE_LOGOUT_URL_SERVICE=https://uunn.local/idp/saml2/idp/SingleLogoutService.php
SSO_SP_IDP_PUBLIC_KEY_FILE=/usr/local/siu/tehuelche/temp/certificado_idp.crt
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
* **`SSO_SP_IDP_PUBLIC_KEY_FILE:`** Ruta al archivo donde está el certificado público usado para firmar los tokens SAML en el IDP generado [aquí](../arai#generar-certificados)
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
proyecto_login = "tehuelche"

[idp:https://uunn.local/idp/saml2/idp/metadata.php]
SingleSignOnService = "https://uunn.local/idp/saml2/idp/SSOService.php"
SingleLogoutService = "https://uunn.local/idp/saml2/idp/SingleLogoutService.php"
certFile = "/usr/local/siu/tehuelche/instalacion/idp.crt"
```

### Habilitar API de usuarios

Se debe agregar un nuevo usuario y contraseña para que Tehuelche se autentifique contra la API de Araí-Usuarios.
Para esto se debe seguir los pasos indicados [aquí](../arai#habilitar-acceso-api-de-usuarios).

Como Tehuelche es un sistema externo, se debe habilitar además el acceso desde afuera del cluster a dicha API de Araí-Usuarios.

### Configurar el cliente de usuarios en SIU-Tehuelche

En la instalación de SIU-Tehuelche se debe configurar el archivo `instalacion/i__produccion/p__tehuelche/rest/rest_arai_usuarios/cliente.ini` para indicar los datos de acceso a la API de Araí-Usuarios creados en el paso anterior.

Puede ser configurado mediante el comando de Toba o editando el archivo manualmente.

```bash
./bin/toba servicios_web cli_configurar -p tehuelche -s rest_arai_usuarios -u https://uunn.local/api-usuarios/v1/usuarios --usuario USR_API_USUARIOS --usuario_pwd PASSWORD_API_USUARIOS --tipo_ws rest
```

Luego de ejecutar el comando el archivo `cliente.ini` quedaría configurado de la siguiente forma:

```ini
[conexion]
to = "https://uunn.local/api-usuarios/v1/usuarios"
auth_tipo = "digest"
auth_usuario = "USR_API_USUARIOS"
auth_password = "PASSWORD_API_USUARIOS"
```

>Recuerde que es muy importante que las contraseñas utilizadas sean seguras.

Se debe indicar el `appUniqueId` en el archivo `instalacion/instalacion.ini` como se indica a continuación:
```bash
vincula_arai_appID = 'APP_UNIQUE_ID_TEHUELCHE'
```

- **`APP_UNIQUE_ID_TEHUELCHE:`** Es el identificador de aplicación de SIU-Tehuelche en Araí-Usuarios. Este valor se puede obtener desde el listado de Aplicaciones en Araí-Usuarios en la columna `appUniqueId`. 

