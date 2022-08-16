---
id: version-1.0.5-repo-config
title: Repositorio de configuración
sidebar_label: Repositorio de configuración
original_id: repo-config
---

El proyecto es distribuido a traves de un repositorio GIT compuesto por un conjunto de definiciones de stacks de Docker Swarm que permiten desplegar un entorno de producción de referencia. 
Para instalar el proyecto, comience clonando el repositorio.

```bash
git clone -b master https://hub.siu.edu.ar/siu/expedientes
```

> El branch **master** es el que contiene siempre la última versión estable.

Si va a comenzar con la instalación de producción de su institución vea [esta sección](#forma-de-trabajo).
## Contenido

Los siguientes archivos con formato [Docker Compose](https://docs.docker.com/compose/compose-file/) especifican los stacks principales de la solución.  

| Archivo                 | Archivo             |
|-------------------------|---------------------|
| [prod/sudocu/sudocu.yml](https://hub.siu.edu.ar/siu/expedientes/-/blob/master/prod/sudocu/sudocu.yml)  | Especificación stack Sudocu |
| [prod/arai/usuarios.yml](https://hub.siu.edu.ar/siu/expedientes/-/blob/master/prod/arai/usuarios.yml)  | Especificación stack Araí-Usuarios |
| [prod/arai/docs.yml](https://hub.siu.edu.ar/siu/expedientes/-/blob/master/prod/arai/docs.yml) | Especificación stack Araí-Documentos |
| [prod/arai/huarpe.yml](https://hub.siu.edu.ar/siu/expedientes/-/blob/master/prod/arai/huarpe.yml) | Especificación stack SIU-Huarpe |


## Login en la Registry de Imagenes

Las imágenes de Docker referenciadas en las descripciones de los Stacks se encuentran en un repositorio del SIU que requiere autenticación. Para continuar auntentiquese en el mismo

```bash
docker login hub.siu.edu.ar:5005
```

## Forma de trabajo

El repositorio entregado está pensado como una base para crear una instalación personalizada para la institución de la solución.

Para llevar adelante el deploy exitosamente se recomienda mantener un repositorio propio que se vaya sincronizando con el del SIU para poder acceder a las nuevas versiones.

A continuación veremos una forma simple de mantener el repositorio local.

### Creación del repo
Imaginemos que se creó el repositorio `https://git.uunn.local/deploy` vacío. Para comenzar a trabajar lo primero que hay que hacer es clonar este repo:
```bash
git clone https://git.uunn.local/deploy
```

Luego hay que establecer como upstream el repositorio del SIU:

```bash
git remote add upstream https://hub.siu.edu.ar/siu/expedientes.git
```

Una vez hecho esto, se contará con un repositorio listo para sincronizarse con el del SIU

### Descarga inicial

En este momento, el directorio de trabajo se encuentra vacío. Para obtener los fuentes desde `upstream` ejecutar el siguiente comando:

```bash
git fetch upstream
```
Una vez completado ese paso ejecutar

```bash
git merge upstream/master
```

Si ahora ejecutamos `ls` veremos que ya tenemos el código en nuestra working copy. Podemos ejecutar el siguiente comando para verificar a que versión estamos apuntando.

```bash
cat version
```

Este es un buen momento para subir el código a nuestro repositorio local:

```bash
git push
```

### Modificar localmente

Una vez completados los pasos anteriores ya estamos listos para empezar a trabajar. Se deberán editar los archivos (como se ve a lo largo de todo el resto de la documentación) para reflejar nuestra instalación. Esto es, cambiar urls, configuraciones de certificados, secretos, etc.

Cuando llegamos a una configuración deseada en la que estamos contentos con el deploy realizado es momento de comitear nuestro trabajo y subirlo. Se deberan agregar los cambios al stage y crear un nuevo commit:

```bash
git commit -m "config inicial"
```

Es recomendable subirlo:
```bash
git push
```

### Actualizar versión
Imaginemos que se libera una nueva versión de la solución. El objetivo de este paso es lograr incorporar los cambios de la nueva versión sin perder los cambios propios de nuestra instalación. Para hacer esto ejecutaremos (sobre la working copy sin cambios):

```bash
git fetch upstream
```
y

```bash
git merge upstream/master
```

En este estado tendremos en nuestra working copy los cambios de la nueva versión mezclados con nuestros cambios locales. Es posible que en este paso ocurra algún conflicto. Si es así, seguir los pasos indicados en el output del merge.

> **IMPORTANTE**: Antes de hacer el deploy de estos cambios hay que mirar en detalle el CHANGELOG de la versión descargada para asegurarse que no haya ningún cambio bloqueante.

Una vez que se haga el deploy exitosamente, es momento de comitear los cambios y subirlos a nuestro repositorio.

```bash
git commit -m "Actualización a vX.Y.Z"
```

```bash
git push
```

### Posibles Mejoras
El esquema de manejo de versiones aquí provisto asume que existe un sólo branch en el repositorio local y que en la institución se hace sólo un deploy, el de producción.

Esto puede llegar a ser limitado si quiere contar con diferentes `stages` que permitar probar las nuevas versiones antes de ponerlas en producción.

Si se desea hacer un manejo multi-stage es recomendable mantener un branch para cada stage por separado y cada uno manejarlo de la misma manera que se maneja `master` en el esquema presentado.
