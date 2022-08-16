---
id: version-1.3.0-guia-cambio-dominio
title: Cambiar el Dominio del despliegue existente
sidebar_label: Cambiar dominio
original_id: guia-cambio-dominio
---

1. Bajar los stacks de los servicios

```bash
docker stack rm traefik sudocu usuarios huarpe docs
```

2. Modificar el dominio nuevo en `traefik_le.yml` y `loki.yml`

```bash
export DOMAIN_NAME_URL=dominionuevo.edu.ar
sed -i "s/dominioviejo.edu.ar/${DOMAIN_NAME_URL}/g" \
    traefik.le.yml
```

#### Let's Encrypt

Se descomentan las lineas que siguen en `traefik_le.yml`.

 - `certificatesresolvers.le-uunn-local.acme.caserver=https://acme-staging-v02.api.letsencrypt.org/directory`
 - `certificatesresolvers.le-traefik-uunn-local.acme.caserver=https://acme-staging-v02.api.letsencrypt.org/directory`

Una vez que vea que el certificado de prueba se expidió correctamente, es momento de comentar las líneas para utilizar la CA real.

#### Loki
```bash
sed -i "s/dominioviejo.edu.ar/${DOMAIN_NAME_URL}/g" \
 loki.yml
```

3. Cambiar dominio en los archivos de los servicios

Para cambiarlo por el dominio definitivo puede utilizar el siguiente comando (reemplace `dominionuevo.edu.ar` por el dominio real que utilizará durante el despliegue)

```bash
sed -i "s/dominioviejo.edu.ar/${DOMAIN_NAME_URL}/g" \
    usuarios.api.env \
    usuarios.idp.env \
    usuarios.env \
    usuarios.yml \
    docs.yml \
    docs.env \
    huarpe_parameters.yml \
    huarpe.yml
```

#### Desplegar Traefik

Se despliega nuevamente traefik al stack

```bash
docker stack deploy -c servicios/traefik.le.yml traefik
```

> Esto se hace las veces que sea necesario hasta que en el log aparece lo siguiente:

```text
time="2021-07-14T17:15:17Z" level=info msg="Configuration loaded from flags.",
time="2021-07-14T17:15:17Z" level=info msg="Traefik version 2.2.11 built on 2020-09-07T14:12:48Z",
time="2021-07-14T17:15:17Z" level=info msg="\nStats collection is disabled.\nHelp us improve Traefik by turning this feature on :)\nMore details on: https://docs.traefik.io/contributing/data-collection/\n",
time="2021-07-14T17:15:17Z" level=info msg="Starting provider aggregator.ProviderAggregator {}",
time="2021-07-14T17:15:17Z" level=info msg="Starting provider *file.Provider {\"directory\":\"/etc/traefik\",\"watch\":true}",
time="2021-07-14T17:15:17Z" level=info msg="Starting provider *docker.Provider {\"watch\":true,\"endpoint\":\"unix:///var/run/docker.sock\",\"defaultRule\":\"Host(`{{ normalize .Name }}`)\",\"swarmMode\":true,\"network\":\"traefik-public\",\"swarmModeRefreshSeconds\":15000000000}",
time="2021-07-14T17:15:17Z" level=info msg="Starting provider *traefik.Provider {}",
time="2021-07-14T17:15:17Z" level=info msg="Starting provider *acme.Provider {\"email\":\"admin-dom@examples.com\",\"caServer\":\"https://acme-staging-v02.api.letsencrypt.org/directory\",\"storage\":\"/certs/acme-uunn-local.json\",\"keyType\":\"RSA4096\",\"httpChallenge\":{\"entryPoint\":\"web\"},\"ResolverName\":\"le-uunn-local\",\"store\":{},\"ChallengeStore\":{}}",
time="2021-07-14T17:15:17Z" level=info msg="Testing certificate renew..." providerName=le-uunn-local.acme,
time="2021-07-14T17:15:17Z" level=info msg="Starting provider *acme.Provider {\"email\":\"admin-dom@examples.com\",\"caServer\":\"https://acme-staging-v02.api.letsencrypt.org/directory\",\"storage\":\"/certs/acme-traefik-uunn-local.json\",\"keyType\":\"RSA4096\",\"httpChallenge\":{\"entryPoint\":\"web\"},\"ResolverName\":\"le-traefik-uunn-local\",\"store\":{},\"ChallengeStore\":{}}",
time="2021-07-14T17:15:17Z" level=info msg="Testing certificate renew..." providerName=le-traefik-uunn-local.acme,
time="2021-07-14T17:15:47Z" level=info msg="Skipping same configuration" providerName=docker,
```
#### Actualizar Base de Datos y Desplegar Contenedores

1. Modificar en base de datos de Arai-Usuarios en Postgres las tablas `aplicaciones` y `conector_saml` los registros con los valores con el nuevo dominio

   > Nota: si se cambia el IP del servidor que aloja SEEI hay que tambíen darle acceso en `pg_hba.conf` de Postgres al IP nuevo

2. Desplegar el stack de servicios de Arai

 * Desplegar el stack de Usuarios

```bash
docker stack deploy --with-registry-auth -c usuarios.yml usuarios
```

 * Desplegar el stack de Documentos

```bash
docker stack deploy --with-registry-auth -c docs.yml docs
```

 * Desplegar el stack de SIU-Huarpe

```bash
docker stack deploy --with-registry-auth -c huarpe.yml huarpe
```

> Una vez realizados estos pasos, debería poder acceder a Huarpe en `https://dominionuevo.edu.ar/` (o el dominio que haya definido)


### Desplegar SUDOCU

 * Modificar dominio

Para reemplazarlo por el dominio definitivo puede utilizar
el siguiente comando:

```bash
sed -i "s/dominioviejo.edu.ar/${DOMAIN_NAME_URL}/g" \
    config/config-api-server.json \
    config/config-sudocu-login.json \
    config/config-sudocu-mpd.json \
    config/config-sudocu-mpc.json \
    config/config-sudocu-gestion.json \
    sudocu.yml
```

 * Re-deploy

```bash
docker stack deploy --with-registry-auth --compose-file sudocu.yml sudocu
```

 * Actualizar la base de datos:

```bash
docker run --rm \
  --env SUDOCU_DB_HOST=db-sudocu \
  --env SUDOCU_DB_NAME=sudocu \
  --env SUDOCU_DB_PORT=5432 \
  --env SUDOCU_DB_USER=postgres \
  --env SUDOCU_DB_PASSWORD=postgres \
  ungs/sudocu-db-instalador:1.1.8
```
