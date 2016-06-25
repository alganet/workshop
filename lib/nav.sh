#!/usr/bin/env workshop

require 'dispatch'

nav ()
{
	dispatch 'nav' "${@:-}"
}

nav_command_open () ( nav_open "${@:-}" )

nav_option_h () ( nav_command_help )
nav_option_help () ( nav_command_help )
nav_command_help ()
{
	cat <<-NAVHELP
		Usage: nav [OPTIONS] COMMAND

		Commands: open SPEC  Opens a navigation bar with SPEC buttons

		Options: --help      Displays help

	NAVHELP
}

nav_buttonpress ()
{
	eval "${nav_value:-echo '${nav_text}'}" 2>&1 | nav_push_out
}

nav_read_char ()
{
	IFS= read -n1 nav_key
}

nav_dd_char ()
{
	nav_key="$(dd count=1 bs=1 2>/dev/null)"
}

nav_push_out ()
{
	cat | while read -r _line
	do
		nav_push_line "${_line}"
	done
}

nav_push_line ()
{
	if test -z "${nav_buffer:-}" &&
		test "${nav_scroll_top}" -gt 0
	then
		nav_scroll_top=$((nav_scroll_top - 1))
	fi

	if test ! -z "${nav_buffer:-}" &&
			test "${nav_scroll_top}" -gt "${nav_buffer}"
	then
		nav_scroll_top=$((nav_scroll_top - 1))
	fi

	printf "${@:-}"
	printf "${nav_end_clean}"
	printf '\r'
	printf "${nav_cursor_up}"

	if test ! -z ${nav_buffer:-} &&
		test "${nav_scroll_top}" = "${nav_buffer}"
	then
		printf "${nav_cursor_buffer_down}"
		printf \\n\\r
		printf "${nav_cursor_buffer_up}"
	else
		printf \\n\\r
		printf "${nav_cursor_down}"
	fi

	if test -z ${nav_buffer:-} && test "${nav_scroll_top}" = 0
	then
		printf \\n\\r
	fi

	printf "${nav_sc}"
}

nav_keypress ()
{
	nav_text=''
	nav_value=''
	nav_opened=0
	nav_closed=0
	nav_meta=0
	nav_max_focus="${nav_max_focus:-99}"

	printf "${nav_rc}"
	printf "${nav_sc}"
	#nav_push_line "Debug: $1 ${2:-}"

	IFS=' '
	for nav_display in ${nav_start} ${nav_contents:-} ${nav_end}
	do
		case "$nav_display" in
			'[' )
				nav_opened=$((nav_opened + 1))
				nav_meta=0
				;;
			']' )
				nav_closed=$((nav_closed + 1))
				;;
			':' )
				nav_meta=1
				;;
			* )
				if test "$nav_opened" -gt "$nav_closed" &&
					test "$nav_opened" = "$nav_focus"
				then
					widget_type=button
					if test "${nav_meta}" = 0
					then
						if test '' = "${nav_text}"
						then
							nav_text="${nav_display}"
						else
							nav_text="${nav_text} ${nav_display}"
						fi
					else
						if test '' = "${nav_value}"
						then
							nav_value="${nav_display}"
						else
							nav_value="${nav_value} ${nav_display}"
						fi
					fi
				fi
				;;
		esac
	done
	IFS=

	case ${1:-nop}_${2:-} in
		left_ | n_ )
			if test $nav_focus -gt 1
			then
				nav_focus=$((nav_focus - 1))
			fi
			;;
		right_ | p_ )
			if test $nav_focus -lt $nav_max_focus
			then
				nav_focus=$((nav_focus + 1))
			fi
			;;
		home_ )
			nav_focus=1
			;;
		end_ )
			nav_focus=$nav_max_focus
			;;
		ret_ )
			${nav_buttonpress:-nav_buttonpress}
			;;
		l_ct )
			nav_scroll_top=$nav_rows
			tput clear 2>/dev/null || printf '\033[2J'
			printf "${nav_sc}"
		;;
		tab_s | back_ )
			if test $nav_focus = 1
			then
				nav_focus=$nav_max_focus
			else
				nav_focus=$((nav_focus - 1))
			fi
			;;
		back_c )
			nav_focus=1
			;;
		tab_ )
			if test $nav_focus = $nav_max_focus
			then
				nav_focus=1
			else
				nav_focus=$((nav_focus + 1))
			fi
			;;
		* )
			;;
	esac

	nav_frame "${@:-}"
}

nav_frame_prepare ()
{
	nav_frame
	printf "${nav_rc}"
}

