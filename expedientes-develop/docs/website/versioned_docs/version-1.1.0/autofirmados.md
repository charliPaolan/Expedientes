---
id: version-1.1.0-autofirmados
title: Configurar Certificados de Prueba
sidebar_label: Autofirmados
original_id: autofirmados
---

Para realizar pruebas básicas se puede disponer de certificados autofirmados, recuerde que estos certificados NO son válidos para un entorno productivo y que los navegadores solicitarán agregar excepciones para permitir la navegación.

Previo a la generación de los certificados, asegurese de haber cumplimentado los pasos [previos](../redes.md#modificacion-de-dominio-base).

### Generando Certificados de prueba

Primeramente generamos un directorio para contener los certificados en cuestion:

```bash
mkdir -p prod/servicios/certs
cd prod/servicios/certs
```

Si aún no realizo el siguiente paso, es un buen momento:
```bash
export DOMAIN_NAME_URL=universidad.edu.ar
```

Para generar el par de certificado y clave, utilizaremos `Openssl` en su última versión disponible.

```bash
openssl req -x509 -out $DOMAIN_NAME_URL.crt -keyout $DOMAIN_NAME_URL.key \
  -newkey rsa:2048 -nodes -sha256 -subj "/C=AR/CN=$DOMAIN_NAME_URL" \
  -addext "subjectAltName = DNS:$DOMAIN_NAME_URL" -days 1024
```

> NOTA: Es responsabilidad del lector la creación y administración de estas claves. Recuerde no comitear la key

### Configurando los certificados generados

Para utilizar sus certificados es necesario cargar la clave pública como una `config` y la key como un `secret`:
```bash
docker config create traefik_tls_cert servicios/certs/${DOMAIN_NAME_URL}.crt
docker secret create traefik_tls_key servicios/certs/${DOMAIN_NAME_URL}.key
```

Luego de realizados estos pasos, continue con el [procedimiento](../redes.md#headers-de-seguridad) de despliegue.
