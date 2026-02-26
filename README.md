# fsmac_test

Free Open-Source participatory democracy, citizen participation and open government for cities and organizations

This is the open-source repository for fsmac_test, based on [Decidim](https://github.com/decidim/decidim).

## Setting up the application

You will need to do some steps before having the app working properly once you have deployed it:

1. Create a System Admin user: `bin/rails decidim_system:create_admin`
1. Visit `<your app url>/system` and log in with your system admin credentials
1. Create a new organization. Check the locales you want to use for that organization, and select a default locale.
1. Set the correct default host for the organization, otherwise the app will not work properly. Note that you need to include any subdomain you might be using.
1. Fill the rest of the form and submit it.

You are good to go!
===
## Comentarios a la instalación para desarrollo

Inicialmente he seguido el proceso descrito en el Manual de Instalación Oficial de Decidim [Manual de Instalación Oficial de Decidim](https://docs.decidim.org/en/develop/install/manual.html), sin embargo he añadido pasos fundamentales que no se detallan en el manual y son fundamentales para llevar a cabo con exito el proceso:

Lo he instalado en un sistema con Ubuntu 24.04.3 LTS y con las siguientes especificaciones:

|Decidim version|Ruby version|Node version|
|:-------------:|:----------:|:----------:|
|v0.31          |3.3.4       |22.22       |

El proceso ha sido el siguiente:

## Instalación de rbenv:

	sudo apt update
	sudo apt install -y build-essential curl git libssl-dev zlib1g-dev libffi-dev libyaml-dev
	git clone https://github.com/rbenv/rbenv.git ~/.rbenv
	echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
	echo 'eval "$(rbenv init -)"' >> ~/.bashrc
	source ~/.bashrc
	git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
	rbenv install 3.3.4
	rbenv global 3.3.4

## Instalación de Postgresql

	sudo apt install -y postgresql libpq-dev
	sudo -u postgres psql -c "CREATE USER decidim_app WITH SUPERUSER CREATEDB NOCREATEROLE PASSWORD 'thepassword'"

## Instalación de Node.js

	curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
	source "$HOME/.nvm/nvm.sh"
	nvm install 22
	npm install -g yarn

## Instalación de Decidim

	sudo apt install -y libicu-dev imagemagick libvips libvips-tools
	gem install decidim
	decidim FSMAC_test

	FSMAC_test o cualquier otro nombre que será la carpeta en la que se cree la aplicación en este caso ~/FSMAC_test

## Configuración de la base de datos

Creamos el archivo .rbenv-vars fuera de ~/FSMAC_test, yo lo cree en ~/

git clone https://github.com/rbenv/rbenv-vars.git "$(rbenv root)"/plugins/rbenv-vars

con ello se crean los plugins dentro de ~/.rbenv

ahora __fundamental__:

	exec $SHELL

	nano ~/.rbenv-vars 

	incluimos el siguiente contenido:

	DATABASE_HOST=localhost
	DATABASE_USERNAME=decidim_app
	DATABASE_PASSWORD=thepassword

## Creación del repositorio git

	cd ~/FSMAC_test
	git add .
	git commit -m "Initial commit. Generated with Decidim https://decidim.org"

## Creación de la base de datos, primera migración y creación de seeds

	cd ~/FSMAC_test
	bin/rails db:create db:migrate
	bin/rails assets:precompile
	bin/rails db:seed

con ello tambien se ha creado una aplicación de ejemplo que va a correr por defecto en localhost, 0.0.0.0 y 127.0.0.1

## Lanzar el servidor
Dentro de la carpeta de la aplicación, mejor lo hacemos en un terminal aparte:

	cd ~/FSMAC
	bin/dev

en el navegador podemos ya entrar en la aplicación de ejemplo de decidim mediante http://localhost:3000

Según al área que deseemos usaremos: 
|Tipo|Email|Contraseña|URL|Descripción|
|:---|:----|:---------|:--|:----------|
|Decidim::System::Admin|system@example.org|decidim123456789|/sistema|Administrador para el multitenant|
|Decidim::Usuario|admin@example.org|decidim123456789|/admin|Administrador de la organización|
|Decidim::Usuario|user@example.org|decidim123456789|/usuario/sign_in|Usuario para la organización|

## Creación y configuración de organización y usuarios administradores
Necesitamos crear:

1. Un nuevo system admin para nuestra nueva aplicación. Para ello:

	cd ~/FSMAC_test
	bin/rails decidim_system:create_admin
 
nos pedirá un email y un password y creará el nuevo system admin, un usuario del system, no es un admin de la organización.

2. Una nueva organización:

	cd ~/FSMAC_test
	abrimos una consola de rails:
	bin/rails console

dentro creamos la organización:

	org = Decidim::Organization.create!(
	name: { "es" => "Foro Social Más Allá del Crecimiento" },
	host: "127.0.0.2",
	reference_prefix: "FSM",
	available_locales: ["es",”ca”,”eu”,”gl”,”en”],
	default_locale: "es",
	tos_version: Time.current
	)

comprobamos que se ha creado correctamente en la consola rails:

	cd ~/FSMAC_test
	rails c

	Decidim::Organization.all.pluck(:id, :host, :name)

La creación de una nueva organización también puede realizarse entrando en http://127.0.0.2:3000/system, esta es la url de sistema de nuestra organización.

3. continuamos en la consola y creamos el usuario admin de la organización recien creada:

admin = Decidim::User.new(
	email: "admin@localhost.test",
	password: "Password123!",
	password_confirmation: "Password123!",
	name: "Admin",
	nickname: "admin",
	confirmed_at: Time.current,
	organization: org,
	accepted_tos_version: org.tos_version,
	admin: true
)

	admin.save(validate: false)

	podemos verificar que el usuario admin se ha creado:

	org.users.pluck(:id, :name, :email, :admin, :accepted_tos_version)

	ya hemos creado el admin de nuestra organización y podemos salir de la consola:

	exit

Con los datos del admin de nuestra organización podemos entrar en http://127.0.0.2:3000/admin de nuestra organización y configurar nuestro Decidim

4. Creamos un usuario de prueba mediante la interfaz de Decidim pulsando en créate una cuenta.

Si aún no tenemos configurado el servidor SMTP no se enviarán los mensajes de email, pero el sistema los guarda y podemos acceder a ellos en http://127.0.0.2:8000/letter_opener
NOTA: Por defecto esta es la forma en la que se envian correos en modo desarrollo.
Podemos verlo en la consola:

 bin/rails console
	
	Rails.application.config.action_mailer.delivery_method
	=> :letter_opener_web