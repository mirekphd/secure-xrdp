#!/bin/bash

# create a dbus system daemon
dbus-daemon --system

# create the sock dir properly
/bin/sh /usr/share/xrdp/socksetup

# grant user ownership to the xrdp and xrdp-sesman log files
chown 1000 /var/log/xrdp.log
chown 1000 /var/log/xrdp-sesman.log

# run xrdp and xrdp-sesman in the foreground so the logs show in docker
xrdp-sesman -ns &
xrdp -ns