nav_frame ()
{
	nav_opened=0
	nav_closed=0
	nav_meta=0
	IFS=' '
	for nav_display in ${nav_start} ${nav_contents:-} ${nav_end}
	do
		case "$nav_display" in
			'[' )
				nav_opened=$((nav_opened + 1))
				nav_meta=0
				if test "$nav_opened" = "$nav_focus"
				then
					printf '\033[2m\033[7m \033[0m\033[7m '
				else
					printf '[ '
				fi
				;;
			']' )
				nav_closed=$((nav_closed + 1))
				if test "$nav_closed" = "$nav_focus"
				then
					printf '\033[0m\033[2m\033[7m \033[0m '
				else
					printf ']\033[0m '
				fi
				;;
			':' )
				nav_meta=1
				;;
			* )
				if test "${nav_meta}" = 0
				then
					printf '%s ' ${nav_display}
				fi
				;;
		esac
	done
	printf "${nav_end_clean}"
	IFS=
	nav_max_focus="${nav_closed:-0}"
}

nav_keyloop ()
{
	while :
	do
		nav_keys=''
		$nav_get_key
		C1=$nav_key
		case _"${C1}"_ in
			_${nav_3}_ )
				$nav_emit c ct
				nav_exit
				;;
			_${nav_ctrl_l}_ )
				$nav_emit l ct
				;;
			_"	"_ )
				$nav_emit tab
				;;
			_${nav_177}_ )
				$nav_emit back
				;;
			_${nav_36}_ )
				$nav_emit ret ct
				;;
			_${nav_37}_ )
				$nav_emit back c
				;;
			_"${nav_return}"_ | _"${nav_line}"_ )
				$nav_emit ret
				;;
			_"${nav_backspace}"_ | _"${nav_del}"_ ) # Delete Key
				$nav_emit del
				;;
			"_${nav_esc}_" | "_${nav_33}_")
				C1="${nav_esc}"
				$nav_get_key
				C2=$nav_key
		case _"${C2}"_ in
			_"["_ )
				$nav_get_key
				C3=$nav_key
		case "_${C3}_" in
			_[0-9]_ )
				$nav_get_key
				C4=$nav_key
				nav_keys="${C1}${C2}${C3}${C4}"
		case "_${C3}${C4}_" in
			_3~_ ) $nav_emit del ;;
			_2~_ ) $nav_emit ins ;;
			_5~_ ) $nav_emit pgup ;;
			_6~_ ) $nav_emit pgdn ;;
			_[0-9][0-9]_ )
		case _"${C3}${C4}"_ in
			_15_ ) CX="f5" ;;
			_17_ ) CX="f6" ;;
			_18_ ) CX="f7" ;;
			_19_ ) CX="f8" ;;
			_20_ ) CX="f9" ;;
			_21_ ) CX="f10" ;;
			_23_ ) CX="f11" ;;
			_24_ ) CX="f12" ;;
		esac
			$nav_get_key
			C5=$nav_key
			nav_keys="${C1}${C2}${C3}${C4}${C5}"
		case _"${C5}"_ in
			_~_ )
				;;
			_";"_ )
				$nav_get_key
				C6=$nav_key
				$nav_get_key
				C7=$nav_key
				nav_keys="${nav_keys}${C6}${C7}"
		case _"${C6}${C7}"_ in
			_2~_ )
				CX="${CX} s"
				;;
			_5~_ )
				CX="${CX} ct"
				;;
			_6~_ )
				CX="${CX} ct_s"
				;;
			* ) ;;
		esac
				;;
			* )
				nav_keys="${C1}${C2}${C3}${C4}${C5}"
				;;
		esac
			$nav_emit ${CX}
			;;
		_[1356]";"_ )
			$nav_get_key
			C5=$nav_key
			nav_keys="${C1}${C2}${C3}${C4}${C5}"
			CX=''
		case _"${C3}${C4}${C5}"_ in
			_"1;8"_ ) CX=" ct_a_s" ;;
			_"1;7"_ ) CX=" ct_a" ;;
			_"1;6"_ ) CX=" ct_s" ;;
			_"1;5"_ ) CX=" ct" ;;
			_"1;4"_ ) CX=" a_s" ;;
			_"1;3"_ ) CX=" a" ;;
			_"1;2"_ ) CX=" s" ;;
			_"3;2"_ ) $nav_emit del s ;;
			_"3;2"_ ) $nav_emit del s ;;
			_"3;5"_ ) $nav_emit del ct ;;
			_"3;3"_ ) $nav_emit del a ;;
			_"3;4"_ ) $nav_emit del a_s ;;
			_"3;6"_ ) $nav_emit del ct_s ;;
			_"5;4"_ ) $nav_emit pgup a_s ;;
			_"6;4"_ ) $nav_emit pgdn a_s ;;
			_"5;5"_ ) $nav_emit pgup ct ;;
			_"6;5"_ ) $nav_emit pgdn ct ;;
			_"5;6"_ ) $nav_emit pgup ct_s ;;
			_"6;6"_ ) $nav_emit pgdn ct_s ;;
			_"5;7"_ ) $nav_emit pgup ct_a ;;
			_"6;7"_ ) $nav_emit pgdn ct_a ;;
			_"5;8"_ ) $nav_emit pgup ct_a ;;
			_"6;8"_ ) $nav_emit pgdn ct_a ;;
		esac
			$nav_get_key
			C6=$nav_key
			nav_keys="${C1}${C2}${C3}${C4}${C5}${C6}"
		case _"${C6}"_ in
			_D_ ) $nav_emit left${CX} ;;
			_C_ ) $nav_emit right${CX} ;;
			_A_ ) $nav_emit up${CX} ;;
			_B_ ) $nav_emit down${CX} ;;
			_P_ ) $nav_emit f1${CX} ;;
			_Q_ ) $nav_emit f2${CX} ;;
			_R_ ) $nav_emit f3${CX} ;;
			_S_ ) $nav_emit f4${CX} ;;
			_F_ ) $nav_emit end${CX} ;;
			_H_ ) $nav_emit home${CX} ;;
		esac
				;;
			* )
				nav_keys="${C1}${C2}${C3}${C4}"
				;;
		esac
				;;
			_"A"_ ) $nav_emit up ;;
			_"B"_ ) $nav_emit down ;;
			_"C"_ ) $nav_emit right ;;
			_"D"_ ) $nav_emit left ;;
			_"F"_ ) $nav_emit end ;;
			_"H"_ ) $nav_emit home ;;
			_"Z"_ ) $nav_emit tab s ;;
			* ) nav_keys="${C1}${C2}${C3}" ;;
		esac
				;;
			_O_ )
				$nav_get_key
				C3=$nav_key
		case "_${C3}_" in
			_"P"_ ) $nav_emit f1 ;;
			_"Q"_ ) $nav_emit f2 ;;
			_"R"_ ) $nav_emit f3 ;;
			_"S"_ ) $nav_emit f4 ;;
			* ) nav_keys="${C1}${C2}${C3}" ;;
		esac
				;;
			_"${nav_esc}"_ )
				$nav_emit esc esc
				;;
			* )
				nav_keys="${C1}${C2}"
				;;
		esac
				;;
			_[a-zA-Z0-9]_                              |\
			_[\'\"\[\]\ \-\+\!\@\#\$\%\&\*]_           |\
			_[\(\)\_\=\{\}\~\:\;\,\.\<\>\?\/\^\`\\\|]_ )
				$nav_emit "${C1}"
				;;
			* )
				nav_keys="${C1}"
				;;
		esac
		unset C1 C2 C3 C4 C5 C6 C7 CX
	done
}

