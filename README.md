<h1 align="center">
	Nodejs dockerized on Alpine OS
</h1>

[![Build Status](https://travis-ci.org/franz-josef-kaiser/Docker-Alpine-Nodejs.svg?branch=master)](https://travis-ci.org/franz-josef-kaiser/Docker-Alpine-Nodejs)
[![Stories in Ready](https://badge.waffle.io/franz-josef-kaiser/filterama.png?label=ready&title=Ready)](https://waffle.io/franz-josef-kaiser/filterama)

Builds a **small and highly versatile** Docker container, running **Alpine Linux OS** latest version 
and Nodejs on top. Optional installation of npm and, depending on that, installs packages 
on demand.

### Configuration

There are various parts that you can define when building your image:

 * `VERSION` - The _Nodejs_ version number; 
 Default: `5.6.0`
 * `NPM` - Set to "yes" (or whatever) if you want to install _npm_ as well; 
 Default: `yes`
 * `NPM_VERSION` - Define the _npm_ version you want to install; 
 Default: `3.6.0`
 * `PREFIX` - The `--prefix` for installing _Nodejs_ and _npm_; 
 Default: `/usr`
 * `FLAGS` - Any additional flags you want to pass to the `configure` call when building _Nodejs_; 
 Default: none, but [due to a bug](https://github.com/nodejs/node-v0.x-archive/wiki/statically-linked-executable), 
 `--fully-static` will be removed even if set.
 * `TARGET` - The installation target, prefixed by `PREFIX`, so please leave that off; 
 Default: `${PREFIX}/lib/app`
 * `SRC` - From where to fetch the original files for the `ONBUILD` commands; 
 Default: `./app`; **Note** will probably get removed
 * `ADDT_PACKAGES` - Additional (permanent) packages from the Alpine OS package repository, 
 set for e.g. `wget` or `nano` here; 
 Default: none

### Security

**OS** Alpine Linux has a very small foot print and therefore only a tiny attack surface. 
In addition, it features SELinux for enhanced security. Still it is recommended to 
have a firewall, proxy or load balancer in front of your Node servers to not expose 
them directly to the public.

**Packages** The download gets verified using _GNU Privacy Guard_/gpg. That means that 
if the source repo should get compromised, the build will fail with the 
following message:

```shell
node-v5.6.0.tar.gz: FAILED
sha256sum: WARNING: 1 of 1 computed checksums did NOT match
```

### How To

Build the image on the command line (assuming the `Dockerfile` is in a subfolder):

    docker build -t nodejs:latest ./Docker/Nodejs/

Per default, the container comes **without npm**. To install with NPM and adjust 
both the Node and NPM version, you have to use the `--build-arg` flag:

    docker build -t nodejs:5.6.0 --build-arg VERSION="5.6.0" NPM_VERSION="3" NPM="yes" ./Docker/Nodejs/

Development builds should be done without cache:

    docker build --no-cache -t nodejs:dev ./Docker/Nodejs/

Docker Compose Example:

```yml
version: '2'

services:
    nodejs:
        container_name: nodejs
        build:
            context: ./Docker/Nodejs
            args:
                VERSION: "5.6.0"
                NPM_VERSION: "3"
                NPM: "yes"
                PREFIX: "/usr"
                TARGET: "/src/app"
                SRC: "./app/node"
        restart: on-failure:3
        expose:
            - "3000"
        depends_on:
            - nodeapp
        volumes_from:
            - nodeapp
        command: [ "node", "server.js" ]
        #command: npm install --force --loglevel=error
        networks:
            - front
        tty: true

    nodeapp:
        container_name: nodeapp
        image: busybox:latest
        volumes:
            - ./app/node:/usr/src/app
        networks:
            - front
        tty: true

volumes:
	nodeapp:

networks:
    front:
        driver: bridge
```

You can then check your attached volume:

```shell
$ docker volume ls
local    projectname_nodeapp
```

In case you need to remove your volume container:

```shell
docker volume rm $(docker volume ls |awk '{print $2}')
```

Details about the volume are then available via:

```shell
docker volume inspect <volume_name>

# Example:
$ docker volume inspect projectname_nodeapp

[
    {
        "Name"       : "projectname_nodeapp",
        "Driver"     : "local",
        "Mountpoint" : "/mnt/sda1/var/lib/docker/volumes/projectname_nodeapp/_data"
    }
]
```

**Sidenote:** You might want to `docker-compose down` your Nodejs service 
to get a fresh start before going to create volumes.

### FAQ

**Q:** What is the license?

**A:** MIT License (Expat). **tl;dr**: Basically, you can do whatever you 
want as long as you include the original copyright and license notice in any copy 
of the software/source. [tl;dr](https://tldrlegal.com/license/mit-license). See 
the attached license file in this repository for the full text.

**Q:** The GPG verification fails with `gpg: no ultimately trusted keys found`. Why that?

**A:** The only key that you can trust is _your own_. You can sign other peoples
keys as "trusted", something that you only want to do if you know them in person 
and _really_ trust them. If you have such a person and this person knows someone 
who knows someone who knows the person who signed that release, then you can 
build a "chain of trust" and absolutely verify a key. For every real world use 
case, above verification is more than enough. And key signing never hit a critical 
mass to build a web of trust easily. In other words: The message is a bit misleading.

**Q:** The GPG verification states `gpg: WARNING: not a detached signature;`. Why that?

**A:** The signature asc file checked out good, but warned about it not being 
certified with a trusted signature. As learned in the previous step, it just 
tells you that you did not sign it yourself.

**Q:** I get `gyp: true not found (cwd: /node-v5.6.0) while trying to load true. Error running GYP`
when trying to build the image.

**A:** You should define all build arguments as _strings_. Do not set `--build-arg NPM=true`, but 
use `--build-arg NPM="true"` (or better: `yes`) instead to avoid using a _real_ boolen. 
The same has to be done when using _Docker Compose_. Set `build: args: NPM: "yes"` as _string_.

## Tests

Currently there are acceptance tests shipped with this package. The specs 
are run using Ruby and the following Gems:

 * [rspec](https://rubygems.org/gems/rspec)
 * [serverspec](https://rubygems.org/gems/serverspec)
 * [docker-api](https://rubygems.org/gems/docker-api)

To run tests, you need Ruby and the listed Gems installed. The test can 
be run on the command line:

```shell
$ Print progress bar/dots while running tests
$ rspec --format progress Dockspec.rb
# Short notation
$ rspec -f p Dockspec.rb
# Verbose output (Print spec titles) while running tests
$ rspec --format documentation Dockspec.rb
# Short notation
$ rspec -f d Dockspec.rb
```

The _docker-api_ Gem will remote execute Docker, which means that the test run 
is a real world test and will fully expose things that might go wrong.

**OS X** and **Windows** users will have to run the tests inside their Docker Machine.

## TO-DO

The build is currently not running smoothly. There are some things that need fixing. 
If you can help, please open an issue, to discuss any idea you have in mind. If that 
results in a pull request, I am happy to give you AAA-access to this repo. Please take a 
quick look at [CONTRIBUTING](CONTRIBUTING.md) - you will not find any surprises there. 

 * Nodejs probably shouldn't run as `root` on this machine. When everything works as `root`, 
 there should be a non privileged `node` user in place. See uncommented parts of the [`Dockerfile`](Dockerfile)
 * Maybe there should be an [`ENTRYPOINT`](docker-entrypoint.sh) in place to pass commands directly 
 to `npm` and avoid fiddling with `node`.
 * The file removal after the installation of NPM could be much easier and just set a whitelist.
 That would also mean that it's more versatile regarding the folder structure of various versions.
 Also we need to check the folder structure first and maybe switch the whitelist depending on the version.
