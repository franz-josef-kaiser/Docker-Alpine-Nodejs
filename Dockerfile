#@IgnoreInspection BashAddShebang
FROM alpine:edge

MAINTAINER Franz Josef Kaiser <wecodemore@gmail.com>

# User defined build variables
ARG VERSION
ENV VERSION ${VERSION:-5.6.0}

ARG NPM
ENV NPM ${NPM:-yes}

ARG NPM_VERSION
ENV NPM_VERSION ${NPM_VERSION:-3.6.0}

ENV USER node

# The base directory
ARG PREFIX
ENV PREFIX ${PREFIX:-/usr}

# Do not use `--fully-static` with Alpine Linux
# as it might have problems with musl (and glibc) and loading compiled modules
# @link https://github.com/nodejs/node-v0.x-archive/wiki/statically-linked-executable
ARG FLAGS
ENV FLAGS ${FLAGS:-}

ARG TARGET
ENV TARGET ${TARGET:-$PREFIX/lib/app}

ARG SRC
ENV SRC ${SRC:-./app}

# Here for historical reasons only
ENV NODE_PATH "${HOME}/.node_modules:${HOME}/.node_libraries:${TARGET}"

# Alpine APK registry packages
# Custom, user defined runtime packages, allowing for extensions
ARG ADDT_PACKAGES
# Concatenated package list
ENV PACKAGES "bash binutils-gold ca-certificates curl g++ gcc gnupg libgcc libstdc++ linux-headers make paxctl python ${ADDT_PACKAGES}"

WORKDIR "${TARGET}"

