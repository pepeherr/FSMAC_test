## Modificaciones realizadas para la renominación
### Objetivo
La denominación "Asamblea" y "Proceso" son las nativas de Decidim pero para njuestro proyecto necesitabamos adaptarlas respectivamente a "Círculo" y "Conflicto", para ello, con el servidor detenido

1. Ejecutamos desde la raiz del proyecto
```
rails runner x_scripts/generar_traducciones_es.rb

```
nos generará el archivo traducciones_es.yml en la raiz del proyecto
2. Revisamos y cambiamos lo que creamos conveniente el archivo generado y lo copiamos:
```
cp traducciones_completas.yml config/locales/overrides.yml
```
3. iniciamos el servidor y comprobamos la traducción de los términos a "Círculo" y "Conflicto"
4. Realizamos los pasos 1 al 3 para los diferentes idiomas: catalán, euskera, gallego e ingles.

