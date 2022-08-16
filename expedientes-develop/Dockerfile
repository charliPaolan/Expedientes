FROM node:alpine as deps
RUN apk add autoconf automake build-base zip git
WORKDIR /app/website
COPY docs/website/package.json /app/website/package.json
RUN npm install

FROM deps as build
WORKDIR /prepare
COPY docs/docs /prepare/docs
COPY docs/website /prepare/website
# se copia del stage anterior q ya tiene la node_modules
RUN mv /app/website/node_modules /prepare/website/node_modules
RUN cd /prepare/website && yarn run build

FROM httpd:alpine
COPY --from=build /prepare/website/build/espedienteElectronico /usr/local/apache2/htdocs/
