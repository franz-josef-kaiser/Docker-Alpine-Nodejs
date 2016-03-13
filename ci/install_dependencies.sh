#!/bin/bash
# @author (GitHub) swipely/docker-api @tlunter
# @license MIT
# @link https://github.com/swipely/docker-api/blob/1c5f27324e49c2fb04e964303629f6fc7ad9768f/script/install_dependencies.sh

set -e

# Update bundler
gem install bundler

# Install docker
sudo mkdir -p /opt/docker
sudo curl -fo /opt/docker/docker "https://get.docker.com/builds/Linux/x86_64/docker-${DOCKER_VERSION}"
sudo chmod +x /opt/docker/docker

running=0
for x in {1..3}
do
    [[ $running != 1 ]] || break
    sudo rm -rf /var/run/docker.pid
    sudo /opt/docker/docker daemon -D &
    DOCKER_PID=$!
    sleep 5
    echo "Checking if docker is running"
    ps -p $DOCKER_PID && running=1 || echo "Couldn't start docker, retrying"
done
echo "Docker running, continuing"