# 1. Add APK packages, Update certs, Add keys to verify the validity of the side-loaded Node.js tarball
#    The keys contain the ones of three older Node.js maintainers as well to verify older versions integrity
#    Verify .asc key file first, then verify tarball, then untar when everything went well
# 2. Build Nodejs using Gnu C Compiler/gcc ia Make using max available amount of CPUs, default to 1
#    Node.js needs to execute arbitrary code at runtime. Permit this by disabling mprotect: Grsecurity + paxctl.
# 3. Test the Node.js build and finished installation, Install NPM globally - if requested
# 4. Finally install NPM on demand.
# 5. Clean up temporary files, packages that aren't needed anymore, Remove Man pages, etc.
RUN apk update \
	&& apk add --upgrade --no-cache ${PACKAGES} \
	&& update-ca-certificates --fresh \
	&& gpg --keyserver pool.sks-keyservers.net --recv-keys 9554F04D7259F04124DE6B476D5A82AC7E37093B \
	&& gpg --fingerprint 9554F04D7259F04124DE6B476D5A82AC7E37093B \
	&& gpg --keyserver pool.sks-keyservers.net --recv-keys 94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
	&& gpg --fingerprint 94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
	&& gpg --keyserver pool.sks-keyservers.net --recv-keys 0034A06D9D9B0064CE8ADF6BF1747F4AD2306D93 \
	&& gpg --fingerprint 0034A06D9D9B0064CE8ADF6BF1747F4AD2306D93 \
	&& gpg --keyserver pool.sks-keyservers.net --recv-keys FD3A5288F042B6850C66B31F09FE44734EB7990E \
	&& gpg --fingerprint FD3A5288F042B6850C66B31F09FE44734EB7990E \
	&& gpg --keyserver pool.sks-keyservers.net --recv-keys 71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
	&& gpg --fingerprint 71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
	&& gpg --keyserver pool.sks-keyservers.net --recv-keys DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
	&& gpg --fingerprint DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
	&& gpg --keyserver pool.sks-keyservers.net --recv-keys C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
	&& gpg --fingerprint C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
	&& gpg --keyserver pool.sks-keyservers.net --recv-keys B9AE9905FFD7803F25714661B63B535A4C206CA9 \
	&& gpg --fingerprint B9AE9905FFD7803F25714661B63B535A4C206CA9 \
	&& gpg --keyserver pool.sks-keyservers.net --recv-keys 93C7E9E91B49E432C2F75674B0A78B0A6C481CF6 \
	&& gpg --fingerprint 93C7E9E91B49E432C2F75674B0A78B0A6C481CF6 \
	&& gpg --keyserver pool.sks-keyservers.net --recv-keys 114F43EE0176B71C7BC219DD50A3051F888C628D \
	&& gpg --fingerprint 114F43EE0176B71C7BC219DD50A3051F888C628D \
	&& gpg --keyserver pool.sks-keyservers.net --recv-keys 7937DFD2AB06298B2293C3187D33FF9D0246406D \
	&& gpg --fingerprint 7937DFD2AB06298B2293C3187D33FF9D0246406D \
	&& echo " ---> Downloading Node.js tarball" \
	&& curl --tlsv1.2 -sSOL "https://nodejs.org/dist/v${VERSION}/node-v${VERSION}.tar.gz" \
	&& curl --tlsv1.2 -sSOL "https://nodejs.org/dist/v${VERSION}/SHASUMS256.txt.asc" \
	&& curl --tlsv1.2 -sSOL "https://nodejs.org/dist/v${VERSION}/SHASUMS256.txt" \
	&& echo " ---> Verifying build" \
	&& gpg --verify -a SHASUMS256.txt.asc \
	&& grep "node-v${VERSION}.tar.gz" SHASUMS256.txt.asc \
		| sha256sum -c - \
	&& tar xzf "node-v${VERSION}.tar.gz" \
	&& cd "node-v${VERSION}" \
	&& echo " ---> Compiling Node.js with flags: ${FLAGS} --prefix=${PREFIX}" \
	&& ./configure ${FLAGS} --prefix=${PREFIX} $([[ -z "${NPM+yes}" ]] && echo "--without-npm") \
	&& make -j$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) \
	&& make install \
	&& paxctl -cm /usr/bin/node \
	&& if [[ -n "${NPM+yes}" ]]; then \
			echo " ---> Installing NPM globally" \
			&& npm install "npm@v${NPM_VERSION}" -g --prefix=${PREFIX}/local \
			&& ln -s -f /usr/local/bin/npm /usr/bin/npm \
			&& find /usr/lib/node_modules/npm -name test -print0 -o -name .bin -type d | xargs -0 rm -rf; \
		fi \
	&& node -e "console.log( ' ---> Node.js ' + process.version + ' was successfully installed' )" \
	&& echo " ---> Cleaning up" \
	&& cd .. \
	&& apk del ${PACKAGES} \
	&& apk -v cache clean \
	&& rm SHASUMS256.tx* \
	&& rm node-v${VERSION}.tar.gz \
	&& rm -rf /etc/ssl \
		node-v${VERSION} \
		/usr/include \
		/usr/share/man \
		/tmp/* \
		/var/cache/apk/* \
		/root/.npm \
		/root/.node-gyp \
		/usr/lib/node_modules/npm/man \
		/usr/lib/node_modules/npm/doc \
		/usr/lib/node_modules/npm/html

# && curl -L https://npmjs.org/install.sh | sh \
#VOLUME ${TARGET}

# Add group, Add no-pass user and assign to group, recursively own the target dir
#RUN addgroup ${USER} \
#	&& adduser -S ${USER} -D -G ${USER} \
#	&& chown -R ${USER}:${USER} ${TARGET}

#USER ${USER}

#ENV HOME /home/${USER}

#WORKDIR "${TARGET}"

# Create App directory
#ONBUILD RUN mkdir -p ${TARGET}

# Bundle app source
#ONBUILD COPY ${SRC} ${TARGET}

# Conditional installation of packages via NPM; Triggers when ${NPM} is set to not NULL.
#ONBUILD RUN [[ -z "${NPM}" ]] || $(npm install)

EXPOSE 3000

# The image name can double as a reference to the binary
# $ docker run nodejs
#COPY docker-entrypoint.sh /entrypoint.sh
#RUN chmod +x /entrypoint.sh
#ENTRYPOINT [ "/entrypoint.sh" ]

# Default command
CMD [ "node", "-v" ]