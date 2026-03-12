## Tabla de usuarios
### Configuración de la tabla:

Usamos el script x_script/table_conf_to_csv.rb y obtenemos x_temp/tabla_usuarios.csv

### Registros de la tabla:

Podemos ver los registros de la tabla usuarios en la consola con:

```
Decidim::User.where(decidim_organization_id:2).pluck(:id, :name, :email, :decidim_organization_id,:locale, :admin, :managed, :roles)

```
## Roles y superadmin
No pueden confundirse los roles con el admin global de la plataforma (nivel organización), que tiene acceso a TODO. Los roles sólo tienen ambito en un espacio participativo concreto (Círculo -Assembly- o Conflicto -Process-)
## Sobre los roles
Los roles tanto para Circulos como para Conflictos son los siguientes:

Acción	                           Admin	Colaboradora	Moderadora	Evaluadora
Configurar el espacio	            ✅	       ❌	         ❌	        ❌
Crear componentes	                ✅	       ❌	         ❌	        ❌
Editar contenidos generales	        ✅	       ✅ (limitado)	 ❌	        ❌
Ver contenido no publicado	        ✅	       ✅	         ❌	        ❌
Moderar/ocultar contenido	        ✅	       ❌	         ✅	        ❌
Gestionar denuncias	                ✅	       ❌	         ✅	        ❌
Evaluar propuestas (notas privadas)	✅	       ❌	         ❌	        ✅
Exportar datos	                    ✅	       ❌	         ❌	        ❌
Invitar nuevos usuarios	            ✅	       ❌	         ❌	        ❌

En Decidim, cada espacio participativo (Asamblea, Proceso) tiene su propia configuración de roles y permisos, los roles del Circulo no se heredan a los Procesos.

Los roles de los usuarios en los espacios participativos se guardan en:
```
Decidim::AssemblyUserRole
=> Decidim::AssemblyUserRole(id: integer, decidim_user_id: integer, decidim_assembly_id: integer, role: string, created_at: datetime, updated_at: datetime)

Decidim::ParticipatoryProcessUserRole
=> Decidim::ParticipatoryProcessUserRole(id: integer, decidim_user_id: integer, decidim_participatory_process_id: integer, role: string, created_at: datetime, updated_at: datetime)
```

Ver roles de un usuario: en asambleas (Circulos) y en procesos participativos (Conflictos)

```
Decidim::AssemblyUserRole.where(decidim_user_id: 124).pluck(:decidim_assembly_id, :role)

Decidim::ParticipatoryProcessUserRole.where(decidim_user_id: 7).pluck(:id, :decidim_participatory_process_id, :role)

```



