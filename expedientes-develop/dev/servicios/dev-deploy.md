Instalando ambientes de desarrollo
---

| Consideraciones  |
|---|
| Estos pasos arman un ambiente inseguro, sólo para desarrollo local |
| Los items marcados con este emoji :pencil2: requieren de su atención |
| Tener en cuenta que existen comandos que finalizan en segundo plano. Marcados con :hourglass: |

### Requisitos minimos para Sudocu+Arai+Huarpe (Ubuntu)
* Procesador: 2 Ghz (Disponibles)
* RAM: 4 Gb (Disponibles)
* Disco: 12 Gb (Mas si desea realizar actualizaciones)

### Cluster Swarm
https://docs.docker.com/engine/reference/commandline/swarm_init/

Si esta en una maquina local puede ser suficiente con:
```bash
docker swarm init
```

### Limpiar entorno
Warning! Borra todos los stacks, volumes, secrets y configs de su entorno


##### Borrar Stacks :hourglass:
```bash
docker stack ls --format {{.Name}} | xargs docker stack rm
```

##### Borrar resto
```bash
docker volume ls --format {{.Name}} | xargs docker volume rm
docker secret ls --format {{.Name}} | xargs docker secret rm
docker config ls --format {{.Name}} | xargs docker config rm
docker system prune --all --volumes
```

### Instalando

#### Completar con dominio de su servidor :pencil2:
```bash
export DOMAIN_NAME_URL=uunn.local
```

#### Agregar dominio inventado en `/etc/hosts` :pencil2:

Usar la IP donde corre docker (ya sea la PC o VM), solo agregar a la PC desde donde se usa el Browser para acceder.

```bash
echo "127.0.0.1	traefil.$DOMAIN_NAME_URL $DOMAIN_NAME_URL" | sudo tee -a /etc/hosts
```

> En Windows suele estar en C:\Windows\System32\drivers\etc\hosts (no fue probado)

#### Autenticarse para poder bajar las imágenes docker

```bash
docker login hub.siu.edu.ar:5005
docker login gitlab.siu.edu.ar:5005

docker network create --driver=overlay traefik-public
docker network create --driver=overlay red-siu
```


#### Modificar dominio en archivos locales
```bash
sed -i 's/uunn\.local/'"$DOMAIN_NAME_URL"'/g' \
    prod/servicios/traefik.le.yml \
    prod/servicios/traefik.yml \
    prod/servicios/tls.toml
```

### Crear Certificados
```bash
mkdir prod/servicios/certs
cd prod/servicios/certs
```

```bash
openssl req -x509 -out $DOMAIN_NAME_URL.crt -keyout $DOMAIN_NAME_URL.key \
  -newkey rsa:2048 -nodes -sha256 -subj "/C=AR/CN=$DOMAIN_NAME_URL" \
  -addext "subjectAltName = DNS:$DOMAIN_NAME_URL" -days 1024
```

```bash
docker config create traefik_tls_cert ${DOMAIN_NAME_URL}.crt
docker secret create traefik_tls_key ${DOMAIN_NAME_URL}.key
```

```bash
cd ..
sed -i 's/--api.dashboard=false/--api.dashboard=true/' traefik.yml
sed -i 's/frameDeny = true/frameDeny = false/' security.toml
docker stack deploy -c traefik.yml traefik
```

#### (Opcional) Loki
```bash
sed -i 's/uunn\.local/'"$DOMAIN_NAME_URL"'/g' \
    loki.yml
```

```bash
docker stack deploy -c loki.yml loki
```

> Disponible en domain_name_url/metricas ej: uunn.local/metricas

### ARAI

```bash
cd ../arai

sed -i 's/uunn\.local/'"$DOMAIN_NAME_URL"'/g' \
    usuarios.api.env \
    usuarios.idp.env \
    usuarios.env \
    usuarios.yml \
    docs.yml \
    docs.env \
    huarpe_parameters.yml \
    huarpe.yml
```

#### Crear Secrets
```bash
cp secrets.sh.dist secrets.sh
./secrets.sh
```

