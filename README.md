# Arch packages
  
To install .list file using pkmgr:  

```shell
pkmgr curl https://github.com/pkmgr/debian/raw/main/lists/default.list
```

To install .sh script using pkmgr  

```shell
pkmgr script https://github.com/pkmgr/debian/raw/main/scripts/default.sh
```  

use the following format to manual install:  

```shell
sudo pacman -S $(cat pkglist.txt )
```