nav_push_state ()
{
	printf "${nav_sc}"
	printf ' \033[1m'${nav_char}'\033[0m'
	printf "${nav_rc}"
	nav_focus=1
	nav_contents="${1:-}"
	nav_chars="$(nav_frame | wc -m)"
	if test ! -z ${nav_buffer:-}
	then
		_i=1
		while test "${_i}" -lt ${nav_buffer:--1}
		do
			_i=$((_i + 1))
			printf \\n\\r
			printf "${nav_end_clean}"
			printf "${nav_sc}"
			printf "${nav_rc}"
		done
		printf "${nav_cursor_buffer_up:-$nav_cursor_up}"
	fi
	if test "$nav_cols" -lt "$nav_chars"
	then
		printf "${nav_end_clean}"
		nav_new_buffer=$(expr $nav_chars / $nav_cols)
		if test $nav_new_buffer -gt ${nav_buffer:-0}
		then
			nav_buffer=${nav_new_buffer}
			nav_cursor_buffer_down="$(tput cud $nav_buffer ||
				printf "\033[${nav_buffer}B")"
			nav_cursor_buffer_up="$(tput cuu $nav_buffer ||
				printf "\033[${nav_buffer}A")"
			_i=1
			while test "${_i}" -lt ${nav_buffer:--1}
			do
				_i=$((_i + 1))
				printf \\n\\r
				printf "${nav_end_clean}"
				printf "${nav_sc}"
				printf "${nav_rc}"
			done
			printf "${nav_cursor_buffer_up}"
		fi
	fi
	printf "${nav_sc}"
	printf "${nav_end_clean}"
	nav_text=""
	printf '\r'
}


