<div align="center">

# Paruse

###### . . . An Interactive Package Management Tool for Arch Linux

</div>

## Overview

#### Paruse uses [paru](https://github.com/Morganamilo/paru) & [fzf](https://github.com/junegunn/fzf) to manage "goto" task centered around packages.
- You can browse Arch Repos in real-time, filter through packages <ins>**while you type**</ins> (not, after pressing `Enter`)
- You can manage install/uninstall/purge, one package or multiple
- Backup/restore packagelist, update system, clean cache, view Arch news, and a couple of other things
- Interaction is not limited to keyboard, you can click through menus, and click to make selections.

#### To use it paruse.. Download it from aur or git, and run paruse.
- Type `paruse` in a terminal
- Or launch `Paruse` via your favorite app launcher.
- Git installations can use the .desktop file provided in 📂 `paruse/pkg/`
```
paru -S paruse
```
```
git clone https://github.com/soulhotel/paruse.git
```

> No paru operations are suppressed, meaning intervention in a paru/pacman operation is as-is, paruse simply presents all information via fzf and passes it along to paru.

## Preview

> Browsing Installed Packages

<img src="https://github.com/user-attachments/assets/bdc6f812-faa4-4c1e-a339-8c940311e13c" width="90%"/>

> Browsing Arch/Aur Repo's

<img src="https://github.com/user-attachments/assets/6ba5d42e-1a2d-49c0-a566-7837d6cbdba3" width="90%"/>

> Installing multiple packages

<img src="https://github.com/user-attachments/assets/7d91bfd8-6d11-4fb5-92c6-1138bb1ce8f1" width="90%"/>

> Managing packagelist backups

<img src="https://github.com/user-attachments/assets/6f73d3ac-bef4-4f00-ba0a-e0f234756cad" width="90%"/>