### DEV REQS :hourglass:
```bash
cd ../../dev/servicios
docker stack deploy --with-registry-auth -c ldap.yml ldap
docker stack deploy --with-registry-auth -c postgres.yml db
```

##### Esperar a que todos esten `healthy` 
```bash
watch -n1 docker ps
```

#### (Opcional) Fake-SMTP
```bash
docker stack deploy --with-registry-auth -c smtp.yml smtp
```

```bash
cd ../../prod/arai
sed -i 's/^MAILER_HELO=.*/MAILER_HELO=mailcatcher/' usuarios.env
sed -i 's/^MAILER_HOST=.*/MAILER_HOST=mailcatcher/' usuarios.env
sed -i 's/^MAILER_PORT=.*/MAILER_PORT=1025/' usuarios.env
sed -i 's/^MAILER_SEGURIDAD=.*/MAILER_SEGURIDAD=none/' usuarios.env
sed -i 's/^MAILER_AUTH=.*/MAILER_AUTH=0/' usuarios.env
```

### USUARIOS
```bash
cd ../../prod/arai/

mkdir certs
openssl req -newkey rsa:2048 -new -x509 -days 3652 -nodes -out certs/certificado_idp.crt -keyout certs/certificado_idp.key -subj "/C=AR/ST=Misiones/L=Posadas/O=CIN/OU=SIU/CN=cin.siu/emailAddress=nomail@siu.edu.ar"
openssl genrsa -out certs/oidc_module.pem 2048
openssl rsa -in certs/oidc_module.pem -pubout -out certs/oidc_module.crt

docker config create usuarios_idp_saml_cert ./certs/certificado_idp.crt
docker secret create usuarios_idp_saml_key ./certs/certificado_idp.key
docker secret create usuarios_idp_oidc_key ./certs/oidc_module.pem
docker config create usuarios_idp_oidc_cert ./certs/oidc_module.crt
```

```bash
ADMIN_PASS=toba1234 docker stack deploy \
    --with-registry-auth \
    -c util/usuarios_crear_admin.yml \
    boot
```

#### Esperar a que finalice
```bash
docker service logs boot_idm -f
docker stack rm boot
```

#### (Opcional) Habilitar acceso externo a API Arai-Usuarios

```bash
cd ../../prod/arai
sed -i 's/# labels:/labels:/' usuarios.yml
sed -i 's/#   - "traefik\(.*\)/  - "traefik\1/' usuarios.yml

```

### Deploy Usuarios :hourglass:
```bash
docker stack deploy --with-registry-auth -c usuarios.yml usuarios
```
##### esperar a que los componentes de usuarios esten healthy
```bash
watch docker ps
```

#### (Opcional) Habilitar acceso externo a API backend Arai-Docs

```bash
sed -i 's/\/frontend//' docs.yml

```

### Deploy Documentos

#### (Opcional) Cambiar el backend de Storage a Filesystem. Requiere arai-docs 1.3.1 o superior 
```bash
sed -i 's/ARAI_DOCS_REPO_TIPO=RDI/ARAI_DOCS_REPO_TIPO=Filesystem\nARAI_DOCS_FILESYSTEM_DIR=\/tmp/' docs.env
```


```bash
docker stack deploy --with-registry-auth -c docs.yml docs
```
##### esperar a que el contenedor este `healthy`
```bash
watch "docker ps | grep docs"
```

### Deploy Huarpe

Ver documentacion para agregar huarpe como SP https://expedientes.siu.edu.ar/docs/arai/#registrar-huarpe-como-service-provider :pencil2: 

Luego deployar huarpe :hourglass:

```bash
docker stack deploy --with-registry-auth -c huarpe.yml huarpe
```

##### esperar a que el contenedor este `healthy`
```bash
watch "docker ps | grep huarpe"
```

- - -

### SUDOCU

```bash
cd ../../prod/sudocu/
```

#### Modificar dominio
```bash
sed -i 's/uunn\.local/'"$DOMAIN_NAME_URL"'/g' \
    config/config-api-server.json \
    config/config-sudocu-login.json \
    config/config-sudocu-mpd.json \
    config/config-sudocu-mpc.json \
    config/config-sudocu-gestion.json \
    sudocu.yml
```

