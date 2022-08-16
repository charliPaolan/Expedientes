#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

which jq >/dev/null 2>&1  ||
    fatal "No está instalado el comando JQ"

echo "Carga secretos por defecto. Si esto es producción, ALEJESE. Desea continuar?"
select yn in "Si" "No"; do
    case $yn in
        Si ) break;;
        No ) exit;;
    esac
done

################################################################################
# Usuarios
################################################################################
printf "postgres123" | docker secret create usuarios_db_pass -
printf "admin123" | docker secret create usuarios_ldap_admin_pass -
printf "admin123" | docker secret create usuarios_ldap_config_pass - 
printf $(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 20 | head -n 1) | docker secret create usuarios_pass_salt -
printf "admin123" | docker secret create usuarios_idp_simplesaml_admin -
docker secret create usuarios_idp_saml_key $DIR/certs_prueba/certificado_idp.key
docker secret create usuarios_idp_oidc_key $DIR/certs_prueba/oidc_module.pem
docker config create usuarios_idp_saml_cert $DIR/certs_prueba/certificado_idp.crt
docker config create usuarios_idp_oidc_cert $DIR/certs_prueba/oidc_module.crt

DOCS_USUARIOS_PASS=documentos123
HUARPE_USUARIOS_PASS=huarpe123

USUARIOS_API_USERS=$(cat << EOF
[
    ["documentos", "$DOCS_USUARIOS_PASS"],
    ["huarpe", "$HUARPE_USUARIOS_PASS"]
]
EOF
)
printf $(echo $USUARIOS_API_USERS | jq -c) | docker secret create usuarios_api_users -

docker volume create usuarios_assets_vol

################################################################################
# Documentos
################################################################################
DOCS_PASS=docs123
printf $DOCS_PASS | docker secret create docs_api_pass -
printf "postgres123" | docker secret create docs_db_pass -
printf "Administrator" | docker secret create docs_repo_pass -

DOCS_CONEXION_USUARIOS=$(cat << EOF
"{base_uri:'usuarios-api/api/v1/usuarios',method:'basic',user:'documentos',password:'$DOCS_USUARIOS_PASS'}"
EOF
)
printf $DOCS_CONEXION_USUARIOS | docker secret create docs_conexion_usuarios -

DOCS_CONEXION_SUDOCU=$(cat << EOF
"{base_uri:'http://api-server:8080/integracion/',method:'basic',user:'integracion',password:'integracion'}"
EOF
)
printf $DOCS_CONEXION_SUDOCU | docker secret create docs_conexion_sudocu -

################################################################################
# Huarpe
################################################################################

printf $(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 31 | head -n 1) | docker secret create huarpe_secret -

# HUARPE_CONEXION_USUARIOS=$(cat << EOF
# "{auth:[huarpe,$HUARPE_USUARIOS_PASS,basic],base_uri:'usuarios-api/api/v1/'}"
# EOF
# )
printf $HUARPE_USUARIOS_PASS | docker secret create huarpe_conexion_usuarios -

# HUARPE_CONEXION_DOCS=$(cat << EOF
# "{auth:[huarpe,$DOCS_PASS,basic],base_uri:'docs-api/documentos/rest/backend/'}"
# EOF
# )
printf $DOCS_PASS | docker secret create huarpe_conexion_docs -
