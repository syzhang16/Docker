# utilisation de Gogs pour des repertoires git privé
# Gogs est un service git ecrit en langage Go d'ou le golang
# il permet de lancer autant de repertoires git prives que le serveur peut supporter 
# facile et leger
FROM golang:latest
# creation d'un utilisateur git
# --gecos specifie le nom de l'utilisateur
# --disabled-login n'utilise pas passwd pour fixer le mot de passe. L'utilisateur ne pourra pas utiliser son compte avant que son mot de passe soit donné.
RUN adduser --disabled-login --gecos 'Gogs' git
# installer base donnes mysql, lancer le service mysql et se connecter en root
RUN apt-get update && apt-get install mysql-server -y \
    && service mysql start && mysql -u root -e "create database gogs"
# se connecter en tant que git
USER git
# creer le repertoire parent, aller dedans, cloner les dependances de go et pointer le tout dans un dossier gogs, aller dans gogs et lancer gogs
RUN mkdir -p $GOPATH/src/github.com/gogits \
	&& cd $GOPATH/src/github.com/gogits \
	&& git clone --depth=1 -b develop https://github.com/gogits/gogs \
	&& cd gogs && go build
# lancer l'interface web
CMD cd $GOPATH/src/github.com/gogits/gogs && ./gogs web
