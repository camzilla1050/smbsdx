#!/bin/bash

SRV=smbd
PRODUCT="Product Name"  # Ex: Samsung
ID_DRV="id drive" # Ex: 059f:1014
LK_DRV="Your moint point" # Ex: /mnt/hdd1  


# Fonction : 1. Vérif si le device est réconnu sur /dev/sdX. 2. Monter le périph. 3. Démarrer le service 
#	Arguments: $1=Service; $2=Lien de montage  

function allumer(){
#	Teste si le fichier /dev/sdX existe
sdXn=$(ls -la /dev | grep "sd[a-c][1]" | cut -d':' -f2 | cut -d' ' -f2); 
sdX=${sdXn:0:3}

#	Teste si /dev/sdX existe : test -e 
#	From Source: https://linuxize.com/post/bash-check-if-file-exists/

if test -e "/dev/$sdX"; 
	then sudo mount /dev/$sdXn $2; echo "Votre périphérique "$sdXn" est monté";
	if test -e "$(df -H | grep /dev/$sdXn | cut -d' ' -f16)"; 
		then sudo systemctl start $1; echo "Félicitations, votre système est démarré."; 
		else echo "Désolé, il y a un problème avec le service."; 
	fi
fi
}

# Fonction : 1. Eteindre le service;2. Démonter le disque;
# Argumets: $1=Service, $2=Lien du périphérique à démonter  

function etteindre(){
	# info// echo "eteindre le service + démonter";
	sudo systemctl stop $1 
#		Vérif si le service est éteint ALORS Démonter le périph.	
		if [[ $(systemctl status $S1 | grep Active | cut -d' ' -f6) != '(running)' ]]; 
			then sudo umount $2 ; 
#			Vérif si le périph a été correctement démonté:
			if [ $(df -H | grep $2 | wc -l) -eq 1 ]
				then echo "Désolé, le périph. "$2" n'a pas été correctement démonté.";
				else echo "Ok, le périph "$2" a été correctement démonté."
			fi
		fi
}

#	Fonction employant 2 Arguments $1 $2 - fait appel à la fonction systatus
#-->> Ci-dessous, éxecute les fonctions.

#			Tableau d'entrée

#	Statement	  A	| B	
#				 _______
#	Eteint/ RàF	| 0	| 0	|
#	Allumer()	| 0	| 1	|
#	Eteindre()	| 1	| 0	|
#	Allumé/ RàF	| 1	| 1	|


# Vérifier l'état du périph.
# Argumments: $1=Service; $2=Point de montage sdX; $3=retour sur l état du drive ON ou OFF
function boucler() {

#       Condition : détecter si le périphérique est présent --> avec commande "lusb"
if [[ $(lsusb | grep $3 | cut -d' ' -f6) = $4 ]] ; then drv="on"; else drv="off"; fi;

#	Si le périphérique est présent dans /dev/sdX - selon le retour de la variable $drv
if [ $drv = 'on' ]
	then
		# Vérifier si le service smbd tourne + Vérifier si le périph. est toujours monté  /dev/sdXx.
		if [[ $(systemctl status $1 | grep Active | cut -d' ' -f6) == '(running)' && "$(df -H | grep /dev/$5 | cut -d' ' -f16)" ]]
			then value="Rien à faire. Le service tourne correctement." # ALORS Ici on continue. Tableau d entrée -> Allumé donc RàF 	| 1	| 1	|
			else allumer $1 $2; value="Bonjour, le service sera démarré dans quelques instants..."  # SINON on allume le tout 					Allumer()	| 0	| 1	|
		fi
	elif [[ $(systemctl status $1 | grep Active | cut -d' ' -f6) == '(running)' && "$(df -H | grep /dev/$5 | cut -d' ' -f16)" ]];
		then value="Au revoir, le service va fermer dans quelques instants..."; 
			etteindre $1 $2; # SINON Etteindre()	| 1	| 0	|
		else value="Rien à faire. Le service est fermé."; # AUTREMENT OFF càd que dans l état du Tableau d entrée -> Eteint/ RàF	| 0	| 0	|
fi; 
echo "état du périphérique "$3" : "$value
}


##--> Boucle de lancement du script

while :
	do
		boucler $SRV $LK_DRV $PRODUCT $ID_DRV
		sleep 10
	done
