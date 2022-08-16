---
id: version-1.4.0-firma-digital-remota
title: Servicio de firma en la nube FirmAR
sidebar_label: Firmador en la nube
original_id: firma-digital-remota
---

EEI permite la integración con FirmAR, que es una plataforma de [Firma Digital Remota](https://firmar.gob.ar/), de 
manera tal que el usuario no debe manipular el documento (subirlo para firmar o descargarlo firmado). 

Desde Huarpe se accede al proceso de firma en la nube y una vez firmado, el documento queda disponible en el 
repositorio digital.

La implementación de este este tipo de firma consta de tres partes:
- Cada usuario debe tramitar su certificado de la AC-MODERNIZACIÓN (sin token) en la entidad de registro pertinente https://firmar.gob.ar/RA/info
- Parametrización técnica para la comunicación entre Araí Documentos y https://firmar.gob.ar https://documentacion.siu.edu.ar/documentos/docs/firma-digital-firmar/
- Parametrización funcional en Araí Usuarios, donde a cada usuario que haya gestionado su certificado de AC-MODERNIZACIÓN, se le debe configurar el número de CUIT dentro de la solapa Atributos Extra, atributo CUIT.
