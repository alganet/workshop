#!/usr/bin/env workshop

serve_abort ()
{
	buffer_dir="${1}"
	rm -rf "${buffer_dir}"
	exit
}

serve_buffer ()
{
	buffer_dir="${1}"
	if test -z "${buffer_name:-}"
	then
		temp_dir="$(tempdir)"
		buffer_name="$(od -N4 -tu /dev/random | tr " " "-" | tr -d '\n' )"
		buffer_file="${buffer_dir}/${buffer_name}"

		mkfifo "${buffer_file}"
	fi
	echo "${buffer_file}"
}


serve_response ()
{
	rootdir="${PWD}"
	reldir="${REQUEST_URI}"
	target="${rootdir}/${reldir}"
	target="${target%*/}"

	if [ -f "${target}" ]; then
		case "${target##*.}" in
			"html" )
				type='text/html'
				;;
			"css" )
				type='text/css'
				;;
			"png" )
				type='image/png'
				;;
			"jpg" )
				type='image/jpeg'
				;;
			"gif" )
				type='image/gif'
				;;
			"js" )
				type='text/javascript'
				;;
			* )
				type='text/plain'
				;;
		esac

	elif [ -d "${target}" ]; then
		find "${target}/" -maxdepth 1 -mindepth 1 | while read -r file
		do
			filepath="${reldir}$(basename "${file}")"

			if [ -d "${file}" ]; then
				filepath="${filepath}/"
			fi

			echo "<li><a href='${filepath}'>${filepath}</a></li>"
		done > "/tmp/response"
		type='text/html'
		target="/tmp/response"
	fi

	length=$(wc -c < "${target}")
	cat <<-MSG
		HTTP/1.1 200 OK
		Connection: keep-alive
		Content-Type: ${type}
		Content-Length: ${length}
		${CR}
	MSG
	cat "${target}"

	return
}


serve_parse_request ()
{
	while test -e "${buffer_in}" &&
		 read -r REQUEST_METHOD REQUEST_URI SERVER_PROTOCOL
	do
		if test "${SERVER_PROTOCOL:-}" = "HTTP/1.1${CR}"
		then
			"${callback}"
		fi
	done < "${buffer_in}"
}

serve ()
{
    CR="$(printf '\r')"
	callback="serve_response"
	buffer_dir="$(tempdir)"
	connector2="nc -v -p ${1:-9999} -l 127.0.0.1"
	connector1="nc -v 127.0.0.1 ${1:-9999}"
	buffer_in=$(serve_buffer "${buffer_dir}")
	buffer_out=$(serve_buffer "${buffer_dir}")
	trap 'serve_abort "${buffer_dir}"' 2

	while true
	do
		echo "Connecting..."
		( ${connector1} || ${connector2} ) < "${buffer_out}" > "${buffer_in}" &
		serve_parse_request > "${buffer_out}" &
		wait
		echo "Dropped..."
	done

	rm -rf "${buffer_dir}"
	exit
}
