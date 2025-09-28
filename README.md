add a cache file to speed up the "add/browse package"

add an option to update the cache

remove the sleep 2 secs if no package is selected.



<div align="center">

# Paruse

###### . . . An Interactive Package Management Tool for Arch Linux

</div>

## Overview

Paruse uses [paru](https://github.com/Morganamilo/paru) & [fzf](https://github.com/junegunn/fzf) to manage "goto" task centered around packages. It can browse Arch|Aur Repositories in real-time, filtering by package type, and searching through packages <ins>while you type</ins>. Install|Uninstall|Purge operations can be done for single packages or batch (multiple input). Packagelist are synced and can be backed up and restored from packagelist & packagelist-date&time files found in 📂 `~/.config/paruse`. Updating system, cleaning cache, viewing Arch News, are a couple of other things present in the Paruse Menu. Interaction is not limited to keyboard, you can click through menus, and click to make selections. Also only ~20Kib if that matters.

> As of 0.5: When browsing/hovering an aur package, its pkgbuild and source tree are displayed along side package details.

## Install

```
paru -S paruse
```
```
git clone https://github.com/soulhotel/paruse.git
```
> To summon paruse, type `paruse` in a terminal or launch it via your favorite app launcher. Git installations can use the .desktop file provided in 📂 `paruse/pkg/`

## Preview

> Browsing Installed Packages

<img src="https://github.com/user-attachments/assets/bdc6f812-faa4-4c1e-a339-8c940311e13c" width="90%"/>

> Browsing Arch/Aur Repo's

<img src="https://github.com/user-attachments/assets/6ba5d42e-1a2d-49c0-a566-7837d6cbdba3" width="90%"/>

> Installing multiple packages

<img src="https://github.com/user-attachments/assets/7d91bfd8-6d11-4fb5-92c6-1138bb1ce8f1" width="90%"/>

> Managing packagelist backups

<img src="https://github.com/user-attachments/assets/6f73d3ac-bef4-4f00-ba0a-e0f234756cad" width="90%"/>

> See a [video demonstration](https://www.youtube.com/watch?v=wn6xwm3MdTU) (on youtube).

![Alt](https://repobeats.axiom.co/api/embed/306c2676dea1251899cdbc25b5b154add696a846.svg "Repobeats analytics image")
