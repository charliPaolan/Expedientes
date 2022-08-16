---
id: secretos
title: Secretos y configuraciones
sidebar_label: Secretos y configuraciones
---

Las lineas rojas muestran interacciones entre sistemas. Estas comunicaciones requieren autenticacion. Los nodos amarillos requieren certificados.

![Componentes](assets/secretos.png)

Los secretos son blobs de información que deben almacenarse de forma segura y no pueden ser versionados. Ejemplos de esto son: passwords, claves de SSH, certificados SSL, etc. Más información [aquí](https://docs.docker.com/engine/swarm/secrets/)

Por otro lado, los elementos de configuración de swarm permiten definir datos que son necesarios pero no confidenciales, como por ejemplo una clave pública. Algunas configuraciones son creadas automáticamente cuando se despliegan los stacks y otras es necesario crearlas de manera manual.

Los servicios que conforman esta documentación requieren que ciertos secretos y configuraciones estén definidos **antes** de comenzar el despliegue. 

### Ejemplos de secretos
Los secretos se crean usando los comandos incluídos en Docker. Por ejemplo: 
```bash
# crea el secreto del password de la base de datos Postgres de Usuarios
printf "postgres123" | docker secret create usuarios_db_pass -
```
Se recomienda utilizar `printf` porque `echo` agrega por defecto un `\n` al final.

Para generar valores aleatorios se puede utilizar alguna de [estas utilidades](https://gist.github.com/earthgecko/3089509) y hacerlo directamente en bash. Por ejemplo:
```bash
# crea el salt de passwords de usuarios
printf $(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 20 | head -n 1) | docker secret create usuarios_pass_salt -
```

También se pueden generar secreto a partir de un archivo. Por ejemplo:
```bash
docker secret create usuarios_idp_oidc_key certs/certificado_idp.key
```
### Ejemplos de configuraciones
Ejemplo de creación de una `config`:
```bash
docker config create usuarios_idp_saml_cert certs/certificado_idp.crt
```

A continuación se detalla una lista de los secretos y configuraciones que son necesarios para el funcionamiento de cada módulo base.


> NOTA: Puede utilizar el script llamado `10-crear-secretos-INSEGURO.sh` para ver cómo
crear los diferentes secretos con el formato requerido.

> NOTA: Si se usan las bases de datos de prueba (`db-arai.yml`) los secretos que se definan acá se utilizarán como contraseña en esas instancias.
En el caso de que ya cuente con otros servidores estos secretos deben ser cargados con las credenciales allí definidas.

## Usuarios
### Secretos

* `usuarios_db_pass`: Password de la conexión con la base de datos.
* `usuarios_ldap_admin_pass`: Password de bind de admin de ldap
* `usuarios_ldap_config_pass`: Password de bind del config de ldap
* `usuarios_pass_salt`: Salt de los passwords generados por Araí-Usuarios
* `usuarios_api_users`: Json que define pares de usuario/password para la autenticación de la API de usuarios
* `usuarios_idp_simplesaml_admin`: Password del panel de control de Administrador provisto con SimpleSAMLPhp
* `usuarios_idp_saml_key`: Archivo que contiene la pkey con la se firman los tokens SAML
* `usuarios_idp_oidc_key`: Archivo que contiene la pkey con la se firman los tokens de OIDC

### Configuraciones
* `usuarios_idp_saml_cert`: Clave pública de la firma de SAML
* `usuarios_idp_oidc_cert`: Clave pública de la firma de OIDC

### Volumenes
* `usuarios_assets_vol`: Volumen utilizado para guardar las imagenes de perfil de usuarios e íconos de aplicaciones

### Generar certificados necesarios
La forma más rápida de generar los certificados necesarios es realizando las siguientes acciones:
[ @TODO link al hub ]
```bash
mkdir certs
docker run -it -v $(pwd)/certs:/certs gitlab.siu.edu.ar:5005/siu-arai/arai-usuarios/idp:develop -- "apk add openssl && idp/bin/instalador instalacion:generar-certs -n --destino /certs"
```
Este comando, creará las keys necesarias y las dejará en el directorio `certs`.
```bash
# ls certs
certificado_idp.crt  certificado_idp.key  oidc_module.crt  oidc_module.pem
```

Mapeo de secrets|configs a archivos generados:

* Secretos:

| Secret                | Archivo             |
|-----------------------|---------------------|
| usuarios_idp_saml_key | certificado_idp.key |
| usuarios_idp_oidc_key | oidc_module.pem     |

* Configs:

| Config                | Archivo             |
|-----------------------|---------------------|
| usuarios_idp_saml_cert | certificado_idp.crt |
| usuarios_idp_oidc_cert | oidc_module.crt     |

También pueden ser generados manualmente [ @TODO agregar comandos ]

## Documentos

### Secretos

* `docs_api_pass`: Password de la API de Documentos
* `docs_db_pass`: Password de la conexión con Postgres
* `docs_repo_pass`: Password de la conexión con Nuxeo
* `docs_conexion_usuarios`: Credenciales y endpoint de la conexión con Usuarios
* `docs_conexion_sudocu`: Credenciales y endpoint de la conexión con SUDOCU

## Huarpe
### Secretos

* `huarpe_secret`: Token de 31 caracteres
* `huarpe_conexion_usuarios`: Credenciales de la conexión por API con Usuarios
* `huarpe_conexion_docs`: Credenciales de la conexión por API con Documentos

