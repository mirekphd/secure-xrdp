#!/bin/bash

# add a /etc/passwd entry for the current 
# arbitrary UID generated randomly by OpenShift at runtime 
# (or added by -u switch to docker run)
# (source: container-rhel-examples/starter-arbitrary-uid)
# note that root is required to execute this script (e.g. at entrypoint)

# caution: this line did not work here in entrypoint, 
# so it was moved to Dockerfile
# # delete existing entry for the user from /etc/passwd
# sed -i "/${USER_NAME}:x/d" /etc/passwd

# if ! whoami &> /dev/null; then
  if [ -w /etc/passwd ]; then
    # append a new entry for the user, using the current arbitrary UID 
    echo "${USER_NAME}:x:$(id -u):${MY_GID}:${USER_NAME} user:${HOME}:" >> /etc/passwd
  fi
# fi

# # create the sock dir properly
# # caution: this would require root, 
# # so cannot be run at entrypoint in user mode
# /bin/sh /usr/share/xrdp/socksetup

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
# dbus-daemon --session

# caution: we cannot use dbus-daemon -session, as it does not exit, 
# and would prevent xrdp from being run;
# instead we use dbus-launch: a utility to start D-Bus message bus daemon from a shell script,
# and unlike the daemon itself, dbus-launch exits, allowing subsequent programs (such as xrdp) to run;
# note also that we must specify which session should be used (e.g. xfce4-session)
# caution: dbus-launch cannot be executed until an X11 session has been created,
# so running it here would cause errors like this:
# "xfce4-session: Cannot open display: ."
# dbus-launch --exit-with-session
# dbus-launch --exit-with-session xfce4-session


# run xrdp and xrdp-sesman in the foreground in debug mode (-ns = no service) 
# to see the logs from *both* apps in terminal where docker run was executed
xrdp-sesman -ns & xrdp -ns


# continue running entrypoint (make it pass-through) via the CMD 
# (custom startup command) that will be executed from the Dockerfile
# caution: given that this script only prepares a passwd entry for 
# the current UID, using this line is essential for the server startup 
# (invoked from CMD which follows a call to ENTRYPOINT)
exec "$@"
