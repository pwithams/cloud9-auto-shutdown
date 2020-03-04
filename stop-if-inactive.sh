#!/bin/bash

# stop-if-inactive.sh
# Schedules a shutdown if neither the c9 IDE or an ssh connection
# from specific IP addresses exists
# If either are connected, any existing shutdowns are cancelled

set -euo pipefail
CONFIG=$(cat /home/ubuntu/.c9/autoshutdown-configuration)
SHUTDOWN_TIMEOUT=${CONFIG#*=}
LOG_DIRECTORY="/tmp/.c9-log/"
LOG_FILENAME="auto-shutdown-log.txt"
LOG_FILE_PATH=$LOG_DIRECTORY$LOG_FILENAME
IP_REGEX=".*"

is_shutting_down() {
    is_shutting_down_system_d &> /dev/null || is_shutting_down_init_d &> /dev/null
}

is_shutting_down_system_d() {
    local TIMEOUT
    TIMEOUT=$(busctl get-property org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager ScheduledShutdown)
    if [ "$?" -ne "0" ]; then
        return 1
    fi
    if [ "$(echo $TIMEOUT | awk "{print \$3}")" == "0" ]; then
        return 1
    else
        return 0
    fi
}

is_shutting_down_init_d() {
    pgrep shutdown
}

is_vfs_connected() {
    pgrep vfs-worker >/dev/null
}

is_ssh_connected() {
    sudo netstat -tnpa | grep 'ESTABLISHED.*sshd' | grep "$IP_REGEX" > /dev/null
}

get_ssh_state() {
    local ssh_state="disconnected"
    if is_ssh_connected; then
        ssh_state="connected"
    fi
    echo $ssh_state
}

get_vfs_state() {
    local vfs_state="disconnected"
    if is_vfs_connected; then
        vfs_state="connected"
    fi
    echo $vfs_state
}

main() {
    if ! [[ $SHUTDOWN_TIMEOUT =~ ^[0-9]*$ ]]; then
        echo "shutdown timeout is invalid"
        exit 1
    fi

    if is_shutting_down; then
        if [[ ! $SHUTDOWN_TIMEOUT =~ ^[0-9]+$ ]] || is_vfs_connected || is_sh_connected; then
            shutdown_status="shutdown cancelled"
            sudo shutdown -c
        else
            shutdown_status="current scheduled shutdown is still valid"
        fi
    elif [[ $SHUTDOWN_TIMEOUT =~ ^[0-9]+$ ]] && ! is_vfs_connected && ! is_sh_connected; then
        shutdown_status="shutdown scheduled"
        sudo shutdown -h $SHUTDOWN_TIMEOUT
    else
        shutdown_status="N/A"
    fi

    mkdir -p $LOG_DIRECTORY
    date > $LOG_FILE_PATH
    echo "Shutdown status: "$shutdown_status >> $LOG_FILE_PATH
    echo "VFS State: "$(get_vfs_state) >> $LOG_FILE_PATH
    echo "SSH State: "$(get_ssh_state) >> $LOG_FILE_PATH
}

main
