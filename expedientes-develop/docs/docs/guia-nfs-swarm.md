---
id: guia-nfs-swarm
title: Instalando NFS en Swarm
sidebar_label: NFS en Swarm
---

Este ejemplo lo guiará en la instalación de un servicio NFS dentro de docker swarm (testeado en Debian 10)

> Nota: Se presuponen 2 equipos `192.168.0.100` como nfsserver y `192.168.0.101` como cliente nfs

## En el servidor de NFS (`192.168.0.100`)

1. Instalo server NFS

```bash
apt update && apt install nfs-kernel-server
```

2. Creo el directorio

```bash
mkdir -p /mnt/nfs_share
chown -R nobody:nogroup /mnt/nfs_share/
chmod 777 /mnt/nfs_share/
```

3. Asigno permisos de acceso

Los permisos para acceder al NFS se gestionan desde `/etc/exports` (editar acorde a lo necesitado, sobre todo el rango de IP)

Si se desea otorgar acceso a un solo cliente, se puede utilizar la siguiente sintaxis

```bash
echo "/mnt/nfs_share  IP_Cliente(rw,sync,all_squash,no_subtree_check)" >> /etc/exports
```

Ejemplo: 

```bash
echo "/mnt/nfs_share 192.168.0.101(rw,sync,all_squash,no_subtree_check)" >> /etc/exports
```

Para otorgar a diversos clientes, se puede agregar más de una linea:

```text
/mnt/nfs_share  IP_Cliente_1 (re,sync,all_squash,no_subtree_check)
/mnt/nfs_share  IP_Cliente_2 (re,sync,all_squash,no_subtree_check)
```

O simplemente puede agregar una subred

Ejemplo en donde agregaríamos una subred de todos los equipos entre `192.168.0.0` a `192.168.0.255`: 

```bash
echo "/mnt/nfs_share 192.168.0.0/24(rw,sync,all_squash,no_subtree_check)" >> /etc/exports
```

4. Exporto el directorio y aplico los cambios

```bash
exportfs -a
systemctl restart nfs-kernel-server
```

Para más información les dejamos los siguientes [links](guia-nfs-swarm.md#lectura-sugerida)

 ---

## En los clientes (`192.168.0.101`)

### Testear que funcione el server NFS (opcional pero recomendado)

Instalo dependencias, creo el directorio donde se van a montar los archivos y lo monto por nfs

```bash
apt update && apt install nfs-common net-tools
mkdir -p /mnt/nfs_clientshare
mount 192.168.0.100:/mnt/nfs_share /mnt/nfs_clientshare # (reemplazo la IP)
```

Ya tenemos un NFS funcionando. 

Para más información les dejamos los siguientes [links](guia-nfs-swarm.md#lectura-sugerida)

### NFS dentro de docker

1. Instalo el [plugin de docker](https://github.com/ContainX/docker-volume-netshare) en cada nodo del swarm y lo arranco

```bash
wget https://github.com/ContainX/docker-volume-netshare/releases/download/v0.36/docker-volume-netshare_0.36_amd64.deb
dpkg -i docker-volume-netshare_0.36_amd64.deb
service docker-volume-netshare start
```

Nota: el servicio no tiene autostart, hay que arrancarlo a mano cada vez que se reinicia el equipo.

2. Pruebo que todo esté en orden con un contenedor por fuera de swarm (opcional pero recomendado)

```bash
docker run -i -t --volume-driver=nfs -v 192.168.0.100/mnt/nfs_share:/mnt/nfs_clientshare ubuntu /bin/bash
```

Deberia tener el directorio montado en /mnt/nfs_clientshare

### NFS dentro de swarm

Es solo cuestión de editar los YML y agregarles la configuración del plugin  
Ejemplo:

```yaml
version: '3.7'
services:
  test:
    image: nginx
    volumes:
      - volumenginx:/mnt/nfs_clientshare
volumes:
  volumenginx:
  driver: nfs
  driver_opts:
    share: "192.168.0.50:/mnt/nfs_share"
```


## Lectura sugerida:

[Google Docs](https://docs.google.com/document/d/1MD3Tupbry4WMIqGYtgdSreshh-0QoispNCl5YaNvQRY/edit)
[Plugin Volumenes] (https://github.com/ContainX/docker-volume-netshare/)
[Tutorial NFS en Ubuntu] (https://www.solvetic.com/tutoriales/article/8310-como-instalar-servidor-nfs-ubuntu-2004/)
