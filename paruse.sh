#!/bin/bash

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
    mkdir -p "$config_dir"
fi
if [[ ! -s "$packagelist" ]]; then
    echo " • • • packagelist is empty or missing. Populating with installed packages..."
    paru -Qqe | sort > "$packagelist"
    sleep 4
fi

# interactive process
while true; do
    clear
    echo -e "\n• • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • \n"
    echo -e " Paruse: Package Management for packages that you just can't live without\n"
    echo -e " View Mode: \e[34m$viewmode\e[0m"
    echo -e " Review Mode: \e[34m$reviewmode\e[0m"
    echo
    echo " 1 • View package list"
    echo " 2 • Add package"
    echo " 3 • Remove package"
    echo " 4 • Purge package"
    echo " 5 • Install full package list"
    echo
    echo " v • Toggle view mode"
    echo " r • Toggle review mode"
    echo " u • Update system packages"
    echo " s • Sync current package list"
    echo " b • Backup current package list"
    echo " a • Set a custom bash_alias for Paruse"
    echo " q • Press q, Q, or Enter to exist"
    echo -e "\n• • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • \n"
    read -rp $'\n Pick a number, any number: ' choice

    case $choice in
        u|U)
            echo && paru -Syu
            echo && read -rp " • Press Enter to continue..."
            ;;
        s|S)
            if [[ ! -s "$packagelist" ]]; then
                echo -e "\n • packagelist is empty or missing. Populating with installed packages..."
            else
                echo -e "\n • packagelist exists. Syncing installed packages..."
                rm -f "$packagelist"
            fi
            paru -Qqe | sort > "$packagelist"
            sleep 2
            ;;
        b)
            backup_file="${packagelist}-$(date +'%Y%m%d-%H%M%S')"
            cp "$packagelist" "$backup_file" && \
            echo -e "\n • Backup created: $backup_file" || \
            echo -e "\n • Backup failed..."
            sleep 2
            ;;
        v|V)
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
            ;;
        r|R)
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
            ;;
        1)
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
            ;;

        2)
            echo -e "\n • Loading Repo(s)..." && parusing="$config_dir/parusing"
            comm -23 <(paru -Slq | sort) <(paru -Qq | sort) | sed 's/$//' > "$parusing"
            comm -12 <(paru -Slq | sort) <(paru -Qq | sort) | sed 's/$/ (installed)/' >> "$parusing"
            sort "$parusing" -o "$parusing"

            pkg_to_add=$(fzf --print-query --no-multi --prompt="Add package: " \
                --preview='paru -Si $(echo {} | sed "s/ (installed)//")' \
                --layout=reverse \
                --preview-window=wrap:50% \
                < "$parusing")

            pkg_to_add=$(echo "$pkg_to_add" | head -n1 | sed 's/ (installed)//')

            if [[ -z "$pkg_to_add" ]]; then
                echo -e "\n • No package name entered."
                sleep 2
            elif grep -Fxq "$pkg_to_add" "$packagelist"; then
                echo " • Package '$pkg_to_add' is already in the list."
                sleep 2
            else
                echo -e "\n • '$pkg_to_add' marked for installation...\n"
                case "$reviewmode" in
                    "Review Changes")
                        paru -S --needed "$pkg_to_add"
                        ;;
                    "Skip Review")
                        paru -S --needed --skipreview --noconfirm "$pkg_to_add"
                        ;;
                    "Only Show Progress")
                        paru -S --needed --quiet --noconfirm "$pkg_to_add"
                        ;;
                    *)
                        paru -S --needed "$pkg_to_add"
                        ;;
                esac
                if [[ $? -eq 0 ]]; then
                    echo "$pkg_to_add" >> "$packagelist"
                    echo -e "\n • Package '$pkg_to_add' installed and added to list."
                    read -rp " • Press Enter to continue..."
                else
                    echo -e "\n • Installation failed or canceled. Nothing added to list."
                    read -rp " • Press Enter to continue..."
                fi
            fi
            ;;
        3)
            pkg_to_remove=$(fzf < "$packagelist" \
                --preview='pacman -Qil {}' \
                --layout=reverse \
                --prompt="ESC to exit | Enter/DBL-Click a package to remove: " \
                --preview-window=wrap:50%)

            if [[ -n "$pkg_to_remove" ]]; then
                echo -e "\n • '$pkg_to_remove' marked for removal...\n"
                case "$reviewmode" in
                    "Review Changes")
                        paru -R "$pkg_to_remove"
                        ;;
                    "Skip Review")
                        paru -R --noconfirm "$pkg_to_remove"
                        ;;
                    "Only Show Progress")
                        paru -R --noconfirm "$pkg_to_remove"
                        ;;
                    *)
                        paru -R "$pkg_to_remove"
                        ;;
                esac

                if [[ $? -eq 0 ]]; then
                    grep -Fxv "$pkg_to_remove" "$packagelist" > "${packagelist}.tmp" && mv "${packagelist}.tmp" "$packagelist"
                    echo -e "\n • Package '$pkg_to_remove' removed from system and list."
                    read -rp " • Press Enter to continue..."
                else
                    echo -e "\n • Package removal failed or canceled. List unchanged."
                    read -rp " • Press Enter to continue..."
                fi
            else
                echo -e "\n • No package selected."
                sleep 2
            fi
            ;;
        4)
            pkg_to_remove=$(fzf < "$packagelist" \
                --preview='pacman -Qil {}' \
                --layout=reverse \
                --prompt="ESC to exit | Enter/DBL-Click a package to purge: " \
                --preview-window=wrap:50%)

            if [[ -n "$pkg_to_remove" ]]; then
                echo -e "\n • '$pkg_to_remove' marked for removal...\n"
                case "$reviewmode" in
                    "Review Changes")
                        paru -Rns "$pkg_to_remove"
                        ;;
                    "Skip Review")
                        paru -Rns --noconfirm "$pkg_to_remove"
                        ;;
                    "Only Show Progress")
                        paru -Rns --noconfirm "$pkg_to_remove"
                        ;;
                    *)
                        paru -Rns "$pkg_to_remove"
                        ;;
                esac
                if [[ $? -eq 0 ]]; then
                    grep -Fxv "$pkg_to_remove" "$packagelist" > "${packagelist}.tmp" && mv "${packagelist}.tmp" "$packagelist"
                    echo -e "\n • Package '$pkg_to_remove' removed from system and list."
                    read -rp " • Press Enter to continue..."
                else
                    echo -e "\n • Package removal failed or canceled. List unchanged."
                    read -rp " • Press Enter to continue..."
                fi
            else
                echo -e "\n • No package selected."
                sleep 2
            fi
            ;;
        5)
            clear
            backup_files=("$config_dir/my_package_list"-*)
            if [[ ${backup_files[0]} == "my_package_list_*" ]]; then
                backup_files=()
            fi
            if [[ ${#backup_files[@]} -gt 0 ]]; then
                echo -e "\n Multiple packagelists found:\n"
                for i in "${!backup_files[@]}"; do
                    echo "$((i+1))) ${backup_files[i]}"
                done
                echo "$(( ${#backup_files[@]} + 1 ))) Use current packagelist"
                echo "$(( ${#backup_files[@]} + 2 ))) Cancel"
                echo
                read -rp " Choose a packagelist to install everything from: " choice
                if (( choice >= 1 && choice <= ${#backup_files[@]} )); then
                    selected_file="${backup_files[choice-1]}"
                    echo -e "\n • Using backup file: $selected_file"
                    packagelist="$selected_file"
                elif (( choice == ${#backup_files[@]} + 1 )); then
                    echo -e "\n • Using current packagelist."
                else
                    echo -e "\n • Cancelled."
                    sleep 2
                fi
            else
                echo
            fi
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
            if [[ $? -eq 0 ]]; then
                echo -e "\n Installation complete." && read -rp " • Press Enter to continue..."
            else
                echo -e "\n • Installation failed or canceled." && read -rp " • Press Enter to continue..."
            fi
            ;;
        a)
            echo -e "\n • Set a custom bash alias for Paruse Package Management. This lets you open a terminal and type your alias (e.g. paruse) to run this menu."
            echo -ne "\n • Enter a custom alias: "
            read -r user_alias
            script_path="$(readlink -f "$0")"
            if [[ -z "$user_alias" ]]; then
                echo -e "\n • Canceled..."
                sleep 2
            else
                alias_line="alias $user_alias='$script_path'"
                alias_file="$HOME/.bash_aliases"
                if [[ ! -f "$alias_file" ]]; then
                    alias_file="$HOME/.bashrc"
                fi
                if grep -Fxq "$alias_line" "$alias_file"; then
                    echo -e "\n • Alias '$user_alias' already exists in $alias_file"
                    sleep 3
                else
                    echo "$alias_line" >> "$alias_file"
                    echo -e "\n • Alias added to $alias_file"
                    echo -e "   Please reload your shell or run 'source $alias_file' to activate the alias."
                    sleep 4
                fi
            fi
            ;;
        q|Q|'')
            echo -e "\n Cya next time"
            sleep 2
            exit
            ;;
        *)
            echo -e "\n...Try again."
            sleep 2
            ;;
    esac
done

