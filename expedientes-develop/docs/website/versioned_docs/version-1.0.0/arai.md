---
id: version-1.0.0-arai
title: Desplegar Araí 3.0
sidebar_label: Desplegar Araí 3.0
original_id: arai
---

Desde la raíz del  [repositorio](repo-config.md) navegue a la carpeta donde se encuentra la configuración de Araí 3.0

```bash
cd prod/arai
```
Sobre esta carpeta se procederá a adaptar los archivos de configuración a las necesidades de su instalación y luego desplegar los distintos stacks.

## Configuración General
### Cambiar dominio

En los archivos de configuración se asume el dominio `uunn.local`, para cambiarlo por el dominio definitivo puede utilizar el siguiente comando (reemplace `universidad.edu.ar` por el dominio real que utilizará durante el despliegue)

```bash
sed -i 's/uunn.local/universidad.edu.ar/g' \
    usuarios.api.env \
    usuarios.idp.env \
    usuarios.env \
    usuarios.yml \
    docs.yml \
    docs.env \
    huarpe_parameters.yml \
    huarpe.yml
```
### Secretos en Docker

Los secretos son blobs de información que deben almacenarse de forma segura y no pueden ser versionados. Ejemplos de esto son: passwords, claves de SSH, certificados SSL, etc. Más información [aquí](https://docs.docker.com/engine/swarm/secrets/). 

Los servicios que conforman esta documentación requieren que ciertos secretos estén definidos **antes** de comenzar el despliegue. 

#### Esta es la lista de secretos requeridos por Araí durante el despliegue:

* `usuarios_db_pass`: Password de la conexión con la base de datos.
* `usuarios_ldap_admin_pass`: Password de bind de admin de ldap
* `usuarios_ldap_config_pass`: Password de bind del config de ldap
* `usuarios_pass_salt`: Salt de los passwords generados por Araí-Usuarios
* `usuarios_api_users`: Json que define pares de usuario/password para la autenticación de la API de usuarios
* `usuarios_idp_simplesaml_admin`: Password del panel de control de Administrador provisto con SimpleSAMLPhp
* `docs_api_pass`: Password de la API de Documentos
* `docs_db_pass`: Password de la conexión con Postgres
* `docs_repo_pass`: Password de la conexión con Nuxeo
* `docs_conexion_usuarios`: Credenciales y endpoint de la conexión con Usuarios
* `docs_conexion_sudocu`: Credenciales y endpoint de la conexión con SUDOCU
* `huarpe_secret`: Token de 31 caracteres
* `huarpe_conexion_usuarios`: Credenciales de la conexión por API con Usuarios
* `huarpe_conexion_docs`: Credenciales de la conexión por API con Documentos

#### Creación de secretos
La distribucion provee el script de bash [`secrets.sh.dist`](https://hub.siu.edu.ar/siu/expedientes/-/blob/master/prod/secrets.sh.dist) para ejemplificar como inicializar todos los valores requeridos. Si desea mantener un archivo propio con las claves de su ambiente ejecute:

```bash
cp secrets.sh.dist secrets.sh
```
y **modifique el script** `secrets.sh` con los datos correspondientes a su entorno. Luego ejecutelo para cargar los secretos dentro de Docker.

```bash
./secrets.sh
```
> En el caso que se mantenga un repositorio de configuraciones propio, se recomienda ignorar este archivo y evitar subirlo. Tambien es posible no escribir las claves en archivos y configurar los secretos a mano tomando el script [`secrets.sh.dist`](https://hub.siu.edu.ar/siu/expedientes/-/blob/master/prod/secrets.sh.dist) como referencia.


## Configurar y desplegar Araí-Usuarios

La especificación del stack de este módulo se encuentra en [`usuarios.yml`](https://hub.siu.edu.ar/siu/expedientes/-/blob/master/prod/arai/usuarios.yml). Existen tambien otros archivos de configuración asociados: [`usuarios.api.env`](https://hub.siu.edu.ar/siu/expedientes/-/blob/master/prod/arai/usuarios.api.env), [`usuarios.env`](https://hub.siu.edu.ar/siu/expedientes/-/blob/master/prod/arai/usuarios.env) y [`usuarios.idp.env`](https://hub.siu.edu.ar/siu/expedientes/-/blob/master/prod/arai/usuarios.idp.env)

### Nota sobre la persistencia de datos

> Este stack utiliza un **volumen** llamado `usuarios_assets` para guardar la imagen de perfil de los usuarios. Es importante que el almacenamiento subyacente sea compartido por todos los nodos del cluster donde este stack se este ejecutando para que mantengan entre ellos un estado consistente de la base de imagenes. Para lograr esto se requiere contar con una tecnología de [almacenamiento distribuido](servicios-base#storage) (NFS, GlusterFS, etc) montada en cada nodo. Como alternativa al almacenamiento distribuido tambien es posible simplificar el despliegue limitando la ejecución de este stack a un único nodo del cluster conectado al almacenamiento centralizado.

### Acceso a Postgres
Los parámetros de conexión los puede encontrar en el archivo `usuarios.env`, son los siguientes:
```
DB_HOST=db-siu
DB_PORT=5432
DB_DBNAME=usuarios
DB_USERNAME=postgres
DB_SCHEMA=usuarios
```

### Acceso a LDAP
Los parámetros de conexión los puede encontrar en el archivo `usuarios.env`, son los siguientes:
```
LDAP_HOST=ldap
LDAP_PORT=389
LDAP_TLS=0
LDAP_METHOD=user
LDAP_BINDUSER=cn=admin,dc=siu,dc=cin,dc=edu
LDAP_BINDPASS_FILE=/run/secrets/usuarios_ldap_admin_pass
LDAP_SEARCHBASE=dc=siu,dc=cin,dc=edu
LDAP_USERS_OU=usuarios
LDAP_USERS_ATTR=ou
LDAP_ACCOUNTS_OU=usuariosCuentas
LDAP_ACCOUNTS_ATTR=ou
LDAP_GROUPS_OU=groups
LDAP_GROUPS_ATTR=ou
LDAP_NODES=
```

### Creación de Base de Datos
En el sitio de documentación de Araí-Usuarios hay documentación extensa de cómo crear la base de LDAP y Postgres.

> https://documentacion.siu.edu.ar/usuarios/docs/cache/instalacion-bases-ldap/
> https://documentacion.siu.edu.ar/usuarios/docs/cache/instalacion-bases-postgres/

### Generar certificados

Araí-Usuario requiere dos pares de claves para funcionar, una para firmar los tokens SAML y otra para firmar los tokens JWT de OIDC.

Para generar los certificados utilizados para firmar los tokens SAML ejecutar:
```bash
mkdir certs
openssl req -newkey rsa:2048 -new -x509 -days 3652 -nodes -out certs/certificado_idp.crt -keyout certs/certificado_idp.key
```

Para generar los certificados utilizados en OIDC para firmar tokens JWT ejecutar:
```bash
openssl genrsa -out certs/oidc_module.pem 2048
openssl rsa -in certs/oidc_module.pem -pubout -out certs/oidc_module.crt
```
Para finalizar, registre los certificados y claves generadas en Docker.
```bash
docker config create usuarios_idp_saml_cert ./certs/certificado_idp.crt
docker secret create usuarios_idp_saml_key ./certs/certificado_idp.key
docker secret create usuarios_idp_oidc_key ./certs/oidc_module.pem
docker config create usuarios_idp_oidc_cert ./certs/oidc_module.crt
```

### Bootstraping del proyecto

La primera vez que se instala este proyecto es necesario realizar dos tareas administrativas
para que todo funcione correctamente. Las tareas a realizar son:
 * Registrar la UI de Araí-Usuarios como SP 
 * Crear y setear un password para el usuario `admin`

> Para realizar este paso, es necesario que las bases de datos estén [inicializadas](arai#creación-de-base-de-datos)

Estas dos tareas se realizan ejecutando el siguiente comando:
```bash
ADMIN_PASS=toba1234 docker stack deploy \
    --with-registry-auth \
    -c util/usuarios_crear_admin.yml \
    boot
```
Setee la variable `ADMIN_PASS` al password que desee.


Puede verificar el estado de ejecución del mismo de la siguiente manera:
```bash
docker service logs boot_idm -f
```

Una vez finalizado, puede borrar el stack:
```bash
docker stack rm boot
```

### Desplegar el stack

```bash
docker stack deploy --with-registry-auth -c usuarios.yml usuarios
```

> Una vez realizados estos pasos, debería poder acceder en https://uunn.local/usuarios (o el dominio que haya definido)

### Configurar logo
Este paso es opcional, pero deseable. 

Para configurar el logo debe seguir los siguientes pasos: 

1. Ingrese a Araí-Usuarios (user `admin` y password seteado [anteriormente](arai#bootstraping-del-proyecto))
1. Dirigirse al item Aplicaciones
1. Ir a la lupa a la derecha de la fila de la aplicación Araí-Usuarios
1. Cargar el ícono. https://hub.siu.edu.ar/siu/expedientes/-/blob/master/var/logos/usuarios.png

## Configurar y desplegar Araí-Documentos

La especificación del stack de este módulo se encuentra en [`docs.yml`](https://hub.siu.edu.ar/siu/expedientes/-/blob/master/prod/arai/usuarios.yml). Existen tambien otros archivo de configuración asociado: [`docs.env`](https://hub.siu.edu.ar/siu/expedientes/-/blob/master/prod/arai/usuarios.api.env)

### Conexión con Postgres
* `ARAI_DOCS_URL`: Es la URL base de la API accesible desde fuera
* `ARAI_DOCS_DB_HOST`: Host de la base de datos
* `ARAI_DOCS_DB_PORT`: Puerto de la base de datos
* `ARAI_DOCS_DB_DBNAME`: Nombre de la base de datos
* `ARAI_DOCS_DB_USERNAME`: Usuario de la base de datos 

### Conexión con Nuxeo

* `ARAI_DOCS_REPO_HOST`: Es la url de nuxeo, debe apuntar a la API CMIS <url-host-nuxeo>/nuxeo/atom/cmis/
* `ARAI_DOCS_REPO_USUARIO`: API User de Nuxeo
* `ARAI_DOCS_REPO_CLAVE`: Password asociada al User anterior
* `ARAI_DOCS_REPO_SISTEMA`: Identificador del sistema Ej: uunn
* `ARAI_DOCS_REPO_INSTALACION`: Identificador de la instalación Ej: arai_docs_uun

### Creación de Base de Datos
Se incluye un comando que crea la estructura de la base de datos de Araí-Documentos. Para utilizarlo
ejecutar el siguiente comando:
```bash
docker stack deploy \
    --with-registry-auth \
    -c util/docs_crear_base.yml \
    crear_db_docs
```

Asume que la base de datos especificada en la [sección de la conexión con Postgres](arai#conexión-con-postgres) ya está creada.
### Desplegar el stack
```bash
docker stack deploy --with-registry-auth -c docs.yml docs
```
## Configurar y desplegar SIU-Huarpe

La especificación del stack de este módulo se encuentra en [`huarpe.yml`](https://hub.siu.edu.ar/siu/expedientes/-/blob/master/prod/arai/huarpe.yml). Existen tambien otros archivos de configuración asociados: [`huarpe_alias.conf`](https://hub.siu.edu.ar/siu/expedientes/-/blob/master/prod/arai/huarpe_alias.conf), [`huarpe_parameters.yml`](https://hub.siu.edu.ar/siu/expedientes/-/blob/master/prod/arai/parameters.yml) y [`huarpe_bundles.yml`](https://hub.siu.edu.ar/siu/expedientes/-/blob/master/prod/arai/bundles.yml)

### Conexiones con APIs Rest
Como se dijo antes, este sistema sólo consume información a través de endpoints Rest. 
Estas conexiones están explicitadas en el archivo `huarpe_parameters.yml` y no deberían cambiar, salvo que se cambie 
la ruta interna en el clúster de Sudocu, Usuarios o Documentos.

### Registrar Huarpe como Service Provider

Dentro de la solución, Araí-Usuarios es el proveedor de identidad de SIU-Huarpe. Por este motivo es necesario registrar a este último como Service Provider (SP) de SAML. 

Para hacerlo debe acceder a manejador de usuarios y seguir estos pasos:

1. Ingrese a Araí-Usuarios (user `admin` y password seteado [anteriormente](arai#bootstraping-del-proyecto))
1. Dirigirse al item Aplicaciones
1. Presionar el botón `Agregar +`
1. Completar de la siguiente manera el tab `Datos Generales`
![Datos Generales](assets/huarpe_gui1.png)
   * Url: https://uunn.local
   * Nombre: Huarpe
   * Chequear la opción `Acceso Irrestricto`
   * Cómo ícono colocar esta imagen: https://hub.siu.edu.ar/siu/expedientes/-/blob/master/var/logos/huarpe.png
1. Completar de la siguiente manera el tab `SAML`
![Datos Generales](assets/huarpe_gui2.jpeg)
   * Chequear la opción `Activo`
   * Entity Id: https://uunn.local/saml/metadata
   * Assertion Consumer Serv.: https://uunn.local/saml/acs
   * Single Logout Serv.: https://uunn.local/saml/logout
1. Presionar el botón `Guardar`

### Desplegar el stack
```bash
docker stack deploy --with-registry-auth -c huarpe.yml huarpe
```

> Una vez realizados estos pasos, debería poder acceder a Huarpe en https://uunn.local/ (o el dominio que haya definido)