#!/usr/bin/env bash

## Dirs
DIR="$(pwd)"
PKGS=(`ls --hide={LICENSE,README.md,build_pkgs.sh,packages,build_aur_pkgs.sh,packages_aur}`)
PKGDIR="$DIR/packages"

## Script Termination
exit_on_signal_SIGINT () {
    { printf "\n\n%s\n" "Script interrupted." 2>&1; echo; }
    exit 0
}

exit_on_signal_SIGTERM () {
    { printf "\n\n%s\n" "Script terminated." 2>&1; echo; }
    exit 0
}

trap exit_on_signal_SIGINT SIGINT
trap exit_on_signal_SIGTERM SIGTERM

# Build packages
build_pkgs () {
	local pkg

	{ echo; echo "Building Packages - "; echo; }
	for pkg in "${PKGS[@]}"; do
		{ echo -e "Building ${pkg}..."; echo; }
		cd ${pkg} && makepkg -s
		mv *.pkg.tar.zst "$PKGDIR" && rm -rf pkg

		# Verify
		while true; do
			set -- "$PKGDIR"/${pkg}-*
			if [[ -f "$1" ]]; then
				{ echo; echo "Package '${pkg}' generated successfully."; echo; }
				break
			else
				{ echo; echo "Failed to build '${pkg}', Exiting..." >&2; }
				{ echo; exit 1; }
			fi
		done
		cd "$DIR"
	done	
}

# Execute
build_pkgs
