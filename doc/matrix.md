# Compatibility Tests

workshop is designed to run in many shells. In order to test this
constraint, we need to setup a test matrix that runs the workshop
test suite in all supported shells.

## Setup

For that, we will set up a test scenario. We will use the `doc/` folder
to run all tests and a script to match combinations.

[~]:folder:doc/

To run in all platforms, we will setup needed packages and install them
accordingly using `environment.sh` files that you can tweak:

### Debian Environment

[~]:file:debian-environment.sh
	APTGET='bash dash ksh mksh pdksh posh yash busybox zsh-beta bash2.05b bash3.0.16 bash3.2.48 bash4.2.45'
	SHELLS='dash,bash,zsh,mksh,busybox sh,ksh,pdksh,posh,yash,zsh-beta,bash2.05b,bash3.0.16,bash3.2.48,bash4.2.45'

	add-apt-repository ppa:agriffis/bashes -y
	apt-get update
	apt-get install -y ${APTGET}


### OS X Environment

[~]:file:osx-environment.sh
	BREW='dash bash ksh mksh zsh'
	SHELLS='dash,bash,ksh,mksh,zsh'

	brew update
	brew install $BREW

### MSYS Environment

[~]:file:msys-environment.sh
	PACMAN='zsh mksh bash busybox'
	SHELLS='bash,zsh,mksh,busybox sh'

	pacman --noconfirm -Sy --needed pacman-mirrors
	pacman --noconfirm -Sy
	pacman --noconfirm -Sy $PACMAN

## Matrix

[~]:show
	if command -v apt-get; then . debian-environment.sh; fi
	if command -v brew;    then . osx-environment.sh;    fi
	if command -v pacman;  then . msys-environment.sh;   fi
	if test -f matrix.tap; then rm matrix.tap; fi

	RUNS=''
	POSIT="eval,"${SHELLS}

	# Loop in all shells
	IFS=','
	for TARGET in $SHELLS
	do
		IFS=','
		# Loop in all posit shells
		for SHELL in $POSIT
		do
			echo "# ${TARGET}+${SHELL}"
			RUNS="${RUNS}${RUNS:+ }${TARGET}+${SHELL}"

			# Run a test for each combination
			IFS=' '
			posit_shell="${SHELL}" \
				$TARGET workshop posit run doc/testing.md |
				tee -a matrix.tap
			IFS=','
		done
	done

	IFS=' '

	echo "# Results"

	# Compare all test runs
	cat matrix.tap | workshop untap compare ${RUNS}
