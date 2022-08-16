---
id: seguridad
title: Seguridad en el acceso de servicios
sidebar_label: Seguridad de servicios
---

La solución de **Expediente Electrónico Integrado** esta compuesta por múltiples componentes que cooperan para construir y sostener la
gestión integral de documentos y expedientes de manera distribuida. 

Estos componentes exponen diversas APIs que permiten llevar adelante la integración de los mismos, sin embargo no deberian ser accesibles 
desde fuera del cluster ya que permiten realizar tareas administrativas de alto nivel. En caso que fuera imprescindible para la 
comunicación con modulos o aplicaciones propias de la institución se deben tomar medidas adicionales.

Asi como algunos servicios de las instituciones estan disponibles únicamente accediendolos mediante una VPN desde el exterior, en 
el caso de ***EEI*** los servicios que brinda el cluster deben tener un mecanismo de protección adicional (control de acceso) para con 
su entorno externo (ej: LAN de la institución.

Lo más recomendable entonces es establecerlo por medio de la infraestructura, para evitar exponer dichas APIs al acceso desde ubicaciones 
no confiables que pudieran derivar en ataques externos/accesos no autorizados.

## Filtrar Acceso

En el caso de `EEI` esto lo podemos llevar adelante mediante los labels en la configuración del reverse proxy Traefik.

A modo de ejemplo, una configuración para `Arai-Documentos` podría contener algunos o todos los siguientes `labels`

```yml
labels:
        - "traefik.enable=true"
        - "traefik.http.routers.docs.entrypoints=web-secured"
        - "traefik.http.routers.docs-backend.entrypoints=web-secured"
        - "traefik.http.routers.docs.rule=Host(`uunn.local`) && ( PathPrefix(`/docs/rest/frontend`) || Path(`/docs/firmador.php`) )"
        - "traefik.http.routers.docs-backend.rule=Host(`uunn.local`) && PathPrefix(`/docs/rest/backend`)"
        - "traefik.http.routers.docs.tls=true"
        - "traefik.http.routers.docs-backend.tls=true"
        - "traefik.http.services.docs.loadbalancer.server.port=80"
        - "traefik.http.middlewares.docs-ipwhitelist.ipwhitelist.sourcerange=127.0.0.1/32,172.27.100.0/24"
        - "traefik.http.routers.docs.middlewares=security-headers@file"
        - "traefik.http.routers.docs-backend.middlewares=security-headers@file,docs-ipwhitelist"
```

> Nota. Debe reemplazar la IP/RED por el rango que esté autorizado acceder al servicio

### Exponiendo API de Arai-Documentos

En particular si deseamos exponer un endpoint particular de una API deberemos definir como minimo un par de labels para la ruta y su activación.

```yml
- "traefik.http.routers.docs-backend.rule=Host(`uunn.local`) && PathPrefix(`/docs/rest/backend`)"
- "traefik.http.routers.docs-backend.tls=true"
```

Luego deberiamos acotar el rango de ubicaciones desde las cuales este endpoint en particular (o todos los endpoints) es accesible.
Para ello primero definiremos un ***whitelist*** de IPs válidos y luego lo aplicaremos al endpoint correspondiente. Recuerde colocar los valores 
adecuados a su ambiente.

```yml
- "traefik.http.middlewares.docs-ipwhitelist.ipwhitelist.sourcerange=127.0.0.1/32,172.77.100.0/24"
- "traefik.http.routers.docs-backend.middlewares=security-headers@file,docs-ipwhitelist"
```

Sin esta última regla, el endpoint es accesible por todo el rango de IPs que lleguen hasta Traefik, potencialmente todo el mundo si tiene IP pública.
