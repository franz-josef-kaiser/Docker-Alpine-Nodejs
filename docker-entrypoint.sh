#!/bin/bash
set -e

NAME="node"
TARGET=/usr/src/app

if [ "$1" = ${NAME} ]; then
	chown -R ${NAME} ${TARGET}
	exec gosu ${NAME} "$@"
fi

exec "$@"