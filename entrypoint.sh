#!/bin/bash

# create the sock dir properly
/bin/sh /usr/share/xrdp/socksetup

# run xrdp and xrdp-sesman in the foreground so the logs show in docker
xrdp-sesman -ns &
xrdp -ns

# create a dbus system daemon
# note that it needs to be run successfully,
# or else we will get errors like these in xorgxrdp log:
# "(EE) dbus-core: error connecting to system bus: 
# org.freedesktop.DBus.Error.FileNotFound (Failed to connect 
# to socket /var/run/dbus/system_bus_socket: No such file or directory)"
# caution: we cannot create a system-wide bus (with --system), 
# because that would require root, so instead we create a per-login-session 
# message bus (with --session), which can be run as standard user
# caution: we cannot use dbus-daemon -session, as it does not exit, 
# and would prevent xrdp from being run;
# instead we use dbus-launch: a utility to start D-Bus message bus daemon from a shell script,
# and unlike the daemon itself, dbus-launch exits, allowing subsequent programs (such as xrdp) to run;
# note also that we must specify which session should be used (e.g. xfce4-session)
# dbus-daemon --system
# dbus-daemon --session
# dbus-launch --exit-with-session
dbus-launch --exit-with-session xfce4-session