```bash
cp sudocu-api-server-secret.json.dist sudocu-api-server-secret.json
docker secret create sudocu-api-server ./sudocu-api-server-secret.json
```

#### Deploy stack Sudocu
```bash
docker stack deploy --with-registry-auth --compose-file sudocu.yml sudocu
```

#### Registrar Sudocu como SP

https://expedientes.siu.edu.ar/docs/sudocu/#registrar-sudocu-como-service-provider-en-ara%C3%AD-usuarios

#### Crear Usuario Admin Sudocu

https://expedientes.siu.edu.ar/docs/sudocu/#crear-usuario-admin-de-sudocu-en-ara%C3%AD-usuarios


## Actualización

### 1.0 a 1.1

```bash
git stash save
git pull
git stash pop
```

#### Deploy Usuarios

```bash
cd prod/arai/util
docker stack deploy --with-registry-auth --compose-file usuarios_exportar_instalacion.yml usuarios_export
```
Esperar a que exporte y se detenga
```bash
docker service logs usuarios_export_idm -f
docker stack rm usuarios_export
```

```bash
docker stack deploy --with-registry-auth --compose-file usuarios_actualizar_base.yml usuarios_actualizar_base
```
Esperar a que migre y se detenga
```bash
docker service logs usuarios_actualizar_base_idm -f
docker stack rm usuarios_actualizar_base
```

Esperar a que elimine y se detenga
```bash
cd ../../../dev/servicios/
docker stack rm ldap
```

```bash
cat >/tmp/upgrade.ldif <<EOF
dn: cn={5}01-arai-usuarios,cn=schema,cn=config
changetype: modify
add: olcAttributetypes
olcAttributetypes: ( 2.25.23498964053317889486365664544994739483.117
  NAME 'requiereSecondFactor'
  EQUALITY booleanMatch
  SYNTAX 1.3.6.1.4.1.1466.115.121.1.7
  SINGLE-VALUE )
-
delete: olcObjectClasses
olcObjectClasses: ( 2.25.23498964053317889486365664544994739483.200
  NAME 'accountArai'
  SUP top
  AUXILIARY
  MUST ( aid $
  cuenta $
  defecto )
  MAY ( appUniqueId $
  appUnlink ) )
-
add: olcObjectClasses
olcObjectClasses: ( 2.25.23498964053317889486365664544994739483.200
  NAME 'accountArai'
  SUP top
  AUXILIARY
  MUST ( aid $
  cuenta $
  defecto )
  MAY ( appUniqueId $
  appUnlink $
  requiereSecondFactor ) )
-
delete: olcObjectClasses
olcObjectClasses: ( 2.25.23498964053317889486365664544994739483.100
  NAME 'inetOrgPersonArai'
  SUP Top AUXILIARY
  MUST ( uid $ bloqueado )
  MAY ( login $ loginMethod $ idPersona $ mailPassRecovery $
  mailVerified $ mailPassRecoveryVerified $ mobileVerified $
  uniqueIdentifier $ atributos $ cuentas $ gender $ birthDate $
  zoneInfo ) )
-
add: olcObjectClasses
olcObjectClasses: ( 2.25.23498964053317889486365664544994739483.100
  NAME 'inetOrgPersonArai'
  SUP Top AUXILIARY
  MUST ( uid $ bloqueado )
  MAY ( login $ loginMethod $ idPersona $ mailPassRecovery $
  mailVerified $ mailPassRecoveryVerified $ mobileVerified $
  requiereSecondFactor $ uniqueIdentifier $ atributos $ cuentas $
  gender $ birthDate $ zoneInfo ) )
-
EOF
```

```bash
docker run --name upgrade-ldap --rm -d \
   --volume ldap_volumen_ldap_data:/var/lib/ldap \
   --volume ldap_volumen_ldap_config:/etc/ldap/slapd.d \
   --volume /tmp/upgrade.ldif:/tmp/upgrade.ldif \
   siutoba/docker-openldap-arai:openldap-4 --copy-service
```

```bash
docker exec -it upgrade-ldap ldapmodify -c -Y EXTERNAL -Q -H ldapi:/// -f /tmp/upgrade.ldif
docker rm -f upgrade-ldap
```