nav_exit ()
{
	_i=1
	while test "${_i}" -lt ${nav_buffer:--1}
	do
		_i=$((_i + 1))
		if test ${nav_scroll_top:-0} -gt $((${nav_buffer:-} + 1))
		then
			printf \\n\\r
		fi
		printf "${nav_rc}"
		printf "${nav_end_clean}"
		printf "${nav_end_clean1}"
	done
	printf '\r\033[2m'
	nav_focus=-1 nav_frame | sed -e "s/\x1b\[.\{1,5\}m//g"
	printf '\033[0m'
	if test ! -z ${nav_buffer:-}
	then
		printf "${nav_cursor_buffer_down}"
	fi
	stty "${nav_previous_stty:-}"
	printf '\033[?25h' # Show Blinking Cursor
	echo ""
	exit
}

nav_open ()
{
	nav_char='~'
	printf "\033[?25l~ " # Hide Blinking Cursor
	tput sc 2>/dev/null  || printf '\033[s'
	nav_cols="$(stty size | cut -d ' ' -f2)"
	nav_progress_total="$(expr $nav_cols / 19)"
	nav_progress_done=0
	nav_progress_ ()
	{
		_i=1
		while test "${_i}" -lt "${nav_progress_total}"
		do
			_i=$((_i + 1))
			nav_progress_done=$((nav_progress_done + 1))
			if test $nav_progress_done -lt $nav_cols
			then
				printf "${nav_rc}\033[1m_\033[0m${nav_sc}"
			fi
		done
	}
	nav_sc="$(tput sc 2>/dev/null  || printf '\033[s')"
	nav_rc="$(tput rc 2>/dev/null  || printf '\033[u')"
	nav_progress_
	nav_end_clean1="$(tput el1 2>/dev/null  || printf '\033[1K')"
	trap "nav_exit" 2
	nav_progress_
	nav_end_clean="$(tput el 2>/dev/null  || printf '\033[K')"
	nav_rows="$(stty size | cut -d ' ' -f1)"
	nav_progress_
	nav_input="${1:-[ About nav ] [ Exit ]}"
	nav_stack=0
	nav_start="${nav_char}"
	nav_end=''
	tput smcup > /dev/null 2>/dev/null  || printf '\033[47h' > /dev/null
	nav_progress_
	nav_cursor_up="$(tput cud 1 2>/dev/null  || printf '\033[1A')"
	nav_progress_
	nav_cursor_down="$(tput cuu 1 2>/dev/null  || printf '\033[1B')"
	nav_progress_
	nav_restore_screen="$(tput rmcup 2>/dev/null  || printf '\033[47l')"
	nav_esc="$(printf '\E')"
	nav_progress_
	nav_33="$(printf '\033')"
	nav_return="$(printf '\r')"
	nav_progress_
	nav_line="$(printf '\n')"
	nav_progress_
	nav_tab="$(printf '\t')"
	nav_backspace="$(printf '\b')"
	nav_progress_
	nav_del="$(printf '\127')"
	nav_progress_
	nav_36=""$(printf '\036')""
	nav_progress_
	nav_37="$(printf '\037')"
	nav_3="$(printf '\003')"
	nav_progress_
	nav_ctrl_l="$(printf '\f')"
	nav_progress_
	nav_177="$(printf '\177')"
	nav_progress_
	nav_emit=nav_keypress
	if ( printf 1 | read -n 1 2>/dev/null )
	then
		nav_get_key="nav_read_char"
	else
		nav_get_key="nav_dd_char"
	fi
	nav_progress_
	nav_keys=''
	nav_focus=1
	printf "\r"
	nav_previous_stty="$(stty -g)"
	stty raw -echo -isig -ixon -ixoff intr '' -tostop time 0 2>/dev/null
	nav_progress_
	nav_terminal_pos=''
	printf '\033[6n'
	$nav_get_key
	if test _"${nav_key}"_ = _"${nav_33}"_
	then
		$nav_get_key
		$nav_get_key
		while test _"${nav_key}"_ != _"R"_
		do
			nav_terminal_pos="${nav_terminal_pos}${nav_key}"
			$nav_get_key
		done
		nav_progress_
	fi
	nav_row_position="$(printf %s "${nav_terminal_pos}" |
		cut -d ';' -f1)"
	nav_scroll_top=$((nav_rows - nav_row_position + 1))
	tput rmcup 2>/dev/null  || printf '\033[47l'
	nav_progress_
	unset -f nav_progress_
	printf \\r
	PS4="\\r+ "
	nav_push_state "${nav_input}"
	nav_keypress init
	nav_keyloop
	printf '\033[?25h' # Show Blinking Cursor
	nav_exit
}
