#!/usr/bin/env sh

# workshop, the loader
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

	# Input module name or file path. Trim dashes from beginning.
	_input="${2##*-}"

	_remote="$(dirname ${_input})"

	# Module server hostname
	_hostname='raw.githubusercontent.com'

	if test 'https' = "${_remote%%:*}"
	then
		# Default server to look for dependencies
		_master="${_remote}/"
	else
		# Default server to look for dependencies
		_master="https://${_hostname}/alganet/workshop/master/lib/"
	fi

	# Name of the module
	_main="$(basename "${_input}")"

	# Remove trailing file extension from main module
	_main="${_main%%.*}"

	# Use default server if non has been provided
	workshop_server="${workshop_server:-${_master}}"

	# Path to the executable that started workshop
	_executable="${workshop_executable:-${1}}"

	# Directory in which the workshop executable resides
	_lib="$(dirname "${_executable}")"

	# Make executable dir absolute
	workshop_lib="$(cd "${workshop_lib:-${_lib}}" || exit;pwd)"

	# Absolute path to the executable that started workshop
	workshop_executable="${workshop_lib}/$(
		basename "${_executable}"
	)"

	# Path to look for other modules
	workshop_path="${workshop_path:-$(pwd):${workshop_lib}}"

	shift 2 # Remove first two arguments, remaining are module arguments

	resolve "${_main}"

	# Call module with arguments, if there is at least one
	if test -z "${*:-}"
	then
		"${_main}"
	else
		"${_main}" "${@}"
	fi
}

resolve ()
{
	_main="${1}"

	if test -f "${workshop_executable}"
	then
		# List of modules already loaded
		_modules="${workshop_modules:-} : workshop resolve tempdir "

		# List of modules to be loaded, include main module by default
		_dependencies="${workshop_modules:-} ${_main}"
	else
		# List of modules already loaded
		_modules="${workshop_modules:-} : resolve tempdir "

		# List of modules to be loaded, include workshop and main
		_dependencies="${workshop_modules:-} ${_main} workshop"

		# Workshop is running from sh, detached from an executable file
		workshop_detached=1
	fi

	# Don't stop until all dependencies are met
	while true ; do for _dependency in ${_dependencies}
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
			break 2 # Exit
		fi

		# Current dependency is already loaded, continue to next one
		if test "${_modules#* $_dependency}" != "${_modules}"
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
		if test -z "${_found_module:-}" &&
			test ! -z "${workshop_server:-}"
		then
			if test -z "${_temp_dir:-}"
			then
				_temp_dir="$(tempdir workshop)"
			fi
			_remote_url="${workshop_server}${_dependency}.sh"
			_found_module="${workshop_lib}/${_dependency}.sh"
			_temp_module="${_temp_dir}/${_dependency}.sh"

			flash "Downloading '${_dependency}' from '${_remote_url}'."
			httpgetfile "${_remote_url}" "${_temp_module}" &&
				_downloaded=$? ||
				_downloaded=$?
			if test "${_downloaded}" = '127'
			then
				# Module cannot be retrieved
				flash "No download tool available" \
				       "to retrieve '${_dependency}'."
				return 127
			elif test "${_downloaded}" = '1'
			then
				# Module cannot be found
				flash "Failed to download '${_dependency}'" \
				       "from '${_remote_url}'."
				return 1
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
				if test -z "${workshop_detached:-}"
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
		elif test ! -z "${workshop_detached:-}"
		then
			# Redefine some variables after getting a disk instance
			# of workshop
			workshop_executable="${_found_module}"
			workshop_lib="$(dirname "${workshop_executable}")"
			workshop_lib="$(cd "${workshop_lib}" || exit;pwd)"
			workshop_executable="${workshop_lib}/$(
				basename "${workshop_executable}"
			)"
		fi

		# Add up newly found dependencies to list
		_dependencies="${_required:-} ${_dependencies:-}"
		# Add loaded module to list of dependencies met
		_modules="${_modules} ${_dependency} "
	done ; done

	# If not in run once mode, remove temporary files.
	if test ! -z "${_temp_dir:-}" && test -z "${workshop_detached:-}"
	then
		rm -Rf "${_temp_dir}"
	fi

	require ()
	{
		resolve "${@:-}"
	}
}

tempdir ()
{
    _temp_dir="$(
    	mktemp -d \
    	"${TMPDIR:-/tmp}/workshop.XXXXXX" 2>/dev/null || :
	)"
    if test -z "${_temp_dir:-}"
	then
		_temp_dir="${TMPDIR:-/tmp}/workshop."$(
			od -An -N2 -i /dev/random | sed 's/[ 	]*//m'
		)
	    mkdir -m 'u+rwx' "${_temp_dir}"
	fi

	printf %s "${_temp_dir}"
}

flash ()
{
	if test -z "${workshop_tput_el:-}"
	then
		workshop_tput_el="$(tput 'el' 2>/dev/null || :)"
		workshop_tput_el1="$(tput 'el1' 2>/dev/null || :)"
	fi

	printf %s\\r "${workshop_tput_el}${workshop_tput_el1}${*:-}" 1>&2
}

httpgetfile ()
{
	if curl --help >/dev/null 2>&1
	then
		curl --fail -L "${1}" \
			2>/dev/null > "${2}" || return 1

		return 0
	elif wget --help >/dev/null 2>&1
	then
		wget -qO- "${1}" \
			2>/dev/null  > "${2}" || return 1

		return 0
	fi

	return 127
}

workshop "${0}" "${@:-}"
