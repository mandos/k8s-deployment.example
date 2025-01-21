#!/bin/sh
set -e

docker build -t mandos22/assessment-back-test:"$1" -f charts/backend/docker/Dockerfile charts/backend/docker/

if [ "$2" = "push" ]; then
	docker push mandos22/assessment-back-test:"$1"
fi