```bash
docker stack deploy -c ldap.yml ldap
```

```bash
cd ../../prod/arai/
docker stack deploy --with-registry-auth --compose-file usuarios.yml usuarios
```

#### Deploy Documentos

```bash
cd util
docker stack rm docs
```

```bash
docker stack deploy --with-registry-auth --compose-file docs_actualizar_base.yml docs_actualizar_base
```

Esperar a que migre y se detenga

```bash
docker service logs docs_actualizar_base_update -f
docker stack rm docs_actualizar_base
```

```bash
docker secret rm docs_conexion_sudocu
DOCS_CONEXION_SUDOCU=$(cat << EOF
"{base_uri:'http://api-server:8080/',method:'basic',user:'integracion',password:'integracion'}"
EOF
)
printf $DOCS_CONEXION_SUDOCU | docker secret create docs_conexion_sudocu -
```

```bash
cd ..
docker stack deploy --with-registry-auth -c docs.yml docs
```

#### Deploy Huarpe





#### Deploy SQ Núcleo

Pasos para realizar una instalación de SQ Núcleo sin docker

Descargar de fuentes

```bash
cd /usr/local/proyectos/sanaviron_quilmes/

git clone -b master https://hub.siu.edu.ar/sanaviron-quilmes/nucleo.git

cd nucleo
```

Descargar las dependencias mediante Composer

```bash
 composer install
```

Configuración de la instalación

```bash
  ./bin/instalador proyecto:definir-variables
```

Es importante configurar los siguientes parámetros del archivo `instalador.env`

```dotenv
   PROYECTO_STANDALONE="true"    
```

Requiere una conexión a un Pilagá

```dotenv
    ##### CONFIG SIU-PILAGA #####
    PROYECTO_PILAGA_API_URL="http://127.0.0.1/pilaga/rest/"
    PROYECTO_PILAGA_API_USUARIO="toba"
    PROYECTO_PILAGA_API_PASSWORD="toba"
    PROYECTO_PILAGA_API_METHOD="basic"
```

Instalar el sistema

```bash
   ./bin/instalador proyecto:instalar --crear-db
```

Corregir los permisos

```bash
    sudo ./bin/instalador permisos:simple
```

Sacar al sistema de modo mantenimiento

```bash
    ./bin/instalador instalacion:modo-mantenimiento --sin-mantenimiento
```

Configurar el servidor web Apache

```bash
    sudo ln -s ./config/toba.conf /etc/apache2/sites-enabled/sq_nucleo.conf
    
    sudo a2enmod rewrite
    sudo service apache2 restart
```

Iniciar el servidor Jasper

```bash
    java -jar ./vendor/siu-toba/jasper/JavaBridge/WEB-INF/lib/JavaBridge.jar SERVLET:8081
```

Registrar SIU SQ-Núcleo como Service Provider en Araí Usuarios

Ver documentación para agregar SQ-Núcleo como SP https://expedientes.siu.edu.ar/docs/sq-nucleo/#registrar-siu-sq-nucleo-como-service-provider-en-araí-usuarios


#### Deploy Sudocu

Sudocu normalmente actualiza su bd en el pasaje de versiones por lo que es requerido que dicho paso sea llevado adelante antes de levantar el stack nuevo.
Primeramente bajamos el stack de Sudocu

```bash
docker stack rm sudocu
```
Luego actualizamos la bd de Sudocu utilizando el migrador provisto para la version correspondiente

```bash
cd /dev/servicios
docker stack deploy --with-registry-auth --compose-file util/sudocu_actualizar_base.yml sudocu_actualizar_base
```
Esperar a que migre y se detenga
```bash
docker service logs sudocu_actualizar_base -f
docker stack rm sudocu_actualizar_base
```

Luego de realizado este paso, debemos actualizar el contenedor correspondiente a la bd de Sudocu para que levante con la nueva version.

```bash
docker service update db_db-sudocu

```
Finalmente levantamos nuevamente el stack de Sudocu

```bash
cd /prod/sudocu
docker stack deploy --with-registry-auth --compose-file sudocu.yml sudocu
```


