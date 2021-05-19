#!/usr/bin/env bash

## This script will download and build AUR pkgs.

## Dirs
DIR="$(pwd)"
PKGDIR="$DIR/packages_aur"

LIST=(ckbcomp
	  mkinitcpio-openswap
	  adapta-kde
	  colorpicker
	  blight
	  i3lock-color
	  betterlockscreen
	  ksuperkey
	  networkmanager-dmenu-git
	  obmenu-generator
	  perl-linux-desktopfiles
	  polybar
	  yay
	  picom-ibhagwan-git
#	  compton-tryone-git
	  timeshift
	  cava
	  downgrade
	  pyroom
	  pygtk
	  libglade
	  python2-gobject2
	  toilet
	  tty-clock
	  unimatrix-git)

# Sort packages
PKGS=(`for i in "${LIST[@]}"; do echo $i; done | sort`)

## Script Termination
exit_on_signal_SIGINT () {
    { printf "\n\n%s\n" "Script interrupted." 2>&1; echo; }
	if [[ -d "$DIR"/aur_pkgs ]]; then
		{ rm -rf "$DIR"/aur_pkgs; exit 0; }
	else
		exit 0
	fi
}

exit_on_signal_SIGTERM () {
    { printf "\n\n%s\n" "Script terminated." 2>&1; echo; }
	if [[ -d "$DIR"/aur_pkgs ]]; then
		{ rm -rf "$DIR"/aur_pkgs; exit 0; }
	else
		exit 0
	fi
}

trap exit_on_signal_SIGINT SIGINT
trap exit_on_signal_SIGTERM SIGTERM

# Download AUR packages
download_pkgs () {
	mkdir "$DIR"/aur_pkgs && cd "$DIR"/aur_pkgs
	for pkg in "${PKGS[@]}"; do
		git clone --depth 1 https://aur.archlinux.org/${pkg}.git
	# Verify
		while true; do
			set -- "$DIR"/aur_pkgs/${pkg}
			if [[ -d "$1" ]]; then
				{ echo; echo "'${pkg}' downloaded successfully."; echo; }
				break
			else
				{ echo; echo "Failed to download '${pkg}', Exiting..." >&2; }
				{ echo; exit 1; }
			fi
		done
    done
}

# Build AUR packages
build_pkgs () {
	{ echo "Building AUR Packages - "; echo; }
	cd "$DIR"/aur_pkgs
	for pkg in "${PKGS[@]}"; do
		echo "Building ${pkg}..."
		cd ${pkg} && makepkg -s
		mv *.pkg.tar.zst "$PKGDIR"
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
		cd "$DIR"/aur_pkgs
	done
}

# Cleanup
cleanup () {
	echo "Cleaning up..."
	rm -rf "$DIR"/aur_pkgs
	if [[ ! -d "$DIR"/aur_pkgs ]]; then
		{ echo; echo "Cleanup Completed."; exit 0; }
	else
		{ echo; echo "Cleanup failed."; exit 1; }
	fi	
}

# Main
download_pkgs
build_pkgs
cleanup
