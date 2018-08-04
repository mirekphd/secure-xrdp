FROM ubuntu:16.04

ARG xrdp_source=https://github.com/neutrinolabs/xrdp/releases/download/v0.9.3.1/xrdp-0.9.3.1.tar.gz
ARG xorgxrdp_source=https://github.com/neutrinolabs/xorgxrdp/releases/download/v0.2.3/xorgxrdp-0.2.3.tar.gz

# install packages
RUN apt-get update \
    && apt-get install --yes --force-yes --no-install-recommends \
        software-properties-common \
        xorg \
        xserver-xorg \
        xfce4 \
        gnome-themes-standard \
        gtk2-engines-pixbuf \
        file-roller \
        evince \
        gpicview \
        leafpad \
        xfce4-whiskermenu-plugin \
        ttf-ubuntu-font-family \
        dbus-x11 \
        vnc4server \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# build and install xrdp from source in one step (minimise size of container)
RUN apt-get update \
    && apt-get install --yes --force-yes --no-install-recommends \
        wget \
        build-essential \
        libssl-dev \
        libpam0g-dev \
        libxrandr-dev \
        nasm \
        xserver-xorg-dev \
        libxfont1-dev \
        pkg-config \
        file \
        libxfixes-dev \
    && cd /tmp \
    && wget --no-check-certificate $xrdp_source \
    && tar -xf xrdp-*.tar.gz -C /tmp/ \
    && cd /tmp/xrdp-* \
    && ./configure \
    && make \
    && make install \
    && cd /tmp \
    && rm -rf xrdp-* \
    && wget --no-check-certificate $xorgxrdp_source \
    && tar -xf xorgxrdp-*.tar.gz -C /tmp/ \
    && cd /tmp/xorgxrdp-* \
    && ./configure \
    && make \
    && make install \
    && cd /tmp \
    && rm -rf xorgxrdp-* \
    && apt-get remove --yes --force-yes \
        wget \
        build-essential \
        libssl-dev \
        libpam0g-dev \
        libxrandr-dev \
        nasm \
        xserver-xorg-dev \
        libxfont1-dev \
        pkg-config \
        file \
        libxfixes-dev \
    && apt-get --yes autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# install theme
RUN add-apt-repository ppa:numix/ppa \
    && apt-get update \
    && apt-get install --yes --force-yes --no-install-recommends numix-icon-theme numix-icon-theme-circle \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# add the customised files
ADD ubuntu-files/lightdm-gtk-greeter.conf /etc/lightdm/lightdm-gtk-greeter.conf
ADD ubuntu-files/Adwaita-Xfce /usr/share/themes/Adwaita-Xfce
ADD ubuntu-files/xfce-perchannel-xml /etc/xdg/xfce4/xfconf/xfce-perchannel-xml
RUN mkdir -p /usr/share/backgrounds
ADD ubuntu-files/background-default.png /usr/share/backgrounds/background-default.png
RUN ln -s /usr/share/icons/Numix-Circle /usr/share/icons/KXicons

# add the user
RUN useradd --create-home user
RUN echo "user:changeme" | chpasswd

# add the keyboard maps
COPY keymaps /etc/xrdp/


# initialize and grant user ownership to the xrdp log file
RUN touch /var/log/xrdp.log && \
    chown user /var/log/xrdp.log

# initialize and grant user ownership to the xrdp-sesman log file
RUN touch /var/log/xrdp-sesman.log && \
    chown user /var/log/xrdp-sesman.log

# grant user ownership to the xrdp certificate
RUN chown user /etc/xrdp/cert.pem && \
    chown user /etc/xrdp/key.pem

# grant user ownership to the entire /var/run folder,
# where xrdp.pid will be created at run time
# (note that we cannot initialize this file in advance,
# as this would prevent new session from starting)
RUN chown -R user /var/run/

# grant user ownership to the entire /etc/xrdp/ folder
RUN chown -R user /etc/xrdp/

# # grant user ownership to the entire /etc/X11/xrdp folder
# RUN chown -R user /etc/X11/xrdp
# grant user ownership to the entire /etc/X11 folder
RUN chown -R user /etc/X11/

# grant user ownership to the entire /usr/share/X11 folder
RUN chown -R user /usr/share/X11

# allow all users to use Xorg X server
# and make it drop its default root rights
# (see Xwrapper.config (5) - Linux Man Pages)
RUN echo "allowed_users=anybody" >> /etc/X11/Xwrapper.config && \
    echo "needs_root_rights=no" >> /etc/X11/Xwrapper.config
# grant user ownership to Xwrapper.config
RUN chown user /etc/X11/Xwrapper.config 

# replace the default log file location from the /root folder 
# with a user-editable location (~/ folder)
# sed -i -e 's/old/new/g' file.txt
RUN sed -i "s/.xorgxrdp.10.log//tmp/.xorgxrdp.10.log/g" /etc/xrdp/sesman.ini

# # initialize xrdp.pid file and grant ownership to the user
# RUN touch /var/run/xrdp.pid && \
#     chown user /var/run/xrdp.pid


ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT /entrypoint.sh
