---
id: version-1.5.0-sudocu
title: Desplegar Sudocu
sidebar_label: Desplegar Sudocu
original_id: sudocu
---

> Los siguientes pasos son para realizar una nueva instalación de Sudocu. En el caso de una actualización vaya al correspondiente [apartado](#actualización-de-versión).

Desde la raíz del  [repositorio](repo-config.md) navegue a la carpeta donde se encuentra la configuración de Sudocu:

```bash
cd prod/sudocu
```
Sobre esta carpeta se procederá a adaptar los archivos de configuración a las necesidades de su instalación y luego a desplegar el stack .

## Configuración

La especificación del stack de este módulo se encuentra en [`sudocu.yml`](https://hub.siu.edu.ar/siu/expedientes/-/blob/master/prod/sudocu/sudocu.yml). 

### Modificar dominio
En los archivos de configuración se asume el dominio `uunn.local`, para reemplazarlo por el dominio definitivo puede utilizar 
el siguiente comando:

```bash
sed -i 's/uunn.local/universidad.edu.ar/g' \
    config/config-api-server.json \
    config/config-sudocu-login.json \
    config/config-sudocu-mpd.json \
    config/config-sudocu-mpc.json \
    config/config-sudocu-gestion.json \
    sudocu.yml
```


### Crear secretos
1. Copiar el template de los `secrets`:
```bash
cp sudocu-api-server-secret.json.dist sudocu-api-server-secret.json
```

1. Editar el archivo `sudocu-api-server-secret.json` con los datos que correspondan:
```json
{
  "auth_providers_basic_password": "integracion",
  "repositorios_arai_password": "docs123",
  "firma_password": "docs123",
  "db_password": "postgres",
  "redis_options_password": "redis"
}
```

- `auth_providers_basic_password`: Password de autenticación básica del servicio de integración de Sudocu.
- `repositorios_arai_password`: Password de servicio Araí Documentos.
- `firma_password`: Password de servicio firma de Araí Documentos.
- `db_password`: Password de Postgres de Sudocu.
- `redis_options_password`: Password de Redis de Sudocu.

```bash
docker secret create sudocu-api-server ./sudocu-api-server-secret.json
```

### Acceso a Postgres
Editar la configuracion de conexión a la base de datos en el archivo `config/config-api-server.json`:
```json
  "ungsxt": {
    "host": "db-sudocu",
    "port": "5432",
    "database": "sudocu",
    "user": "postgres"
  }
```

## Creación de Base de Datos

> Antes de crear la estructura de la base hay que crear el `schema` sudocu:
>   ```bash
>   createdb -h DB_HOST -U DB_USER -p DB_PORT sudocu
>   psql -h DB_HOST -U DB_USER -p DB_PORT -c "CREATE SCHEMA sudocu; ALTER SCHEMA sudocu OWNER TO postgres;" sudocu 
>   ```
1. Inicializar la base de datos. Cambiar los valores de conexión.
   ```bash
   docker run --rm \
     --env SUDOCU_DB_HOST=db-sudocu \
     --env SUDOCU_DB_NAME=sudocu \
     --env SUDOCU_DB_PORT=5432 \
     --env SUDOCU_DB_USER=postgres \
     --env SUDOCU_DB_PASSWORD=postgres \
     ungs/sudocu-db-instalador:1.3.6
   ```

## Deploy

```bash
docker stack deploy --with-registry-auth --compose-file sudocu.yml sudocu
```

## Registrar Sudocu como Service Provider en Araí Usuarios

Debe registrarse de manera manual desde Araí-Usuarios. Para hacerlo siga los siguientes pasos:
1. Ingrese a Araí-Usuarios (user `admin` y password seteado [anteriormente](arai#bootstraping-del-proyecto))
1. Dirigirse al item Aplicaciones
1. Presionar el botón `Agregar +`
1. Completar de la siguiente manera el tab `Datos Generales`
   * Url: https://uunn.local/sudocu
   * Nombre: Sudocu
   * Cómo ícono colocar esta imagen: https://hub.siu.edu.ar/siu/expedientes/-/blob/master/var/logos/sudocu.png
1. Completar de la siguiente manera el tab `SAML`
   * Chequear la opción `Activo`
   * Entity Id: https://uunn.local/sudocu
   * Assertion Consumer Serv.: https://uunn.local/sudocu/api/auth/saml/callback
   * Single Logout Serv.: https://uunn.local/sudocu/#!/sso/logout_local
1. Presionar el botón `Guardar`

## Crear usuario Admin de Sudocu en Araí Usuarios
1. Ingrese a Araí-Usuarios (user `admin` y password seteado [anteriormente](arai.md#bootstraping-del-proyecto))
1. Dirigirse al item Usuarios
1. Presionar el botón `Agregar +`
1. Completar de la siguiente manera el tab `Perfil`:
   * Identificador: adminsudocu
   * Nombre: Admin
   * Apellido: Sudocu
   * Nombre: Admin
   * E-mail: admin@sudocu.edu.ar
   * Password: ******
1. Presionar el botón `Guardar`
1. Completar de la siguiente manera el tab `Cuentas`
   * Aplicación: Sudocu
   * Cuenta: adminsudocu
1. Presionar el botón `Agregar`
1. Presionar el botón `Guardar`



> Una vez realizados estos pasos, debería poder acceder en https://uunn.local/sudocu (o el dominio que haya definido)

Para mayor información y documentación funcional recurrir a la [página oficial de SUDOCU](https://sudocu.dev).

## Actualización de versión
> IMPORTANTE: En las actualizaciones es posible que se incluyan nuevos parámetros en los archivos de configuración del api-server y los distintos modulos de SUDOCU. Por lo tanto, es necesario en cada actualización comparar los archivos de configuración desplegados localmente con el archivo config-default.json ubicado en la raíz de cada módulo, y agregar los parámetros que no se encuentren en el archivo local.

1. Borrar el stack actual:
```bash
docker stack rm sudocu
```

> Antes de actualizar es necesario realizar un backup de la base de datos.
>
> ```bash
> pg_dump -h DB_HOST -U DB_USER -p DB_PORT sudocu > sudocu.$(date -I).sql
> ```

2. Realizar nuevo deploy:
```bash
docker stack deploy --with-registry-auth --compose-file sudocu.yml sudocu
```

3. Actualizar la base de datos:
```bash
docker run --rm \
  --env SUDOCU_DB_HOST=db-sudocu \
  --env SUDOCU_DB_NAME=sudocu \
  --env SUDOCU_DB_PORT=5432 \
  --env SUDOCU_DB_USER=postgres \
  --env SUDOCU_DB_PASSWORD=postgres \
  ungs/sudocu-db-instalador:1.3.6
```

