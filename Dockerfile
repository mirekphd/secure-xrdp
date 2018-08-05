FROM ubuntu:16.04

# use non-interactive install model
ENV DEBIAN_FRONTEND noninteractive


#################################################################################################################
#   ACCOUNT SETUP
#################################################################################################################

# set up user name and password
ENV USER_NAME=rstudio
ENV USER_PASS=rstudio

# set up temporary user ID 
# note it will be changed at run time by the 'uid_entrypoint.sh' 
# script to allow running under OpenShift 
ENV MY_UID=1000

# set up group ID to 0
# caution: setting group to 0 is essential 
# for /tmp/rstudio-rsession/rstudio-d to be created,
# avoiding "ERROR system error 13 (Permission denied) 
# [path=/home/rstudio/.rstudio, target-dir=]" error 
# and "Unable to connect to service" error message after logon;
# NOTE: group 0 carries NO special priviledges, unlike uid 0
# ENV MY_GID=0
ENV MY_GID=0

# set up home folder and add it to path
# ENV HOME=/opt/app-root
ENV HOME=/home/${USER_NAME}
ENV PATH=${HOME}:${PATH}

# add user
RUN useradd -m -d $HOME -u ${MY_UID} -G ${MY_GID} ${USER_NAME}

# set user password 
RUN echo ${USER_NAME}:${USER_PASS} | chpasswd

# change ownership of the home folder
RUN chown ${USER_NAME}:${MY_GID} /home/${USER_NAME}

# set up user for build execution and application runtime
RUN chgrp -R ${MY_GID} ${HOME} && \
    # copy user permissions to group 
    # for home folder and /etc/passwd 
    chmod -R g=u ${HOME} && \
    chmod -R g=u /etc/passwd

# # create the user
# RUN useradd --create-home user

# # set user password
# RUN echo "user:changeme" | chpasswd


#################################################################################################################
#   SHELL
#################################################################################################################

# Configure bash
RUN ln -sf /bin/bash /bin/sh
ENV SHELL=/bin/bash



#################################################################################################################
#   LOCALE
#################################################################################################################

# caution: not configuring locale will lead to dependency problems (errors during package installations)

# prior to setting locale (e.g. LC_ALL=), it has to be generated 
# because en_US locales are not available in Ubuntu by default
RUN apt-get update && apt-get install -y locales && \
	locale-gen en_US.UTF-8 

ENV LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8
    
    
#################################################################################################################
#   UPDATE UBUNTU
#################################################################################################################

# Install essential OS dependencies for building the docker image     

# install Ubuntu packages:    
# - dependencies/utils first
RUN apt-get update && \
    apt-get install -y --fix-missing \
        build-essential \
        git \
        evince \
	file \
        file-roller \
        gpicview \
        htop \
        libpam0g-dev \
	libssl-dev \
	libxfixes-dev \
	libxfont1-dev \
        libxrandr-dev \
        leafpad \
        mc \
        nano \
	nasm \
	pkg-config \
        software-properties-common \
        ttf-ubuntu-font-family \
	udev \	
        wget && \ 
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# - graphical desktop environment second
RUN apt-get update && \
    apt-get install -y --fix-missing \
        dbus-x11 \
        gnome-themes-standard \
	gtk2-engines-pixbuf \
        vnc4server \
        xfce4 \
        xfce4-whiskermenu-plugin \
        xorg \
        xserver-xorg \
	xserver-xorg-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


#################################################################################################################
#   XRDP
#################################################################################################################

ARG XRDP_VER=0.9.7
ARG XORGXRDP_VER=0.2.7

ARG XRDP_URL=https://github.com/neutrinolabs/xrdp/releases/download/v${XRDP_VER}/xrdp-${XRDP_VER}.tar.gz
ARG XORGXRDP_URL=https://github.com/neutrinolabs/xorgxrdp/releases/download/v${XORGXRDP}/xorgxrdp-${XORGXRDP}.tar.gz

# build and install xrdp from source
RUN apt-get update \
    && cd /tmp \
    && wget --quiet --no-check-certificate ${XRDP_URL} \
    && tar -xf xrdp-*.tar.gz -C /tmp/ \
    && cd /tmp/xrdp-* \
    && ./configure \
    && make \
    && make install \
    && cd /tmp \
    && rm -rf xrdp-* \
    && apt-get --yes autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# build and install xorgxrdp from source
