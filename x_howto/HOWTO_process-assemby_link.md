# Relaciones entre procesos y asambleas
## Fundamento
Los procesos pueden relacionarse con asambleas en la UI de Admin.
En el formulario para la definición de la asamblea se pueden marcar los procesos relacionados
Esta relación se establece con el sistema ParticipatorySpaceLink
Esta tabla contiene los siguientes campos:

	Decidim::ParticipatorySpaceLink
	=> Decidim::ParticipatorySpaceLink(id: integer, from_type: string, from_id: integer, to_type: string, to_id: integer, name: string, data: jsonb)

Las asambleas usan el helper __linked_participatory_space_resources__

## Listado de procesos relacionados con una asamblea

	assembly = Decidim::Assembly.find(4)

	assembly.linked_participatory_space_resources(
	:participatory_processes,
	"included_participatory_processes"
	)

Listado de todos los procesos relacionados con una asamblea:

	Decidim::ParticipatorySpaceLink.where(from: assembly)

o también:




Listado de los id's de los procesos relacionados con una asamblea:

Usando el helper:

	assembly
	.linked_participatory_space_resources(:participatory_processes, "included_participatory_processes")
	.pluck(:id)

	=> [4, 5, 7]

Explorando la tabla ParticipatorySpaceLink:

	Decidim::ParticipatorySpaceLink.where(from: 4).map(&:to_id)
	Decidim::ParticipatorySpaceLink Load (1.5ms)  SELECT "decidim_participatory_space_links".* FROM "decidim_participatory_space_links" WHERE "decidim_participatory_space_links"."from_id" = $1  [["from_id", 4]]
	=> [4, 5, 7]

## Relacionar y desrelacionar un proceso con una asamblea

Estableciendo la relación:

	assembly = Decidim::Assembly.find(4)
	process  = Decidim::ParticipatoryProcess.find(8)

	Decidim::ParticipatorySpaceLink.create!(
	from: assembly,
	to: process,
	name: "included_participatory_processes"
	)

OJO. Para que aparezca la relación en la UI es necesario publicarla. Es decir, es necesario hacer:

	process.update_column(published_at: Time.current)

Para despublicar: process.update_column(published_at: nil)

Eliminar la relación:

	assembly = Decidim::Assembly.find(4)
	process  = Decidim::ParticipatoryProcess.find(8)

	Decidim::ParticipatorySpaceLink.where(
	from: assembly,
	to: process,
	name: "included_participatory_processes"
	).destroy_all

