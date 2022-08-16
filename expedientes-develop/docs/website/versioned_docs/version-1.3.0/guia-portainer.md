---
id: version-1.3.0-guia-portainer
title: Implementando Portainer para la administración del cluster Swarm
sidebar_label: Administrar con Portainer
original_id: guia-portainer
---

Puede implementar Portainer directamente como un servicio en su clúster de Docker. 

Tenga en cuenta que este método desplegará automáticamente una única instancia de Portainer Server y desplegará Portainer Agent como un servicio global en cada nodo de su clúster.

```bash
curl -L https://downloads.portainer.io/portainer-agent-stack.yml -o portainer-agent-stack.yml

docker stack deploy -c ./portainer-agent-stack.yml portainer
```

> Nota : De forma predeterminada, este stack no habilita las funciones de administración de host, debe habilitarla desde la interfaz de usuario de Portainer.
