FROM ubuntu:16.04
# run as root
# RUN apt-get update -y && apt-get upgrade -y && apt-get install sudo -y
# Installing the Dependencies
RUN apt-get update && apt-get install ca-certificates curl openssh-server && apt-get install -y vim
# Move into the /tmp directory and then download the installation script
RUN cd /tmp && curl -LO https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh
# run the installer
RUN bash /tmp/script.deb.sh
# install the actual GitLab application
RUN apt-get install gitlab-ce
# Adjusting the Firewall Rules & verify with sudo ufw status
RUN ufw enable && ufw allow http && ufw allow https && ufw allow OpenSSH
# open Gitlab's configuration file
RUN vim /etc/gitlab/gitlab.rb

