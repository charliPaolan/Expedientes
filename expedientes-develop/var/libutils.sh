### This should only be sourced, not executed directly ###

trap "echo Argh! ; exit 1" ERR
#set -o errtrace

function    fatal()
{
    echo "$@" >&2
    exit 1
}

function    errtrap
{
    fatal "${ERRTEXT:-Argh!}"
}

trap errtrap ERR
test -n "$BASH_VERSION"                                     ||
    fatal "This file must be source(d) from bash."
test "$( caller 2>/dev/null | awk '{print $1}' )" != "0"    ||
    fatal "This file must be source(d), not executed."
# test -x jq    ||
#     fatal "No está instalado el comando JQ"
test "$(id -u)" != "0"    ||
    fatal "No está permitido ejecutar como ROOT y/o SUDO"

# Lee la variable $DOMINIO y exporta
#  DOMINIO > dominio completo sin schema
#  SCHEME  > el scheme de la url
#  DOMINIO_HTTPS > 'si' si scheme es https 'no' de lo contrario
# function load_domain_vars
# {
# }

