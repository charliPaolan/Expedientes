---
id: version-1.3.0-guia-config-nfs
title: Configurando un volumen NFS
sidebar_label: Volumen NFS
original_id: guia-config-nfs
---

En esta guía se indica como realizar la configuración de un volumen a NFS en un servicio, utilizaremos como ejemplo el stack contenido en el archivo `sudocu.yml` pero la técnica es aplicable a los stacks de los módulos restantes de SEEI.


## Requisitos previos

Se presupone que existe un server NFS en la infraestructura, si no es su caso le recomendamos seguir esta [guía](guia-nfs-swarm.md)
 

## Configuración de volumen a NFS (ejemplo sudocu.yml)

La solución tiene levantado el servicio de NFS en la infraestructura y luego se configura el volumen "files" que por defecto viene sin configuración. quedando así:

```yaml
volumes:
 files:
   driver: local
   driver_opts:
     type: nfs
     o: nfsvers=4,addr=10.1.64.101,rw
     device: ":/recursos_nfs/sudocu_storage"
```

De esta forma, la carpeta `/app/sudocu-files` del contenedor esta vinculada al servidor nfs y todo lo subido como adjunto se almacena allí y no en el contenedor.

