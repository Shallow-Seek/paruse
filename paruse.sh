#!/bin/bash
if [ -z "$BASH_VERSION" ]; then
    exec /bin/bash "$0" "$@"
    echo "• • • Operating in Bash..."
fi
# Installed packages (including aur) will be managed through packagelist (file) for portability and preservation
# of compute resources when referring to the list later on. Also helps to replicate a system later on.
# It can also be synced (basically rewritten) in the Interactive menu below.
# paru and fzf are requirements.
# setup environment
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
config_dir="$HOME/.config/paruse"
packagelist="$config_dir/my_package_list"
viewmode="All"
reviewmode="Review Changes"
for dep in paru fzf; do
    if ! command -v "$dep" &>/dev/null; then
        echo "• • • '$dep' not found. Installing..."
        sudo pacman -Sy --noconfirm "$dep"
    fi
done
if [[ ! -d "$config_dir" ]]; then
    echo " • • • ./config/paruse created. A backup of your packages can be found here..."
    mkdir -p "$config_dir"
fi
if [[ ! -s "$packagelist" ]]; then
    echo " • • • packagelist is empty or missing. Populating with installed packages..."
    paru -Qqe | sort > "$packagelist"
    sleep 4
fi
blueish="\e[38;2;131;170;208m"; yellowish="\e[38;2;175;175;135m"; nocolor="\e[0m"
options=(
    "1 • View package list"
    "2 • Add/Browse packages"
    "3 • Remove package"
    "4 • Purge package"
    "•"
    "5 • Toggle view mode"
    "6 • Toggle review mode"
    "•"
    "7 • Update system"
    "8 • Package data briefing"
    "9 • Package cache cleaning"
    "•"
    "10 • Sync current package list"
    "11 • Restore full package list"
    "12 • Backup current package list"
    "•"
    "13 • Fetch Arch Linux News"
    "14 • Set a custom bash_alias for Paruse"
    "q • Quit"
)
pstate="
Paruse: Package Management for packages that you just cant live without
View Mode: ${blueish}${viewmode}${nocolor}
Review Mode: ${blueish}${reviewmode}${nocolor}
"
help="
1 • View package list
    Presents a list of explicitly installed packages on this system using:
    ${yellowish}paru -Qqe | sort > \"\$packagelist\"${nocolor}
    This list can be filtered by all, only aur, no aur, packages using:
    ${yellowish}6 • Toggle view mode${nocolor}

2 • Add or Browse packages
    Presents a query for all arch/aur repositories using:
    ${yellowish}paru -Slq | fzf --preview='paru -Si \{\}'${nocolor}
    User can browse packages and package data/details, see whats installed.
    Then install packages by typing a name or double-clicking it.
    Multiple packages (package1 package2) can be input for batch install.
    Install behavior can be set to Review Changes, Skip Review, or Progress using:
    ${yellowish}7 • Toggle review mode${nocolor}

3 • Remove package
    Presents a searchable list of packages currently installed on the system using:
    ${yellowish}paru -Slq | fzf --preview='paru -Si \{\}'${nocolor}
    Inputting a package or double clicking it, proceeds with:
    ${yellowish}paru -R package${nocolor}

4 • Purge package
    Presents a searchable list of packages currently installed on the system using:
    ${yellowish}paru -Slq | fzf --preview='paru -Si \{\}'${nocolor}
    Inputting a package or double clicking it, proceeds with:
    ${yellowish}paru -Rns package${nocolor}

7 • Update system
    Performs a full system upgrade using:
    ${yellowish}paru -Syu${nocolor}

8 • Package data briefing
    Shows a total package overview, total packages seperated by type,
    Amount of disk space occupied by packages, biggest packages, etc, using:
    ${yellowish}paru -Ps${nocolor}

9 • Package cache cleaning
    Gives you options for cleaning up pacman & paru cache directories using:
    ${yellowish}paru -Scc${nocolor}
    Very useful for when you need to clean build an aur package...

10 • Sync current package list
    Updates the saved package list file to match the currently installed explicit packages:
    ${yellowish}paru -Qqe | sort > \"\$packagelist\"${nocolor}

