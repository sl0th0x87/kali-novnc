FROM sl0th0x87/kali-basic:latest

LABEL maintainer="sl0th0x87@gmail.com"
LABEL description="Kali Linux with shellinabox"

## Connection ports for controlling the UI:
# VNC port:5901
# noVNC webport, connect via http://IP:6901/?password=vncpassword
ENV DISPLAY=:1 \
    VNC_PORT=5901 \
    NO_VNC_PORT=6901

EXPOSE $VNC_PORT $NO_VNC_PORT

USER root

### Envrionment config
ENV HOME=/headless \
    TERM=xterm \
    STARTUPDIR=/dockerstartup \
    NO_VNC_HOME=/headless/noVNC \
    DEBIAN_FRONTEND=noninteractive \
    VNC_COL_DEPTH=24 \
    VNC_RESOLUTION=1280x1024 \
    VNC_PW=vncpassword \
    VNC_VIEW_ONLY=false \
    LANG='en_US.UTF-8' \
    LANGUAGE='en_US:en' \
    LC_ALL='en_US.UTF-8'

WORKDIR $HOME

RUN apt-get update

RUN apt-get install -y \
    firefox-esr \
    gettext \
    libreoffice \
    libnss-wrapper \
    torbrowser-launcher \
    ttf-wqy-zenhei 

RUN apt-get install -y \
    bzip2 \
    curl \
    dnsutils \
    git \
    kali-desktop-xfce \
    locales \
    net-tools \
    openssh-client \
    openssl \
    python3-numpy \
    rsync \
    smbclient \
    supervisor \
    terminator \
    tmux \
    unzip \
    vim-nox \
    wget \
    whois 

RUN wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg && \
    install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/ && \
    echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list && \
    rm -f packages.microsoft.gpg && \
    apt-get -y install apt-transport-https && \
    apt-get update && \
    apt-get -y install code

### noVNC needs python2 and ubuntu docker image is not providing any default python
RUN test -e /usr/bin/python && rm -f /usr/bin/python ; ln -s /usr/bin/python3 /usr/bin/python

RUN apt-get purge -y pm-utils xscreensaver* && \
    apt-get -y clean

### Install xvnc-server & noVNC - HTML5 based VNC viewer
RUN mkdir -p $NO_VNC_HOME/utils/websockify && \
    wget -qO- https://netcologne.dl.sourceforge.net/project/tigervnc/stable/1.10.1/tigervnc-1.10.1.x86_64.tar.gz | tar xz --strip 1 -C / && \
    wget -qO- https://github.com/novnc/noVNC/archive/v1.3.0.tar.gz | tar xz --strip 1 -C $NO_VNC_HOME && \
    wget -qO- https://github.com/novnc/websockify/archive/v0.10.0.tar.gz | tar xz --strip 1 -C $NO_VNC_HOME/utils/websockify && \
    chmod +x -v $NO_VNC_HOME/utils/*.sh && \
    cp -f /headless/noVNC/vnc.html /headless/noVNC/index.html

### inject files
ADD ./src/xfce/ $HOME/
ADD ./src/scripts $STARTUPDIR

### configure startup and set perms
RUN echo "CHROMIUM_FLAGS='--no-sandbox --start-maximized --user-data-dir'" > $HOME/.chromium-browser.init && \
    /bin/sed -i '1 a. /headless/.bashrc' /etc/xdg/xfce4/xinitrc && \
    find $STARTUPDIR $HOME -name '*.sh' -exec chmod a+x {} + && \
    find $STARTUPDIR $HOME -name '*.desktop' -exec chmod a+x {} + && \
    chgrp -R 0 $STARTUPDIR $HOME && \
    chmod -R a+rw $STARTUPDIR $HOME && \
    find $STARTUPDIR $HOME -type d -exec chmod a+x {} + && \
    echo LANG=en_US.UTF-8 > /etc/default/locale && \
    locale-gen en_US.UTF-8

USER 1000

ENTRYPOINT ["/dockerstartup/desktop_startup.sh"]
CMD ["--wait"]
