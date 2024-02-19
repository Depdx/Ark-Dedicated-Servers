FROM ubuntu:14.04

# Var for first config
# Server Name
ENV SESSIONNAME "Ark Docker"
# Map name
ENV SERVERMAP "TheIsland"
# Server password
ENV SERVERPASSWORD "12456"
# Admin password
ENV ADMINPASSWORD "12456"
# Nb Players
ENV NBPLAYERS 70
# If the server is updating when start with docker start
ENV UPDATEONSTART 1
# if the server is backup when start with docker start
ENV BACKUPONSTART 1

# Server PORT (you can't remap with docker, it doesn't work)
ENV SERVERPORT 27015
# Steam port (you can't remap with docker, it doesn't work)
ENV GAMECLIENTPORT 7777
ENV STEAMPORT 7778
# if the server should backup after stopping
ENV BACKUPONSTOP 0
# If the server warn the players before stopping
ENV WARNONSTOP 0
# UID of the user steam
ENV UID 1000
# GID of the user steam
ENV GID 1000
# Cluster ID
ENV CLUSTERID "cluster_1"

# Install dependencies 
RUN apt-get update &&\ 
    apt-get install -y curl lib32gcc1 lsof git util-linux sudo cron

# Enable passwordless sudo for users under the "sudo" group
RUN sed -i.bkp -e \
	's/%sudo\s\+ALL=(ALL\(:ALL\)\?)\s\+ALL/%sudo ALL=NOPASSWD:ALL/g' /etc/sudoers \
	/etc/sudoers

# Run commands as the steam user
RUN adduser \ 
	--disabled-login \ 
	--shell /bin/bash \ 
	--gecos "" \ 
	steam
# Add to sudo group
RUN usermod -a -G sudo steam

# Copy & rights to folders
COPY run.sh /home/steam/run.sh
COPY user.sh /home/steam/user.sh
COPY crontab /home/steam/crontab
COPY arkmanager-user.cfg /home/steam/arkmanager.cfg

RUN touch /root/.bash_profile
RUN chmod 777 /home/steam/run.sh
RUN chmod 777 /home/steam/user.sh
RUN mkdir  /ark


# We use the git method, because api github has a limit ;)
RUN  git clone https://github.com/Depdx/ark-server-tools /home/steam/ark-server-tools
WORKDIR /home/steam/ark-server-tools/

# Install 
WORKDIR /home/steam/ark-server-tools/tools
RUN chmod +x install.sh 
RUN ./install.sh steam 

# Allow crontab to call arkmanager
RUN ln -s /usr/local/bin/arkmanager /usr/bin/arkmanager

# Define default config file in /etc/arkmanager
COPY arkmanager-system.cfg /etc/arkmanager/arkmanager.cfg

# Define default config file in /etc/arkmanager
COPY instance.cfg /etc/arkmanager/instances/main.cfg

RUN chown steam -R /ark && chmod 755 -R /ark

# Install steamcmd
RUN mkdir -p /home/steam/steamcmd
RUN curl -s "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" -o "/home/steam/steamcmd/steamcmd_linux.tar.gz"
RUN tar -xzf "/home/steam/steamcmd/steamcmd_linux.tar.gz" -C "/home/steam/steamcmd"
ENV PATH="/home/steam/steamcmd:${PATH}"

EXPOSE ${STEAMPORT} 32330 ${SERVERPORT} ${GAMECLIENTPORT}
# Add UDP
EXPOSE ${STEAMPORT}/udp ${SERVERPORT}/udp ${GAMECLIENTPORT}/udp

VOLUME  /ark

# Change the working directory to /arkd
WORKDIR /ark

# Update game launch the game.
ENTRYPOINT ["/home/steam/user.sh"]
