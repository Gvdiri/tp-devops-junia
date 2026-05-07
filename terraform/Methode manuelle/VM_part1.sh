#Code permettant d'utiliser la commande "VBoxManage" dans les scripts tout en utilisant la version windows de virtualbox
shopt -s expand_aliases
alias VBoxManage='/mnt/c/Program\ Files/Oracle/VirtualBox/VBoxManage.exe'

#Création d'une nouvelle VM ayant les caractéristiques demandées
if [[ -z $(VBoxManage list vms | grep "VM_part1") ]]; then
    #Si la VM n'existe pas
    VBoxManage createvm -name "VM_part1" --ostype "Debian_64" --register
else
    echo "Machine virtuelle déjà créée"
fi

#On vérifie si la VM est en fonctionnement avant de la modifier
#Si elle est en fonctionnement, alors on l'éteind d'abord puis on la modifie
if [[ -n $(VBoxManage list runningvms | grep "VM_part1") ]]; then
    #La VM est en fonctionnement, alors on l'éteint
    VBoxManage controlvm "VM_part1" poweroff
fi

VBoxManage modifyvm "VM_part1" --cpus 1 --memory "1000"

#Création d'un disque virtuel de 25Go si ce n'est pas déja fait
if [[ -z $(VBoxManage list hdds | grep -F "disque_VM.vdi") && ! -f "disque_VM.vdi" ]]; then
    VBoxManage createmedium disk --filename "disque_VM.vdi" --size 25000 --format VDI
    echo "Disque créé"
else
    echo "Disque déjà créé"
fi

#Création d'un contrôleur SATA permettant d'attacher les disques à la VM
if [[ -z $(VBoxManage showvminfo "VM_part1" | grep "SATA Controller") ]]; then
    VBoxManage storagectl "VM_part1" --name "SATA Controller" --add sata
else
    echo "Contrôleur SATA déjà créé"
fi


#Attachement du disque de stockage à la VM
VBoxManage storageattach "VM_part1" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "disque_VM.vdi"
echo "Disque attaché"

#Attachement du fichier .iso à la VM
VBoxManage storageattach "VM_part1" --storagectl "SATA Controller" --port 1 --device 0 --type dvddrive --medium "debian-13.3.0-amd64-netinst.iso"
echo "Fichier .iso attaché"

#Configuration de l'ordre de démarrage de la VM (le disque est booté en premier, ensuite c'est le tour du disque de stockage)
VBoxManage modifyvm "VM_part1" --boot1 dvd --boot2 disk --boot3 none --boot4 none
echo "Ordre de boot configuré"

VBoxManage startvm "VM_part1"