11 • Restore full package list
    User can choose from packagelist backups to reinstall packages from:
    ${yellowish}paru -S --needed \$(< \"\$packagelist\")${nocolor}
    Install behavior can be set to Review Changes, Skip Review, or Only Show Progress using:
    ${yellowish}7 • Toggle review mode${nocolor}

12 • Backup current package list
    Creates a timestamped backup of your current package list in the backups folder:
    ${yellowish}\$packagelist.backups/\$(date +%F_%H-%M-%S)${nocolor}
    This points to ${HOME}/.config/paruse/

13 • Fetch Arch Linux News
    Fetches Arch Linux News via:
    ${yellowish}paru -Pw${nocolor}

14 • Set custom bash_alias for Paruse
    Allows you to set an alias (e.g., ${yellowish}paruse${nocolor}) for quick access to this tool from your shell config.
    This function is primary for use if Paruse was obtained through git. Although still useful for making more shortcuts.
"

# interactive process
main_menu() {
    local choice
    choice=$(printf '%s\n' "${options[@]}" | fzf \
        --ansi \
        --layout=reverse \
        --prompt="Paruse › " \
        --height=95% \
        --preview-window=right:70%:wrap \
        --preview="echo -e '$pstate\n$help'"
        )

    case "$choice" in
        "1 • View package list") view_package_list ;;
        "2 • Add/Browse packages") add_package ;;
        "3 • Remove package") remove_package ;;
        "4 • Purge package") purge_package ;;
        "5 • Toggle view mode") toggle_view_mode ;;
        "6 • Toggle review mode") toggle_review_mode ;;
        "7 • Update system") paru -Syu && read -rp " • Press Enter to continue..." ;;
        "8 • Package data briefing") paru -Ps && read -rp " • Press Enter to continue..." ;;
        "9 • Package cache cleaning") paru -Scc && read -rp " • Press Enter to continue..." ;;
        "10 • Sync current package list") sync_package_list ;;
        "11 • Restore full package list") install_list ;;
        "12 • Backup current package list") backup_package_list ;;
        "13 • Fetch Arch Linux News") fetch_news ;;
        "14 • Set a custom bash_alias for Paruse") set_alias ;;
        "q • Quit"|"") echo "Cya!"; exit ;;
    esac
}

toggle_view_mode() {
    case $viewmode in
        "All")
            viewmode="Only AUR"
            ;;
        "Only AUR")
            viewmode="No AUR"
            ;;
        "No AUR" | *)
            viewmode="All"
            ;;
    esac
    sed -i "0,/^viewmode=/s|^viewmode=.*|viewmode=\"$viewmode\"|" "$0"
    pstate="
Paruse: Package Management for packages that you just cant live without
View Mode: ${blueish}${viewmode}${nocolor}
Review Mode: ${blueish}${reviewmode}${nocolor}
"
}
toggle_review_mode() {
    case $reviewmode in
        "Review Changes")
            reviewmode="Skip Review"
            ;;
        "Skip Review")
            reviewmode="Only Progress"
            ;;
        "Only Show Progress" | *)
            reviewmode="Review Changes"
            ;;
    esac
    sed -i "0,/^reviewmode=/s|^reviewmode=.*|reviewmode=\"$reviewmode\"|" "$0"
    pstate="
