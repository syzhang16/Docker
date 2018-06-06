FROM debian
ADD http://dl.4players.de/ts/releases/3.0.13.6/teamspeak3-server_linux_amd64-3.0.13.6.tar.bz2 ./
RUN export DEBIAN_FRONTEND=noninteractive \
  && apt-get update \
  && apt-get upgrade -y\
  && apt-get install -y apt-utils bzip2 \
  && mv teamspeak3-server_linux_amd64 /opt/teamspeak
RUN useradd teamspeak && mkdir -p /opt/teamspeak/data && chown teamspeak:teamspeak /opt/teamspeak/data
# creer un point de montage
VOLUME ["/opt/teamspeak/data"]
# permettre d'ecouter sur les ports
EXPOSE 9987/udp
EXPOSE 30033
EXPOSE 10011
# indique le repertoire dans lequel on travaille
WORKDIR /opt/teamspeak
# indique user
USER teamspeak
#serveur qui se lancera au démarrage de votre container
CMD /opt/teamspeak/ts3server_minimal_runscript.sh start
#  pour tester
# docker run  -d --publish=9987:9987/udp --publish=30033:30033/tcp --publish=10011:10011/tcp --name teamspeakprout teamspeak