RUN apt-get update \
    && wget --quiet --no-check-certificate ${XORGXRDP_URL} \
    && tar -xf xorgxrdp-*.tar.gz -C /tmp/ \
    && cd /tmp/xorgxrdp-* \
    && ./configure \
    && make \
    && make install \
    && cd /tmp \
    && rm -rf xorgxrdp-* \
    && apt-get --yes autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# install theme
RUN add-apt-repository ppa:numix/ppa \
    && apt-get update \
    && apt-get install -y numix-icon-theme numix-icon-theme-circle \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# add the customised files
ADD ubuntu-files/lightdm-gtk-greeter.conf /etc/lightdm/lightdm-gtk-greeter.conf
ADD ubuntu-files/Adwaita-Xfce /usr/share/themes/Adwaita-Xfce
ADD ubuntu-files/xfce-perchannel-xml /etc/xdg/xfce4/xfconf/xfce-perchannel-xml
RUN mkdir -p /usr/share/backgrounds
ADD ubuntu-files/background-default.png /usr/share/backgrounds/background-default.png
RUN ln -s /usr/share/icons/Numix-Circle /usr/share/icons/KXicons


# add user to the input and video groups
RUN usermod -a -G input,video ${USER_NAME}

# add user to 'tsusers' group (this is a group that will be later 
# created by XRDP, but now we have to initialize it ourselves)
RUN groupadd tsusers && \ 
    usermod -a -G tsusers ${USER_NAME}


# add the keyboard maps
COPY keymaps /etc/xrdp/


# initialize and grant user ownership to the xrdp log file
RUN touch /var/log/xrdp.log && \
    chown ${USER_NAME} /var/log/xrdp.log

# initialize and grant user ownership to the xrdp-sesman log file
RUN touch /var/log/xrdp-sesman.log && \
    chown ${USER_NAME} /var/log/xrdp-sesman.log

# grant user ownership to the xrdp certificate
RUN chown ${USER_NAME} /etc/xrdp/cert.pem && \
    chown ${USER_NAME} /etc/xrdp/key.pem

# grant user ownership to the entire /var/run folder,
# where xrdp.pid will be created at run time
# (note that we cannot initialize this file in advance,
# as this would prevent new session from starting)
RUN chown -R ${USER_NAME} /var/run/

# grant user ownership to the entire /etc/xrdp/ folder
RUN chown -R ${USER_NAME} /etc/xrdp/

# # grant user ownership to the entire /etc/X11/xrdp folder
# RUN chown -R user /etc/X11/xrdp
# grant user ownership to the entire /etc/X11 folder
RUN chown -R ${USER_NAME} /etc/X11/

# grant user ownership to the entire /usr/share/X11 folder
RUN chown -R ${USER_NAME} /usr/share/X11

# allow all users to use Xorg X server
# and make it drop its default root rights
# (see Xwrapper.config (5) - Linux Man Pages)
RUN echo "allowed_users=anybody" >> /etc/X11/Xwrapper.config && \
    echo "needs_root_rights=no" >> /etc/X11/Xwrapper.config
# grant user ownership to Xwrapper.config
RUN chown ${USER_NAME} /etc/X11/Xwrapper.config 

# replace the default log file location from the /root folder 
# with a user-editable location (~/ folder)
# sed -i -e 's/old/new/g' file.txt
RUN sed -i "s/.xorgxrdp/\/home\/${USER_NAME}\/.xorgxrdp/g" /etc/xrdp/sesman.ini

# set the DISPLAY environment variable (which is not set automatically) 
# to avoid this "display is zero error":
# [INFO ] main: DISPLAY env var set to (null)
# [ERROR] main: error, display is zero;
# note that the display number must agree with that 
# which has been set using X11DisplayOffset in the sesman.ini file,
# and you can check it by issuing this command in the running container:
# cat /etc/xrdp/sesman.ini | grep X11DisplayOffset
# (the value of X11DisplayOffset is 10 by default, 
# which results in env variable DISPLAY equal to 10.0)
ENV DISPLAY=:10.0
# RUN echo $DISPLAY

# grant user ownership to the /tmp folder
# to allow session manager to create subfolders there,
# such as .ICE-unix
RUN chown ${USER_NAME} /tmp

# # initialize xrdp.pid file and grant ownership to the user
# RUN touch /var/run/xrdp.pid && \
#     chown user /var/run/xrdp.pid


ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT /entrypoint.sh