Paruse: Package Management for packages that you just cant live without
View Mode: ${blueish}${viewmode}${nocolor}
Review Mode: ${blueish}${reviewmode}${nocolor}
"
}
view_package_list() {
    case $viewmode in
        "Only AUR")
            mapfile -t aur_pkgs < <(paru -Qmq)
            grep -Fx -f <(printf '%s\n' "${aur_pkgs[@]}") "$packagelist" | fzf \
                --preview 'pacman -Qil {}' \
                --layout=reverse \
                --prompt="Press ESC to return " \
                --preview-window=wrap:70%
            ;;
        "No AUR")
            mapfile -t aur_pkgs < <(paru -Qmq)
            grep -Fxv -f <(printf '%s\n' "${aur_pkgs[@]}") "$packagelist" | fzf \
                --preview 'pacman -Qil {}' \
                --layout=reverse \
                --prompt="Press ESC to return " \
                --preview-window=wrap:70%
            ;;
        *)
            fzf < "$packagelist" \
                --preview 'pacman -Qil {}' \
                --layout=reverse \
                --prompt="Press ESC to return " \
                --preview-window=wrap:70%
            ;;
    esac
}
preview_pkg() {
    local pkg="$1"
    pkg="${pkg// (installed)/}"  # remove " (installed)" suffix if present

    if paru -Si "$pkg" 2>/dev/null | grep -iE "^Repository\s*:\s*aur"; then
        paru -Si "$pkg"
        echo -e "\e[34mREMINDER:\e[0m
This is a package from the AUR (Arch User Repository). While votes and popularity are metrics for AUR packages, they do not guarantee that a package is vetted or safe. Always double check the package by reviewing the package build, and any other file included such as setup and install scripts. Thank you.

\e[34mAUR LINK:\e[0m
https://aur.archlinux.org/packages/$pkg

\e[34mPKGBUILD:\e[0m"
        curl -fsSL "https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=$pkg" || echo "(Unable to fetch PKGBUILD)"
    else
        paru -Si "$pkg"
    fi
}
export -f preview_pkg
add_package() {
    echo -e "\n • Loading Repo(s)..."
    parusing="$config_dir/parusing"
    comm -23 <(paru -Slq | sort) <(paru -Qq | sort) | sed 's/$//' > "$parusing"
    comm -12 <(paru -Slq | sort) <(paru -Qq | sort) | sed 's/$/ (installed)/' >> "$parusing"
    sort "$parusing" -o "$parusing"

    fzf_output=$(fzf \
        --print-query \
        --preview='preview_pkg {}' \
        --layout=reverse \
        --prompt="Enter/DBL-Click a package to add: " \
        --preview-window=wrap:50% \
        < "$parusing")

    query=$(echo "$fzf_output" | head -n1)
    selection=$(echo "$fzf_output" | sed -n '2p' | sed 's/ (installed)//')

    if [[ -n "$selection" ]]; then
        pkg_input="$selection"
    else
        pkg_input="$query"
    fi
    if [[ -z "$pkg_input" ]]; then
        echo -e "\n • No package name entered."
        sleep 2
    else
        for pkg in $pkg_input; do
            if grep -Fxq "$pkg" "$packagelist"; then
                echo " • Package '$pkg' is already in the list."
                sleep 1
            else
                echo -e "\n • '$pkg' marked for installation...\n"
                case "$reviewmode" in
                    "Review Changes")
                        paru -S --needed "$pkg"
                        ;;
                    "Skip Review")
                        paru -S --needed --skipreview --noconfirm "$pkg"
                        ;;
                    "Only Show Progress")
                        paru -S --needed --quiet --noconfirm "$pkg"
                        ;;
                    *)
                        paru -S --needed "$pkg"
                        ;;
                esac
                if [[ $? -eq 0 ]]; then
                    echo "$pkg" >> "$packagelist"
                    echo -e "\n • Package '$pkg' installed and added to list."
                    read -rp " • Press Enter to continue..."
                else
                    echo -e "\n • Installation failed or canceled for '$pkg'. Nothing added to list."
                    read -rp " • Press Enter to continue..."
                fi
            fi
        done
    fi
}
remove_package() {
    typed_input=""
    pkg_to_remove=$(fzf --print-query \
        --preview='pacman -Qil {}' \
        --layout=reverse \
        --prompt="ESC to exit | Select Package(s) to remove: " \
        --preview-window=wrap:50% \
        < "$packagelist")
    typed_input=$(echo "$pkg_to_remove" | head -n1)
    selection=$(echo "$pkg_to_remove" | sed -n '2p')
    # Typing multiple packages detected by space inputs, they also take precedent
    if [[ "$typed_input" == *" "* ]]; then
        for pkg in $typed_input; do
            if ! grep -Fxq "$pkg" "$packagelist"; then
                echo -e "\n • Huh? You typed ('$pkg') but it's not in your installed list...\n"; sleep 2
                continue
            fi
            echo -e "\n • '$pkg' marked for removal...\n"
            case "$reviewmode" in
                "Review Changes")
                    paru -R "$pkg"
                    ;;
                "Skip Review" | "Only Show Progress")
                    paru -R --noconfirm "$pkg"
                    ;;
                *)
                    paru -R "$pkg"
                    ;;
            esac
            if [[ $? -eq 0 ]]; then
                grep -Fxv "$pkg" "$packagelist" > "${packagelist}.tmp" && mv "${packagelist}.tmp" "$packagelist"
                echo -e "\n • Package '$pkg' removed from system and list."
            else
                echo -e "\n • Package removal failed or canceled for '$pkg'."
            fi
        done
        read -rp " • Press Enter to continue..."
    elif [[ -n "$selection" ]]; then
        pkg="$selection"
        echo -e "\n • '$pkg' marked for removal...\n"
        case "$reviewmode" in
            "Review Changes")
                paru -R "$pkg"
                ;;
            "Skip Review" | "Only Show Progress")
                paru -R --noconfirm "$pkg"
                ;;
            *)
                paru -R "$pkg"
                ;;
        esac
        if [[ $? -eq 0 ]]; then
            grep -Fxv "$pkg" "$packagelist" > "${packagelist}.tmp" && mv "${packagelist}.tmp" "$packagelist"
            echo -e "\n • Package '$pkg' removed from system and list."
            read -rp " • Press Enter to continue..."
        else
            echo -e "\n • Package removal failed or canceled. List unchanged."
            read -rp " • Press Enter to continue..."
        fi
    else
        echo -e "\n • No package selected."
        sleep 1
    fi
}
purge_package() {
    typed_input=""
    pkg_to_remove=$(fzf --print-query \
        --preview='pacman -Qil {}' \
        --layout=reverse \
        --prompt="ESC to exit | Select Package(s) to purge: " \
        --preview-window=wrap:50% \
        < "$packagelist")
    typed_input=$(echo "$pkg_to_remove" | head -n1)
    selection=$(echo "$pkg_to_remove" | sed -n '2p')
    # Typing multiple packages detected by space inputs, they also take precedent
    if [[ "$typed_input" == *" "* ]]; then
        for pkg in $typed_input; do
            if ! grep -Fxq "$pkg" "$packagelist"; then
                echo -e "\n • Huh? You typed ('$pkg') but it's not in your installed list...\n"; sleep 2
                continue
            fi
            echo -e "\n • '$pkg' marked for removal...\n"
            case "$reviewmode" in
                "Review Changes")
                    paru -Rns "$pkg"
                    ;;
                "Skip Review" | "Only Show Progress")
                    paru -Rns --noconfirm "$pkg"
                    ;;
                *)
                    paru -Rns "$pkg"
                    ;;
            esac
            if [[ $? -eq 0 ]]; then
                grep -Fxv "$pkg" "$packagelist" > "${packagelist}.tmp" && mv "${packagelist}.tmp" "$packagelist"
                echo -e "\n • Package '$pkg' purged from system and list."
            else
                echo -e "\n • Package removal failed or canceled for '$pkg'."
            fi
        done
        read -rp " • Press Enter to continue..."
    elif [[ -n "$selection" ]]; then
        pkg="$selection"
        echo -e "\n • '$pkg' marked for removal...\n"
        case "$reviewmode" in
            "Review Changes")
                paru -Rns "$pkg"
                ;;
            "Skip Review" | "Only Show Progress")
                paru -Rns --noconfirm "$pkg"
                ;;
            *)
                paru -Rns "$pkg"
                ;;
        esac
        if [[ $? -eq 0 ]]; then
            grep -Fxv "$pkg" "$packagelist" > "${packagelist}.tmp" && mv "${packagelist}.tmp" "$packagelist"
            echo -e "\n • Package '$pkg' purged from system and list."
            read -rp " • Press Enter to continue..."
        else
            echo -e "\n • Package removal failed or canceled. List unchanged."
            read -rp " • Press Enter to continue..."
        fi
    else
        echo -e "\n • No package selected."
        sleep 1
    fi
}
install_list() {
    clear
    local packagelists preview_text choice selected_file
    mapfile -t packagelists < <(find "$config_dir" -maxdepth 1 -name "my_package_list*" -printf "%f\n" | sort)
    # Ensure the current one is always available
    if [[ ! " ${packagelists[*]} " =~ " my_package_list " ]]; then
        packagelists+=("my_package_list")
    fi
    preview_text=$(
        cat <<EOF
Paruse stores your currently installed packagelist in:
${yellowish}${HOME}/.config/paruse${nocolor}

Any backups made via:
${yellowish}Backup current package list${nocolor}
Are stored as:
${yellowish}packagelist-DateAndTime${nocolor}

Selecting a packagelist here will attempt to install (if not already installed)
all packages listed inside the file.
EOF
    )
    selected_file=$(printf "%s\n" "${packagelists[@]}" | \
        fzf --prompt="Select packagelist: " \
            --header="Choose a packagelist to install from" \
            --layout=reverse \
            --preview='echo -e "'"$preview_text"'" ; echo ; echo "File Content:" ; cat "'"$config_dir"'/"{}' \
            --preview-window=right:70%:wrap)

    if [[ -z $selected_file ]]; then
        return
    fi
    echo -e "\n • Using file: $selected_file"
    packagelist="$config_dir/$selected_file"
    echo -e "\n • Installing packages from: $packagelist\n"

    case "$reviewmode" in
        "Review Changes")
            paru -S --needed $(cat "$packagelist")
            ;;
        "Skip Review")
            paru -S --needed --skipreview --noconfirm $(cat "$packagelist")
            ;;
        "Only Show Progress")
            paru -S --needed --quiet --noconfirm --skipreview $(cat "$packagelist")
            ;;
        *)
            paru -S --needed $(cat "$packagelist")
            ;;
    esac
    echo
    read -rp " • Press Enter to continue..."
}
backup_package_list() {
    backup_file="${packagelist}-$(date +'%Y%m%d-%H%M%S')"
    cp "$packagelist" "$backup_file" && \
    echo -e "\n • Backup created: $backup_file" || \
    echo -e "\n • Backup failed..."
    sleep 2
}
fetch_news() {
    clear
    echo -e "\n • Fetching Arch Linux News..."
    paru -Pw
    read -rp " • Press Enter to continue..."
}
sync_package_list() {
    if [[ ! -s "$packagelist" ]]; then
        echo -e "\n • packagelist is empty or missing. Populating with installed packages..."
    else
        echo -e "\n • packagelist exists. Syncing installed packages..."
        rm -f "$packagelist"
    fi
    paru -Qqe | sort > "$packagelist"
    sleep 2
}

while true; do
    clear
    main_menu
done

