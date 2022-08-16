---
id: version-1.0.0-servicios-base
title: Servicios base
sidebar_label: Servicios base
original_id: servicios-base
---

 Estos son los servicios deben estar funcionando en su ambiente antes de instalar la solución. Por motivos de confiabilidad, performance y simplicidad se recomienda instalar Postgres, Nuxeo y LDAP por fuera de Docker o Swarm.

![Componentes](assets/base.png)

## Docker Swarm

Es necesario tener un clúster de Docker Swarm funcionando. La forma de crearlo va a depender fuertemente de la infraestructura disponible.

Un requerimiento básico es que los nodos pertencientes al clúster pertenezcan todos a una red interna, que no se pueda acceder desde el mundo externo.

A continuación se agregan un par de referencias de cómo crear un cluster.
* https://docs.docker.com/engine/swarm/
* https://medium.com/swlh/six-tips-for-running-swarm-cluster-in-production-b71cc6763b39
* https://dockerlabs.collabnix.com/intermediate/Implementing_High_Availability_with_Docker_Swarm.html

## Postgres

Se requiere un servidor Postgres 10 o superior. En el mismo se deben crear tres bases que estén accesibles por el clúster. Los siguientes módulos son las que las utilizan:
* Araí-Usuarios
* Araí-Documentos 
* Sudocu 

## Nuxeo

Se utiliza NUXEO como servidor CMIS 1.0 compatible (https://www.nuxeo.com/)

## LDAP

Se recomienda utilizar OpenLdap (https://www.openldap.org/). En esta url existe información sobre
cómo instalarlo bare-metal directamente o sobre Docker: https://documentacion.siu.edu.ar/usuarios/docs/cache/instalacion-bases-ldap/.

Si su institución ya cuenta con una base LDAP póngase en contacto con el equipo de Araí-Usuarios para
analizar la manera de integrar los esquemas necesarios.

## Almacenamiento compartido

Hay imagenes dentro de la solución que utilizan volumenes. Si se desea que esas imagenes corran
en más de un nodo específico, es necesario que los volumenes puedan montarse en cualquier nodo.

### NFS
Existen varias maneras de lograr esto, la más simple es utilizando NFS. La manera de implementarlo
es creando un server NFS y asegurando que todos los nodos puedan conectarse al mismo como clientes.

Una vez hecho eso, es necesario instalar en cada nodo un plugin de Docker que permite especificar
volumenes de tipo NFS. El plugin es este: http://netshare.containx.io/.

En los ymls (usuarios.yml y sudocu.yml) que utilizan los volúmenes está la forma de levantarlo desde NFS comentada.

A continuación se dejan unas guías de configuración básica para usar como referencia
* https://collabnix.com/docker-1-12-swarm-mode-persistent-storage-using-nfs/
* https://sysadmins.co.za/docker-swarm-persistent-storage-with-nfs/

### Otros medios
NFS es la manera más simple de configurar almacemiento pero tiene algunos problemas, el más
notable es que es un punto de falla centralizado.

Se pueden utilizar otros medios de persistencia, como por ejemplo, GlusterFS. 

Si alguna institución avanza con una solución distinta a NFS sería bueno que nos contacten 
y analizar si podemos incluir alguna guía para facilitar a la comunidad.

