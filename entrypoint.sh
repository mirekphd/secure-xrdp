#!/bin/bash

# create a dbus system daemon
dbus-daemon --system

# create the sock dir properly
/bin/sh /usr/share/xrdp/socksetup

# initialize and grant user ownership to the xrdp log file
touch /var/log/xrdp.log
chown 1000 /var/log/xrdp.log

# initialize and grant user ownership to the xrdp-sesman log file
touch /var/log/xrdp-sesman.log
chown 1000 /var/log/xrdp-sesman.log

# initialize xrdp.pid file and grant ownership to the user
touch /var/run/xrdp.pid
chown 1000 /var/run/xrdp.pid

# switch to user before running xrdp
su user

# run xrdp and xrdp-sesman in the foreground so the logs show in docker
xrdp-sesman -ns &
xrdp -ns
