#!/usr/bin/env workshop

require 'dispatch'

install ()
{
	dispatch 'install' "${@:-local}"
}

install_command_local ()
{
	install_command_prefix '/usr/local'
}

install_option_h () ( install_command_help "${@:-}" )
install_option_help () ( install_command_help "${@:-}" )
install_command_help ()
{
	cat <<-INSTALL_HELP
	Usage: workshop install COMMAND
	Installs workshop into the system, carrying over portable modules
	already loaded.

	Commands: prefix [PREFIX]  Install on target PREFIX
	          local            Install with PREFIX=/usr/local

	Two file paths will be created:
	  - PREFIX/workshop # The workshop executable
	  - PREFIX/workshop # Folder with workshop libraries

	INSTALL_HELP
}

install_command_prefix ()
{
	workshop_prefix="${1:-/usr/local}"

	flash "Installing workshop on '${workshop_prefix}'."

	# Remove old version if exists
	rm -Rf "${workshop_prefix}/lib/workshop"
	rm -Rf "${workshop_prefix}/bin/workshop"

	# Create new folders
	mkdir -p "${workshop_prefix}/bin"
	mkdir -p "${workshop_prefix}/lib/workshop"

	# Copy contents of current running instance to install folder
	cp -Ra "${workshop_lib}/." "${workshop_prefix}/lib/workshop"

	# Create a new executable pointing to installed workshop
	cat <<-EXECUTABLE > "${workshop_prefix}/bin/workshop"
	#!/usr/bin/env sh

	. "${workshop_prefix}/lib/workshop/workshop.sh"
	EXECUTABLE

	flash "workshop installed on '${workshop_prefix}'."
}
