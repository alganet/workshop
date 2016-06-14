#!/usr/bin/env sh

# workshop, the module loader
#
# Loads modules and their dependencies, downloading them from a server
# if none is found locally.
#
workshop ()
{
	# Workshop needs at least two arguments to work
	if test -z "${2:-}"
	then
		return 0
	fi

	# Be strict unless someone asked explicitly for unsafety
	if 	test -z "${workshop_unsafe:-}"
	then
		# Fail on errors and undefined vars. Don't expand glob patterns
		set -euf
	fi

	# Don't expand glob patterns on zsh
	unsetopt NO_MATCH  >/dev/null 2>&1 || :

	# Split words by whitespace when expanding variables on zsh
	setopt SHWORDSPLIT >/dev/null 2>&1 || :

	# Path to the executable that started workshop
	_executable="${workshop_executable:-${1}}"

	# Directory in which the workshop executable resides
	_executable_dir="$(dirname "${_executable}")"

	# Input module name or file path. Trim dashes from beginning.
	_input="${2##*-}"

	# Name of the module
	_main="$(basename "${_input}")"

	# Remove trailing file extension from main module
	_main="${_main%%.*}"

	# Module server hostname
	_hostname='raw.githubusercontent.com'

	# Default server to look for dependencies
	_master="https://${_hostname}/alganet/workshop/master/lib/"

	# Use default server if non has been provided
	_server="${workshop_server:-${_master}}"

	# Make executable dir absolute
	_executable_dir="$(cd "${_executable_dir}" || exit;pwd)"

	# Absolute path to the executable that started workshop
	workshop_executable="${_executable_dir}/$(basename "${_executable}")"

	# Directory to save downloaded libraries
	workshop_lib="${workshop_lib:-${_executable_dir}}"

	# Path to look for other modules
	workshop_path="${workshop_path:-$(pwd):${workshop_lib}}"

	shift 2 # Remove first two arguments, remaining are module arguments

	if test -f "${_executable}"
	then
		# List of modules already loaded
		_modules="${workshop_modules:-} : workshop "

		# List of modules to be loaded, include main module by default
		_dependencies="${workshop_modules:-} ${_main}"
	else
		# List of modules already loaded
		_modules="${workshop_modules:-} : "

		# List of modules to be loaded, include workshop and main
		_dependencies="${workshop_modules:-} ${_main} workshop"
		_run_once=1
	fi

	# Don't stop until all dependencies are met
	while true 'Dependency Loop'
	do
		# Check each dependency
		for _dependency in ${_dependencies}
		do
			_dependency_status='ok'

			# Check if all dependencies were already loaded first
			for _dependency_check in ${_dependencies}
			do
				if test "${_modules#*$_dependency_check}" != "$_modules"
				then
					if test "${_dependency_status}" = 'ok'
					then
						continue
					fi
				else
						_dependency_status="${_dependency_check} missed"
				fi
			done

			# All dependencies loaded, get out
			if test "${_dependency_status}" = 'ok'
			then
				break 2 # Exit 'Dependency Loop'
			fi

			# Current dependency is already loaded, continue to next one
			if test "${_modules#*$_dependency}" != "$_modules"
			then
				continue
			fi

			# Looks for modules in the ${workshop_path}
			_found_module=''
			_ifs="${IFS}"
			IFS="${workshop_path_separator:-:}"
			for _part in ${workshop_path}
			do
				_file="${_part}/${_dependency}.sh"

				if test -f "${_file}"
				then
					_found_module="${_file}"
					break # Module found, exit loop
				fi
			done
			IFS="${_ifs}"
			unset _ifs

			# If no module has been found, try to donwload it
			if test -z "${_found_module:-}" && test ! -z "${_server:-}"
			then
				if test -z "${_temp_dir:-}"
				then
				    _temp_dir="$(
				    	mktemp -d \
				    	"${TMPDIR:-/tmp}/workshop.XXXXXX" 2>/dev/null
			    	)"
				    if test -z "${_temp_dir:-}"
					then
						_temp_dir="${TMPDIR:-/tmp}/workshop."$(
							od -An -N2 -i /dev/random
						)
					    mkdir -m 700 "${_temp_dir}"
					fi
				fi
				_remote_url="${_server}${_dependency}.sh"
				_found_module="${workshop_lib}/${_dependency}.sh"
				_temp_module="${_temp_dir}/${_dependency}.sh"

				# Tests if current shell can check if commands exist
				if command -v workshop >/dev/null 2>&1
				then
					# Check for popular HTTP download tools
					if command -v curl >/dev/null 2>&1
					then
						curl --fail -L "${_remote_url}" \
							2>/dev/null > "${_temp_module}" ||
								_code=$?
					elif command -v wget >/dev/null 2>&1
					then
						wget -qO- "${_remote_url}" \
							2>/dev/null  > "${_temp_module}" ||
								_code=$?
					else
						# Module cannot be found
						return 127
					fi

					# Tests if downloaded file is a workshop module
					_head=
					test ! -f "${_temp_module}" ||
						_head="$(head -n1 "${_temp_module}")"

					if ( test "${_head}" = "#!/usr/bin/env workshop" ||
							test ${_dependency} = "workshop" ) &&
						"${SHELL}" -n "${_temp_module}" >/dev/null 2>&1
					then
						# Workshop is running with an executable file
						if test -z "${_run_once:-}"
						then
							cp "${_temp_module}" "${_found_module}"
						else
							# Use temporary module as path
							_found_module="${_temp_module}"
						fi
					elif test -f "${_temp_module}"
					then
						# If not a valid module, delete it
						rm "${_temp_module}"
						return 127
					fi
				else
					return 127
				fi
			fi

			_required=''

			# Makes sure no one overrided the require function
			require ()
			{
				_required="${_required:-} ${*:-} "
			}

			# Dry-runs the module to check for errors
			${SHELL} -n "${_found_module}" >/dev/null 2>&1

			# If workshop itself is a dependency and an executable
			# is not available, download it.
			if test "${_dependency}" != "workshop"
			then
				# Loads the module, calling its 'require' commands
				. "${_found_module}"
			elif test ! -z "${_run_once:-}"
			then
				# Redefine some variables after getting a disk instance
				# of workshop
				_executable="${_found_module}"
				_executable_dir="$(dirname "${_executable}")"
				_executable_dir="$(cd "${_executable_dir}" || exit;pwd)"
				workshop_executable="${_executable_dir}/$(
					basename "${_executable}"
				)"
			fi

			# Add up newly found dependencies to list
			_dependencies="${_required:-} ${_dependencies:-}"
			# Add loaded module to list of dependencies met
			_modules="${_modules} ${_dependency} "
		done
	done

	# If not in run once mode, remove temporary files.
	if test ! -z "${_temp_dir:-}" && test -z "${_run_once:-}"
	then
		rm -Rf "${_temp_dir}"
	fi

	# Call module with arguments, if there is at least one
	if test -z "${*:-}"
	then
		"${_main}"
	else
		"${_main}" "${@}"
	fi
}

workshop "${0}" "${@:-}"
