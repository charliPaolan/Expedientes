## 1. Completar identificacion de Institucion
- Nombre completo:  
- ID unico (sigla):

## 2. Identificar proyecto SIU al que se va a dar acceso (solo una opcion)
- [ ] Expedientes  
- [ ] Arai Usuarios
- [ ] Arai Documentos

## 3. Identificacion de Accesos a otorgar
### 3.1 Completar un item por cada acceso 
- Nombre completo:
- Usuario Comunidad SIU:
- email:
- rol
- DNI:

## 4. Tareas
### 4.1 Para cada Acceso 
- [ ] verificar si ya existe el **user** en [hub.siu.edu.ar](url). Si no existe, crearlo

### 4.2 Crear group para el proyecto SIU
- [ ] crear **group** para Institucion 
- [ ] asignar **user** ROOT como OWNER del **group** de la Institucion 
- [ ] asignar **user** que es referente del proyecto como MAINTAINER del **group** de la Institucion 
- [ ] asignar resto de **users** como DEVELOPER del **group** de la Institucion
- [ ] eliminar **user** que creo el **group** 

### 4.3 Grantear acceso a proyectos al group creado
- [ ] grantear group **siu**
- [ ] grantear group **siu-arai**

**Nota**: para usar php share_grupo_proyectos.php es necesario tener habilitado la ejecucion de la REST API de [hub.siu.edu.ar](url)






 
