#!/bin/bash
 SRCDIR=`pwd`
 DESTDIR=$SRCDIR/backups
 bids_name=${SRCDIR##*/}
 FILENAME=${bids_name}_backup_$(date "+%Y-%m-%d")_$(date "+%H-%M-%S").tgz
 tar -cvpz \
 	--exclude='backups/*' \
 	-f ${DESTDIR}/${FILENAME} \
 	.