---
id: version-1.0.0-repo-config
title: Repositorio de configuración
sidebar_label: Repositorio de configuración
original_id: repo-config
---

El proyecto es distribuido a traves de un repositorio GIT compuesto por un conjunto de definiciones de stacks de Docker Swarm que permiten desplegar un entorno de produccion de referencia. Los servicios
Para instalar el proyecto, comience clonando el repositorio.

```bash
git clone https://hub.siu.edu.ar/siu/expedientes
```

## Contenido

Los siguientes archivos con formato [Docker Compose](https://docs.docker.com/compose/compose-file/) especifican los stacks principales de la solución.  

| Archivo                 | Archivo             |
|-------------------------|---------------------|
| [prod/sudocu/sudocu.yml](https://hub.siu.edu.ar/siu/expedientes/-/blob/master/prod/sudocu/sudocu.yml)  | Especificación stack Sudocu |
| [prod/arai/usuarios.yml](https://hub.siu.edu.ar/siu/expedientes/-/blob/master/prod/arai/usuarios.yml)  | Especificación stack Araí-Usuarios |
| [prod/arai/docs.yml](https://hub.siu.edu.ar/siu/expedientes/-/blob/master/prod/arai/docs.yml) | Especificación stack Araí-Documentos |
| [prod/arai/huarpe.yml](https://hub.siu.edu.ar/siu/expedientes/-/blob/master/prod/arai/huarpe.yml) | Especificación stack SIU-Huarpe |


## Login en la Registry de Imagenes

Las imágenes de Docker referenciadas en las descripciones de los Stacks se encuentran en un repositorio del SIU que requiere autenticacion. Para continuar auntentiquese en el mismo

```bash
docker login hub.siu.edu.ar:5005
```

## Mantener un repositorio propio

Cuando la solución se encuentra desplegada y todos los valores de configuración hayan sido estableclidos, se recomienda comitear los cambios hechos en su repositorio local para mantener un registro de los parametros de su ambiente. Lo ideal, sería mantener un fork propio de la institución.

Esto le permitirá tambien aplicar los cambios sobre nuevas versiones de esta instalación de referencia.

