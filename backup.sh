#!/bin/bash
 SRCDIR=$1
 DESTDIR=$SRCDIR/backups
 FILENAME=ug-$(date +%-Y%-m%-d)-$(date +%-T).tgz
 tar -cvpz \
 	--exclude='backups/*'\
 	-f ${DESTDIR}/${FILENAME} \
 	$SRCDIR