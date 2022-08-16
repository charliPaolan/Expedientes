---
id: version-1.3.0-guia-backup-nfs
title: Haciendo backups en volumen NFS
sidebar_label: Backup en NFS
original_id: guia-backup-nfs
---

Cuando se esta en producción con la solución EEI quizás sea necesario hacer Backups de los volumenes de las imagenes para no perder nada.

> Nota: este ejemplo es para el caso del contenedor `sudocu.yml` pero se puede hacer con `usuarios.yml` y `traefik.yml`


## Requisitos previos

 - Existe un server NFS en la infraestructura, si no es su caso le recomendamos seguir esta [guía](guia-nfs-swarm.md)
 - Tiene conocimiento de configuracion de volumenes NFS, en otro caso le recomendamos esta [lectura previa](guia-config-nfs.md).


## Levantando el volumen para backup

Como se está en producción, se necesita PRIMERO levantar una segunda carpeta en el contenedor que esta corriendo (para copiar desde dentro del contenedor todos los archivos al servidor nfs).

Para hacer esto se procede de la siguiente forma:

 * En `sudocu.yml` se agrega un volume adicional, vinculandolo a otra carpeta del contenedor:

```yaml
volumes:
 files:
 sudocu_files:
   driver: local
   driver_opts:
     type: nfs
     o: nfsvers=4,addr=10.1.64.101,rw
     device: ":/recursos_nfs/sudocu_storage"
```

(notese que el volume `files` sigue sin configurarse, sino que se agrega otro volumen llamado `sudocu_files`)


 * Dentro del servicio `api-server` en la sección `volumes` se agrega el segundo volumen recién creado:

```yaml
   volumes:
     - files:/app/sudocu-files
     - sudocu_files:/app/sudocu-files-bkp
```

 * Luego de tener configurado así `sudocu.yml`, se hace un nuevo deploy del stack sudocu (`solo actualización de containers`)

```bash
docker stack deploy --with-registry-auth --compose-file sudocu.yml sudocu
```

Esto hace que se levante el segundo "volume" vinculado al sevidor nfs, en la carpeta del contenedor `/app/sudocu-files-bkp`


## Backupeando los archivos

 * Luego de hacer esto, nos conectamos al bash del contenedor para correr el comando para copiar lo que hay en `/app/sudocu-files` a la carpeta `/app/sudocu-files-bkp`

```bash
docker exec -it sudocu_api-server.1.r5hqywh18tdf9owi7qn4fx78i /bin/bash
```

y ya dentro del contenedor se ejecuta

```bash
cp -p -r /app/sudocu-files /app/sudocu-files-bkp
```

> (-p para que preserve los atributos, y -r para que lo haga de forma recursiva)

Hecho esto, se copiaron todos los archivos y estructura de directorios al servidor nfs

> NOTA: Después hay que bajarlos un nivel de path, pues con ese comando se copian creando una carpeta adicional `sudocu-files` que al momento de implementar no tiene que estar... es decir, que en el servidor NFS se copia todo a `/recursos*nfs/sudocu_storage/sudocu-files/*` , hay que bajarlos a `/recursos*nfs/sudocu_storage/*`


## Restaurando el estado anterior

Ya con todos los archivos copiados al volumen NFS

    * Se procede a bajar el stack
    * Eliminar los volumes involucrados

```bash
docker stack rm sudocu
docker volume rm sudocu_files
docker volume rm sudocu_sudocu_files
```

    * Eliminar de la configuración el segundo volumen denominado `sudocu_files`
    * Volver a hacer el deploy para dejar todo como al inicio

```bash
docker stack deploy --with-registry-auth --compose-file sudocu.yml sudocu
```
