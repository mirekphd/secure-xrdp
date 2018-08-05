#!/bin/bash

# create a dbus system daemon
# note that it needs to be run successfully,
# or else we will get errors like these in xorgxrdp log:
# "(EE) dbus-core: error connecting to system bus: 
# org.freedesktop.DBus.Error.FileNotFound (Failed to connect 
# to socket /var/run/dbus/system_bus_socket: No such file or directory)"
# caution: we cannot create a system-wide bus (with --system), 
# because that would require root, so instead we create a per-login-session 
# message bus (with --session), which can be run as standard user
# dbus-daemon --system
dbus-daemon --session

# create the sock dir properly
/bin/sh /usr/share/xrdp/socksetup

# run xrdp and xrdp-sesman in the foreground so the logs show in docker
xrdp-sesman -ns &
xrdp -ns
