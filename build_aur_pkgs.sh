#!/usr/bin/env bash

## This script will download and build AUR pkgs.

## ANSI Colors (FG & BG)
RED="$(printf '\033[31m')"  GREEN="$(printf '\033[32m')"  ORANGE="$(printf '\033[33m')"  BLUE="$(printf '\033[34m')"
MAGENTA="$(printf '\033[35m')"  CYAN="$(printf '\033[36m')"  WHITE="$(printf '\033[37m')" BLACK="$(printf '\033[30m')"

## Packages
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
	  compton-tryone-git
	  timeshift
	  cava
	  xfce-polkit
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
_pkgs=()
_failed=()

## Reset terminal colors
reset_color() {
	tput sgr0   # reset attributes
	tput op     # reset color
    return
}

## Script Termination
exit_on_signal_SIGINT () {
    { printf "\n\n%s\n" "Script interrupted." 2>&1; echo; }
	if [[ -d "$DIR"/aur_pkgs ]]; then
		{ rm -rf "$DIR"/aur_pkgs; reset_color; exit 0; }
	else
		{ reset_color; exit 0; }
	fi
}

exit_on_signal_SIGTERM () {
    { printf "\n\n%s\n" "Script terminated." 2>&1; echo; }
	if [[ -d "$DIR"/aur_pkgs ]]; then
		{ rm -rf "$DIR"/aur_pkgs; reset_color; exit 0; }
	else
		{ reset_color; exit 0; }
	fi
}

trap exit_on_signal_SIGINT SIGINT
trap exit_on_signal_SIGTERM SIGTERM

# Download AUR packages
download_pkgs () {
	{ echo -e ${BLUE}"\n[*] Downloadind AUR packages...\n"; reset_color; }
	mkdir -p "$DIR"/aur_pkgs && cd "$DIR"/aur_pkgs
	_fail_to_download=()

	for pkg in "${PKGS[@]}"; do
		git clone --depth 1 https://aur.archlinux.org/${pkg}.git	
		if [[ "$?" -eq 0 ]]; then
			echo -e "\n'${pkg}' downloaded successfully.\n"
		else
			echo -e "\nFailed to download '${pkg}'.\n"
			_fail_to_download+=()
		fi
    done

	## List failed packages
	for _fd in "${_fail_to_download[@]}"; do
		echo -e "Failed to download package : ${RED}${_fd}"
		reset_color
	done
	echo -e "\nDownload Manually.\n"
}

# Chech for new version
check_ver () {
	{ echo -e ${BLUE}"[*] Checking for new AUR packages...\n"; reset_color; }
	cd "$DIR"/aur_pkgs
	for pkg in "${PKGS[@]}"; do
		cd ${pkg}
		ver=`cat PKGBUILD | grep -i pkgver= | sed 's/.*=//g' | tr -d "'"`
		rel=`cat PKGBUILD | grep -i pkgrel= | sed 's/.*=//g' | tr -d "'"`

		new=${ver}-${rel}
		current=`pacman -Q ${pkg} 2>/dev/null | awk '{print $2}'`
		
		echo "[*] Package Name : ${pkg}"
		echo "[+] New version : ${ORANGE}$new"${WHITE}
		echo "[-] Current version : ${CYAN}$current"${WHITE}
		if [[ "$new" != "$current" ]]; then
			if [[ -z "$current" ]]; then
				echo -e ${MAGENTA}"[!] Package ${pkg} not found.\n"${WHITE}
			else
				echo -e ${RED}"[!] Package ${pkg} needs an update, Added to build list.\n"${WHITE}
				_pkgs+=("${pkg}")
			fi
		else
			echo -e ${GREEN}"[*] Package ${pkg} is already the latest.\n"${WHITE}
		fi
		
		cd "$DIR"/aur_pkgs
	done
}

# Build AUR packages
build_pkgs () {
	{ echo -e ${BLUE}"[*] Building AUR Packages...\n"; reset_color; }
	cd "$DIR"/aur_pkgs
	for _pkg in "${_pkgs[@]}"; do
		echo "Building ${_pkg}..."
		cd ${_pkg} && makepkg -s
		if [[ "$?" -eq 0 ]]; then
			echo -e "Package '${_pkg}' generated successfully.\n"
			mv *.pkg.tar.zst "$PKGDIR"
		else
			echo -e "\nFailed to build '${_pkg}', Added to failed list.\n"
			_failed+=("${_pkg}")
		fi
		cd "$DIR"/aur_pkgs
	done
	
	## List failed packages
	for _fail in "${_failed[@]}"; do
		echo -e "Failed to build package : ${RED}${_fail}"
		reset_color
	done
	echo -e "Build manually.\n"
}

# Cleanup
cleanup () {
	{ echo -e ${BLUE}"[*] Cleaning up...\n"; reset_color; }
	rm -rf "$DIR"/aur_pkgs
	if [[ ! -d "$DIR"/aur_pkgs ]]; then
		{ echo -e "\nCleanup Completed."; exit 0; }
	else
		{ echo -e "\nCleanup failed."; exit 1; }
	fi	
}

# Main
download_pkgs
check_ver
build_pkgs
cleanup
