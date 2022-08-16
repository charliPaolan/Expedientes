---
id: version-1.2.0-guarani
title: SIU-Guaraní
sidebar_label: SIU-Guaraní
original_id: guarani
---

## Configurar SIU-Guaraní
En este apartado se presenta la documentación para preparar una instalación de SIU-Guaraní existente para que pueda interoperar con SIU-Araí.

### Registrar SIU-Guaraní como Service Provider en Araí Usuarios

#### Registrar SIU-Guaraní Gestión

Para hacerlo debe acceder al manejador de usuarios y seguir estos pasos:

1. Ingrese a Araí-Usuarios (user `admin` y password seteado [anteriormente](../arai#bootstraping-del-proyecto))
1. Dirigirse al item Aplicaciones
1. Presionar el botón `Agregar +`
1. Completar de la siguiente manera el tab `Datos Generales`
   * Url: https://universidad.edu.ar/guarani-gestion
   * Nombre: SIU-Guaraní Gestión
   * Descripción: Módulo de Gestión de SIU-Guaraní
   * Cómo ícono colocar esta imagen: https://hub.siu.edu.ar/siu/expedientes/-/blob/master/var/logos/guarani.png
1. Completar de la siguiente manera el tab `SAML`
   * Chequear la opción `Activo`
   * Entity Id: https://universidad.edu.ar/guarani-gestion/default-sp
   * Assertion Consumer Serv.: https://universidad.edu.ar/guarani-gestion/?acs
   * Single Logout Serv.: https://universidad.edu.ar/guarani-gestion/?sls
1. Presionar el botón `Guardar`

> *La URL `https://universidad.edu.ar/guarani-gestion` usada como ejemplo es la url de acceso a la instalación existente de SIU-Guaraní Gestión*

#### Registrar SIU-Guaraní Autogestión

Para hacerlo debe acceder al manejador de usuarios y seguir estos pasos:

1. Ingrese a Araí-Usuarios (user `admin` y password seteado [anteriormente](../arai#bootstraping-del-proyecto))
1. Dirigirse al item Aplicaciones
1. Presionar el botón `Agregar +`
1. Completar de la siguiente manera el tab `Datos Generales`
   * Url: https://universidad.edu.ar/guarani-autogestion
   * Nombre: SIU-Guaraní Autogestión
   * Descripción: Módulo de Autogestión de SIU-Guaraní
   * Cómo ícono colocar esta imagen: https://hub.siu.edu.ar/siu/expedientes/-/blob/master/var/logos/guarani.png
1. Completar de la siguiente manera el tab `SAML`
   * Chequear la opción `Activo`
   * Entity Id: https://universidad.edu.ar/guarani-autogestion/acceso
   * Assertion Consumer Serv.: https://universidad.edu.ar/guarani-autogestion/acceso?auth=saml
   * Single Logout Serv.: https://universidad.edu.ar/guarani-autogestion/acceso/logout
1. Presionar el botón `Guardar`

> *La URL `https://universidad.edu.ar/guarani-autogestion` usada como ejemplo es la url de acceso a la instalación existente de SIU-Guaraní Autogestión*

> ***Versiones previas a la 3.19.0:** La aplicación `SIU-Huarpe` debe tener como etiqueta el valor `SIU-Huarpe` en `Arai-Usuarios` para que el docente desde SIU-Guaraní Autogestión pueda acceder a sus documentos pendientes de firma.*

> ***A partir de la versión 3.19.0:** En SIU-Guaraní Autogestión se debe configurar la directiva `huarpe_url` en el archivo `instalacion/config.php` con la URL de la aplicación `SIU-Huarpe` para que los docentes puedan acceder a sus documentos pendientes de firma.*

### Sincronizar cuentas de usuarios

#### Exportar cuentas de usuarios de Guaraní

Primero se debe configurar el archivo `instalacion/instalacion.ini` donde se incorporan las siguientes líneas, asegurarse que dichas líneas queden definidas a nivel global y no dentro de una [sección](https://en.wikipedia.org/wiki/INI_file#Sections):

```bash
autenticacion = "saml_onelogin"
vincula_arai_usuarios = "1"
appUniqueIdGestion = "APP_UNIQUE_ID_GESTION"
appUniqueId3w = "APP_UNIQUE_ID_3W"
```

A continuación se explica cada parámetro:  
- **`autenticacion:`** Tipo de autenticación, debe tener el valor `saml_onelogin` para poder autenticar con el SAML de SIU-Araí.
- **`vincula_arai_usuarios:`** Si vincula los usuarios de SIU-Guaraní con los de SIU-Araí. Poner en `1`.
- **`appUniqueIdGestion:`** El valor del atributo `appUniqueId` de la aplicación de SIU-Guaraní Gestión generado en el [primer paso](guarani#registrar-siu-guaraní-como-service-provider-en-araí-usuarios).
- **`appUniqueId3w:`** El valor del atributo `appUniqueId` de la aplicación de SIU-Guaraní Autogestión generado en el [primer paso](guarani#registrar-siu-guaraní-como-service-provider-en-araí-usuarios).

Para exportar las cuentas de usuario de SIU-Guaraní que luego serán importadas en Araí-Usuarios se debe ejecutar el siguiente comando sobre la instalación de Guaraní Gestión:

```bash
bin/guarani exportar_usuarios_arai
```

Este comando posee las siguiente opciones: 

```
-d => Path donde se guarda el archivo, por defecto -> instalacion/usersExportFiles/,
-f => Nombre del archivo donde se exportaran los usuarios, por defecto -> usuarios_yyyymmddhhmmss.json,
-m => Nombre del responsable, por defecto -> toba,
-e => Mails del responsable,  por defecto -> toba@siu.edu.ar
```

Este comando genera un archivo JSON con las cuentas de usuario de Guaraní, solo exporta usuarios docentes y administrativos.
 
Por ejemplo:
```bash
bin/guarani exportar_usuarios_arai
```

> Se debe verificar el JSON generado y tener en cuenta que en la sección `accounts` el valor del atributo `appUniqueId` debe coincidir con el ID de la aplicación de SIU-Guaraní generado en el [paso anterior](guarani#registrar-siu-guaraní-como-service-provider-en-araí-usuarios).
Si el valor no coincide, se recomienda modificar el nombre de la aplicación antes de realizar la importación, de lo contrario no se vincularán las cuentas correctamente.

> **Versiones previas a la 3.19.1:** Se debe reemplazar el valor de la directiva `passwordAlgorithm` de `bcrypt` a `crypt` en el JSON generado.

#### Importar cuentas en Araí-Usuarios

En primer lugar es necesario correr el contenedor que permite realizar tareas administrativas sobre la instalación de Araí-Usuarios.
Para esto se debe realizar el deploy de [`usuarios_cmd.yml`](https://hub.siu.edu.ar/siu/expedientes/-/blob/master/prod/arai/util/usuarios_cmd.yml) de la sgte forma:

```bash
docker stack deploy  --with-registry-auth  -c prod/arai/util/usuarios_cmd.yml usr-cmd
```

> Se debe tener en cuenta que en clusters con más de un nodo es importante utilizar el constraint `constraints: [ node.hostname == hostname-actual ]` para lograr que el contenedor se ejecute en el mismo nodo que se ejecuta el stack deploy. Sin embargo en clusters con sólo un nodo esto no es necesario y puede ser eliminado del archivo `usuarios_cmd.yml` antes de realizar el deploy.

Luego se debe copiar el JSON con las cuentas exportadas al directorio [`prod/arai/util/files`](https://hub.siu.edu.ar/siu/expedientes/-/blob/master/prod/arai/util/files) ya que este directorio es accesible desde dentro del contenedor.

Una vez copiado el JSON es necesario conectarse al contenedor.

```bash
docker exec -it ID_CONTENEDOR_USR_CMD bash
```

Dentro del contenedor de deben ejecutar los siguientes comandos para setear las variables de entorno y finalmente importar las cuentas a Araí-Usuarios

```bash
source /entrypoint.sh --export-secrets && set +e

./idm/bin/toba proyecto importar_usuarios_arai -f files/usuarios_yyyymmddhhmmss.json -m 2  -p arai_usuarios
```

Para conocer en detalle el funcionamiento de la importación de cuentas y sus parámetros puede visitar la documentación de [`Araí-Usuarios`](https://documentacion.siu.edu.ar/usuarios/docs/cache/guia-importacion-usuarios-cuentas/)

> Se debe cambiar la contraseña de los usuarios importados en SIU-Araí, ya que las contraseñas de SIU-Guaraní no pueden reutilizarse en SIU-Araí debido al algoritmo de encriptación.

### Configurar parámetros SAML en SIU-Guaraní

#### Configurar parámetros SAML en SIU-Guaraní Gestión

Configurar el archivo `instalacion/instalacion.ini` donde se incorporan las siguientes líneas, asegurarse que dichas líneas queden definidas a nivel global y no dentro de una [sección](https://en.wikipedia.org/wiki/INI_file#Sections):

```bash
autenticacion = "saml_onelogin"
vincula_arai_usuarios = "1"
appUniqueIdGestion = "APP_UNIQUE_ID_GESTION"
appUniqueId3w = "APP_UNIQUE_ID_3W"
```

A continuación se explica cada parámetro:  
- **`autenticacion:`** Tipo de autenticación, debe tener el valor `saml_onelogin` para poder autenticar con el SAML de SIU-Araí.
- **`vincula_arai_usuarios:`** Si vincula los usuarios de SIU-Guaraní con los de SIU-Araí. Poner en `1`.
- **`appUniqueIdGestion:`** El valor del atributo `appUniqueId` de la aplicación de SIU-Guaraní Gestión generado en el [primer paso](guarani#registrar-siu-guaraní-como-service-provider-en-araí-usuarios).
- **`appUniqueId3w:`** El valor del atributo `appUniqueId` de la aplicación de SIU-Guaraní Autogestión generado en el [primer paso](guarani#registrar-siu-guaraní-como-service-provider-en-araí-usuarios).

También configurar el archivo `instalacion/saml_onelogin.ini` con lo siguiente: 

```bash
[basicos]
permite_login_toba = "0"
atributo_usuario = "defaultUserAccount"


[sp]
auth_source = "default-sp"
session.phpsession.cookiename = "TOBA_SESSID"
idp = "https://uunn.local/idp/saml2/idp/metadata.php"

proyecto_login = "guarani"

[idp:https://uunn.local/idp/saml2/idp/metadata.php]
name = "SIU-Guaraní"
SingleSignOnService = "https://uunn.local/idp/saml2/idp/SSOService.php"
SingleLogoutService = "https://uunn.local/idp/saml2/idp/SingleLogoutService.php"
certFile = "/usr/local/siu/guarani/instalacion/idp.crt"
```

A continuación se explica cada parámetro:
- **`permite_login_toba:`** Si se activa el login interno del proyecto vía Toba. Posibles valores `0` y `1 `.
- **`atributo_usuario:`** El atributo del IDP que contiene el identificador de usuario: En este caso se debe usar `defaultUserAccount`.
- **`auth_source:`** El auth source del SP, por defecto es `default-sp`.
- **`session.phpsession.cookiename:`** Nombre de la cookie manejada por OneLogin. Por ej: `TOBA_SESSID`.
- **`idp:`** URL del IDP donde estén accesibles los metadatos. Por ej: `https://service.example.com/idp.metadata`.
- **`SingleSignOnService:`** URL del IDP donde esté accesible el servicio. Por ej: `http://service.example.com/simplesaml/saml2/idp/SSOService.php`. 
- **`SingleLogoutService:`** URL para cerrar sesión en el IDP. Por ej: `http://service.example.com/simplesaml/saml2/idp/SingleLogoutService.php`.
- **`certFile:`** Ruta al archivo del certificado público usado para firmar los tokens SAML en el IDP generado [aquí](../arai#generar-certificados).

#### Configurar parámetros SAML en SIU-Guaraní Autogestión

Crear y configurar el archivo `instalacion/saml/settings.php` desde el template `instalacion/saml/settings_example.php` reemplazando las siguientes líneas:

```php
<?php
//settings y advanced_settings de la libreria de saml.
$url_autogestion = 'https://universidad.edu.ar/guarani-autogestion';
$url_idp = 'https://uunn.local/idp';
return $settings = array (
    ..................
    // Identity Provider Data that we want connect with our SP
    'idp' => array (
        ..................
        /*
         *Instead of use the whole x509cert you can use a fingerprint
         *(openssl x509 -noout -fingerprint -in "idp.crt" to generate it)
         */
         'certFingerprint' => '65:C0:CE:76:C5:41:8B:C1:D6:0F:C3:E6:4E:22:E5:58:06:E9:94:F1',
    ),
    ..................
);
```

A continuación se explica cada parámetro:
- **`$url_autogestion:`** URL de SIU-Guaraní Autogestión a la cual queremos darle un acceso por el proveedor de indentidad SIU-Araí.
- **`$url_idp:`** URL del IDP (sin `/saml2/idp` al final).
- **`certFingerprint:`** Se genera ejecutando: `openssl x509 -noout -fingerprint -in "/usr/local/siu/guarani/instalacion/idp.crt"`, donde `/usr/local/siu/guarani/instalacion/idp.crt` es la ruta al archivo donde está el certificado usado para contactar al IDP (dentro de SIU-Guaraní Gestión).

Configurar el archivo `instalacion/login.php` reemplazando las siguientes líneas:

```php
'saml'  => array(
        'activo'     => true,
        'clase'      => 'modelo\\autenticacion\\auth_saml',
        'parametros' => array(
                'settings_file' => \siu\bootstrap::get_dir_instalacion() . '/saml/settings.php',
                'saml_uid' => 'userAccounts',
                'local_uid' => 'usuario',
        ),
),
```

A continuación se explica cada parámetro:
- **`activo:`** Si se activa el login vía SAML. Poner en `true`.
- **`settings_file:`** Ruta al archivo donde está la configuración de SAML.
- **`saml_uid:`** User ID de SAML.
- **`local_uid:`** User ID interno de SIU-Guaraní.

A partir de este momento, al ingresar al proyecto, este debiera de redirigirnos a la página de login centralizado de la plataforma SIU-Araí. Una vez el usuario ha ingresado, nos redirige nuevamente hacia la aplicación. La misma debiera de contar además con el menú de aplicaciones integrado, con las aplicaciones SIU o de terceros que tengamos registrados.

![App Launcher](assets/guarani_app_launcher.png)

### Forzar uso de HTTPS

Se debe verificar que SIU-Guaraní este configurado para funcionar sobre HTTPS.

#### Configurar HTTPS en SIU-Guaraní Gestión

En la instalación de SIU-Guaraní Gestión se debe configurar el archivo `instalacion/web_server.ini` cambiando el parámetro `https` a `on`.

```ini
[server_config]
https = "on"
```

#### Configurar HTTPS en SIU-Guaraní Autogestión

En la instalación de SIU-Guaraní Autogestión se debe configurar el archivo `instalacion/config.php` de la siguiente manera:

```php
'ssl' => [
    'alcance' => 'all',
    'redirigir_ssl' => true
],
```

### Habilitar API de Araí-Usuarios

Se debe agregar un nuevo usuario y contraseña para que SIU-Guaraní se autentifique contra la API de Araí-Usuarios. Para esto se debe seguir los pasos indicados [aquí](../arai#configurar-y-desplegar-araí-usuarios).

Como SIU-Guaraní es un sistema externo, se debe habilitar además el acceso desde afuera del cluster a dicha API de Araí-Usuarios.

### Configurar el cliente de usuarios en SIU-Guaraní

#### Configurar el cliente de usuarios en SIU-Guaraní Gestión

En la instalación de SIU-Guaraní Gestión se debe configurar el archivo `instalacion/i__desarrollo/p__guarani/rest/arai_usuarios/cliente.ini` para indicar los datos de acceso a la API de Araí-Usuarios creados en el paso anterior.

```bash
[conexion]
to = "https://uunn.local/api-usuarios/v1/"
auth_tipo = "basic"
auth_usuario = "USR_API_USUARIOS"
auth_password = "PASSWORD_API_USUARIOS"
```

> *Recuerde que es muy importante que las contraseñas utilizadas sean seguras.*

> Recuerde que el dominio `uunn.local` debe ser reemplazado por el que definio en [este](https://expedientes.siu.edu.ar/docs/redes/#modificaci%C3%B3n-de-dominio-base) paso

#### Configurar el cliente de usuarios en SIU-Guaraní Autogestión

En la instalación de SIU-Guaraní Autogestión se debe configurar el archivo `instalacion/servicios_web_config.php` agregando lo siguiente dentro del array de `consumidos`:

```php
'consumidos' => [

............

    'arai_usuarios' => [
        'tipo' => 'rest',
            'parametros' => [
                'base_uri' => 'https://uunn.local/api-usuarios/v1/',
                'auth' => ['USR_API_USUARIOS', 'PASSWORD_API_USUARIOS', 'basic']
            ]
    ],

............

]
```

> *Recuerde que es muy importante que las contraseñas utilizadas sean seguras.*

A partir de ahora cuando queramos asignar un usuario a una persona, aparecerá un combo editable donde podremos buscar los usuarios existentes en SIU-Araí.

Entonces de está forma necesitamos editar la persona en SIU-Guaraní Gestión (operación `Administrar Personas` solapa `Acceso al sistema`), y vincularla con el usuario de SIU-Araí.

![Operación Administrar Personas solapa Acceso al sistema](assets/guarani_admin_personas.png)

### Configurar los parámetros para Araí-Documentos en SIU-Guaraní

#### Configurar los parámetros para Araí-Documentos en SIU-Guaraní Gestión

Se debe crear el archivo `instalacion/arai_documentos.ini` con los siguientes valores:

```ini
host_arai="https://uunn.local/docs"
usr_arai="USUARIO_API_DOCUMENTOS"
pass_arai="PASS_API_DOCUMENTOS"
```

A continuación se explica cada parámetro:

* **`host_arai:`** Es la ruta a la API de **Araí-Documentos**
* **`usr_arai:`** Usuario de acceso a la API de **Araí-Documentos**  
* **`pass_arai:`** Contraseña de acceso a la API de **Araí-Documentos**

#### Configurar los parámetros para Araí-Documentos en SIU-Guaraní Autogestión

Se debe crear el archivo `instalacion/arai_documentos.ini` con los siguientes valores:

```ini
host_arai="https://uunn.local/docs"
usr_arai="USUARIO_API_DOCUMENTOS"
pass_arai="PASS_API_DOCUMENTOS"
```

A continuación se explica cada parámetro:

* **`host_arai:`** Es la ruta a la API de **Araí-Documentos**
* **`usr_arai:`** Usuario de acceso a la API de **Araí-Documentos**  
* **`pass_arai:`** Contraseña de acceso a la API de **Araí-Documentos**

### Habilitar API Backend de Araí-Documentos

Se debe agregar un nuevo usuario y contraseña para que Guaraní se autentifique contra la API de Araí-Documentos.
Para esto se debe seguir los pasos indicados [aquí](../arai#habilitar-acceso-externo-de-api-backend-de-documentos).

Como Guaraní es un sistema externo, se debe habilitar además el acceso desde afuera del cluster a dicha API de Araí-Documentos.

### Worker de Documentos (a partir de SIU-Guaraní 3.18.1)

SIU-Guaraní dispone de un proceso que se encarga de enviar de forma asíncrona los documentos exportados, así como de actualizar el estado de los mismos.

#### Crear tabla donde se encolarán los documentos a crear en SIU-Araí

Ejecutar el siguiente comando (por única vez) parados en el directorio raíz de SIU-Guaraní Gestión: 

```bash
bin/guarani crear_cola_documentos_arai
```
> Dicho comando creará la tabla `arai_documentos_cola` en la base de datos de SIU-Guaraní, la misma es utilizada para encolar los documentos que luego serán creados en SIU-Araí de forma asincrónica.

> ***Versiones previas a la 3.19.1:** Para que la tabla `arai_documentos_cola` sea creada en el esquema `negocio` en lugar del esquema `public` deberá establecer el parámetro `search_path` en la base de datos con el valor `negocio`.*

#### Ejecutar worker para procesar los documentos encolados

Ejecutar el siguiente comando parados en el directorio raíz de SIU-Guaraní Gestión: 

```bash
bin/guarani sincronizar_documentos_arai
```
> Dicho comando ejecutará un worker (proceso demonio) que desencola documentos de la tabla `arai_documentos_cola` e intentará crearlos en SIU-Araí. Debemos asegurarnos que dicho worker siempre se encuentre ejecutándose.

Este proceso denominado "worker" se debe mantener corriendo continuamente. 
Para esto se puede utilizar un sistema de control de procesos como Supervisor (http://supervisord.org/).

A continuación se presenta un ejemplo de un archivo de configuración de Supervisor para correr el worker de documentos. Pero si se utilizará esta herramienta se recomienda leer su [`documentacion`](http://supervisord.org/) para configurarlo.

```
[program:guarani-worker-documentos]
command=<path_instalacion_guarani>/bin/guarani sincronizar_documentos_arai
autostart=true
autorestart=true
stderr_logfile=/var/log/guarani-worker-documentos-err.log
stderr_logfile_maxbytes=2MB
stderr_logfile_backups=10
stderr_capture_maxbytes=1MB
stdout_logfile=/var/log/guarani-worker-documentos-stdout.log
stdout_logfile_maxbytes=10MB
stdout_logfile_backups=10
stdout_capture_maxbytes=1MB
```

#### Resincronizar documentos fallidos

En SIU-Guaraní Gestión disponemos de la operación `Sincronizar Masivamente Documentos con Araí`. Todos los documentos que fallen al intentar crearse con el worker del punto anterior podrán ser resincronizados en esta operación. También posee información con las causas por las cuales falla la creación del documento en SIU-Araí.

#### Notificar a los administradores

En el caso de que haya fallado la creación de algún documento en SIU-Araí, se puede notificar a los administradores de SIU-Guaraní via email ejecutando el siguiente comando parados en el directorio raíz de SIU-Guaraní Gestión:

```bash
bin/guarani notificar_administradores
```

Dicho comando le envía un email a todos los administradores de SIU-Guaraní, avisándoles que deben ingresar a la operación `Sincronizar Masivamente Documentos con Araí` para resincronizar los documentos fallidos.

> Nota: Los administradores deben tener algún email asociado en la operación `Administrar Personas` para poder recibir dicha notificación.

### Archivos de logs

#### Log de documentos-cli
Documentos-cli es el cliente que se encarga de la comunicación con Araí-Documentos.

Su archivo de log se configura la ubicación en el archivo `instalacion/arai_documentos.ini` en la entrada `logs_dir`, por defecto se encuentra en `/usr/local/siu/guarani/instalacion/i__desarrollo/p__guarani/logs/docs-cli.log` para SIU-Guaraní Gestión y `/usr/local/siu/guarani/instalacion/log/docs-cli.log` para SIU-Guaraní Autogestión.

#### Log de librería queue

La librería `queue` es la que se encarga de procesar las transacciones que ocurren entre SIU-Guaraní y Araí-Documentos.
Es el archivo de log más importante a analizar para detectar el origen de algún error.

Su archivo de log se encuentra en `instalacion/i__desarrollo/p__guarani/logs/queue.log`
