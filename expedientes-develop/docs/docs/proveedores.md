---
id: proveedores
title: SIU-Araí Proveedores
sidebar_label: SIU-Araí Proveedores
---

Araí Proveedores es un módulo que brinda herramientas para sincronizar datos de proveedores entre distintos clientes y proveer una API para la consulta y actualización de dicha información.

Está compuesto por dos submódulos:

https://gitlab.siu.edu.ar/siu-arai/arai-proveedores es consumido como librería, provee un cli y se encarga del versionado de la base. La documentación de dicho submódulo puede consultarse en https://documentacion.siu.edu.ar/wiki/SIU-Arai/proveedores

https://hub.siu.edu.ar/siu-arai/proveedores-api es la API cuya definición puede consultarse en https://documentacion.siu.edu.ar/apis/?spec=proveedores_v1

#### Interacción con sistemas SIU

SIU Diaguita y SIU Pilaga utilizan la librería para sincronizar los datos de proveedores.
El Portal del proveedor disponible en SIU Huarpe utiliza la API para consultar los datos del proveedor.

#### Esta es la lista de secretos requeridos por Araí Proveedores durante el despliegue:

* `proveedores_api_pass`: Password de la API de Proveedores
* `proveedores_db_pass`: Password de la conexión con Postgres
* `proveedores_conexion_usuarios`: Credenciales y endpoint de la conexión con Usuarios

#### Creación de secretos

La distribución provee el script de bash [`proveedores-secrets.sh.dist`](https://hub.siu.edu.ar/siu/expedientes/-/blob/master/prod/proveedores-secrets.sh.dist) para ejemplificar como inicializar todos los valores requeridos. Si desea mantener un archivo propio con las claves de su ambiente ejecute:

```bash
cp proveedores-secrets.sh.dist proveedores-secrets.sh
```
y **modifique el script** `proveedores-secrets.sh` con los datos correspondientes a su entorno. Luego ejecutelo para cargar los secretos dentro de Docker.

```bash
./proveedores-secrets.sh
```
## Configurar y desplegar API Araí-Proveedores

La especificación del stack de este módulo se encuentra en [`proveedores.yml`](https://hub.siu.edu.ar/siu/expedientes/-/blob/master/prod/arai/proveedores.yml). Existe otro archivo de configuración asociado: [`proveedores.env`](https://hub.siu.edu.ar/siu/expedientes/-/blob/master/prod/arai/proveedores.env)

### Cambiar Dominio

Reemplazar `universidad.edu.ar` por el valor correcto utilizando el siguiente comando.

```bash
sed -i 's/uunn.local/universidad.edu.ar/g' \
    proveedores.yml \
    proveedores.env
```
### Conexión con Postgres

* `ARAI_PROVEEDORES_URL`: Es la URL base de la API accesible desde fuera
* `ARAI_PROVEEDORES_DB_HOST`: Host de la base de datos
* `ARAI_PROVEEDORES_DB_PORT`: Puerto de la base de datos
* `ARAI_PROVEEDORES_DB_DBNAME`: Nombre de la base de datos
* `ARAI_PROVEEDORES_DB_USERNAME`: Usuario de la base de datos 

### Creación de Base de Datos

Se incluye un comando que crea la estructura de la base de datos de Araí-Proveedores. Para utilizarlo
ejecutar el siguiente comando:
```bash
docker stack deploy \
    --with-registry-auth \
    -c util/proveedores_crear_base.yml \
    crear_db_proveedores
```

Asume que la base de datos especificada en la [sección de la conexión con Postgres](arai#conexión-con-postgres) ya está creada.

### Configurar acceso externo (exponer fuera del cluster con Traefik)

Si desea habilitar el acceso externo a la API se deben descomentar las siguientes líneas en [`proveedores.yml`](https://hub.siu.edu.ar/siu/expedientes/-/blob/master/prod/arai/proveedores.yml)
```
#        - "traefik.enable=true"
#        - "traefik.http.routers.proveedores.entrypoints=web-secured"
#        - "traefik.http.routers.proveedores.rule=Host(`uunn.local`) && PathPrefix(`/proveedores`)"
#        - "traefik.http.routers.proveedores.tls=true"
#        - "traefik.http.services.proveedores.loadbalancer.server.port=80"
#        - "traefik.http.routers.proveedores.middlewares=security-headers@file"
```
### Prueba de funcionamiento

Se puede verificar el correcto funcionamiento de la API ejecutando (reemplazar `uunn.local` por el dominio elegido).

```bash
curl https://uunn.local/proveedores/rest/proveedores/estado -u proveedores:proveedores123
```

### Desplegar el stack

```bash
docker stack deploy --with-registry-auth -c proveedores.yml proveedores
```
### Configuración con SIU Huarpe

En primer lugar se recomienda generar un secret para almacenar la contraseña de la API de Arai-Proveedores. Este paso forma parte de la ejecución del [script](proveedores/#creación-de-secretos)

```bash
printf "proveedores123" | docker secret create proveedores_api_pass -
```

Finalmente se deben definir valores para las restantes variables de entorno necesarias en el archivo `huarpe.env`:

```ini
API_PROVEEDORES_USR=huarpe
API_PROVEEDORES_URL=http://localhost:9191/siu/proveedores/rest/
BUNDLE_PROVEEDORES_ACTIVO=1
```

- **`BUNDLE_PROVEEDORES_ACTIVO:`** Indica que se deben activar los bundles de Proveedores
- **`API_PROVEEDORES_USR:`** Usuario para acceder a la API de Arai-Proveedores.
- **`API_PROVEEDORES_URL:`** URL de la API de Arai-Proveedores. Ej: `https://universidad.edu.ar/proveedores/rest/`


Luego de realizar los cambios en el archivo de configuración se debe actualizar el servicio de **Huarpe**, eliminando en primer lugar el stack y luego realizando nuevamente el deploy de la siguiente manera:

```bash
docker stack rm huarpe
docker stack deploy --with-registry-auth -c huarpe.yml huarpe
```
