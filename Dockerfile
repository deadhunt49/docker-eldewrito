# Pull ubuntu image
FROM ubuntu:24.04

# Set environment variables
ENV CONTAINER_VERSION=1.3 \
    ELDEWRITO_VERSION=0.7.1 \
    MTNDEW_CHECKSUM=f1d6c49381ac1ec572f0f405e4cd406b \
    DISPLAY=:1 \
    WINEPREFIX="/wine" \
    DEBIAN_FRONTEND=noninteractive \
    RUN_AS_USER=1 \
    PUID=1000 \
    PGID=1000

# Install temporary packages
RUN apt-get update && \
    apt-get install -y wget software-properties-common apt-transport-https cabextract

# Install Wine key and repository
RUN dpkg --add-architecture i386 && \
    wget -nc https://dl.winehq.org/wine-builds/winehq.key && \
    apt-key add winehq.key && \
    rm winehq.key && \
    add-apt-repository 'deb https://dl.winehq.org/wine-builds/ubuntu/ noble main' && \
    apt-get update

# Install Wine stable
#RUN apt-get install -y --install-recommends winehq-stable
# Install Wine staging
RUN apt-get install -y --install-recommends winehq-staging

# Download winetricks from source
RUN wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks && \
    chmod +x ./winetricks

# Install X virtual frame buffer and winbind
RUN apt-get install -y xvfb winbind

# Configure wine prefix
# WINEDLLOVERRIDES is required so wine doesn't ask any questions during setup
RUN Xvfb :1 -screen 0 320x240x24 & \
    WINEDLLOVERRIDES="mscoree,mshtml=" wineboot -u && \
    wineserver -w && \
    ./winetricks -q vcrun2012 winhttp

#Install libvulkan and libgll
RUN apt-get install -y libvulkan1:i386 && \
    apt-get install -y libgl1:i386

# Cleanup
RUN apt-get remove -y wget software-properties-common apt-transport-https cabextract && \
    rm -rf /var/lib/apt/lists/* && \
    rm winetricks && \
    rm -rf .cache/

# Add the start script
ADD start.sh .

# Add the default configuration files
ADD defaults defaults

# Make start script executable and create necessary directories
RUN chmod +x start.sh && \
    mkdir config logs

# Set start command to execute the start script
CMD ["/start.sh"]

# Set working directory into the game directory
WORKDIR /game

# Expose necessary ports
EXPOSE 11774/udp 11775/tcp 11776/tcp 11777/tcp

# Set volumes
VOLUME /game
