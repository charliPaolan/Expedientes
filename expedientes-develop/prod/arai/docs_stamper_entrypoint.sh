#!/usr/bin/env sh

# Se instala tzdata para configurar la zona horaria. Se realiza desde variables de entorno
apk add --no-cache tzdata

java -Xms512m -Xdebug -cp /app/resources:/app/classes:/app/libs/* ar.com.nomi.necro.estampatodo.Application
