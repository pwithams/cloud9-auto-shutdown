#!/bin/bash
echo "Backing up existing script..."
date=`date +"%Y-%m-%d-%H-%m-%s"`
mv ~/.c9/stop-if-inactive.sh ~/.c9/stop-if-inactive.sh.bk.$date
echo "Backups: "
ls -l ~/.c9/stop-if-inactive.sh.bk.* | awk '{ print $9 }'
echo "Installing new script..."
cp stop-if-inactive.sh ~/.c9/stop-if-inactive.sh
echo "Finished"
