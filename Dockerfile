FROM debian:9 as builder

ARG BRANCH=v0.8.3
ENV BRANCH=${BRANCH}

# BUILD_DATE and VCS_REF are immaterial, since this is a 2-stage build, but our build
# hook won't work unless we specify the args
ARG BUILD_DATE
ARG VCS_REF

# install build dependencies
# checkout the latest tag
# build and install
RUN apt-get update && \
    apt-get install -y \
      build-essential \
      gdb \
      python-dev \
      gcc \
      g++\
      git \
      cmake \
      libboost-all-dev \
      librocksdb-dev && \
    git clone --branch $BRANCH https://github.com/turtlecoin/turtlecoin.git /opt/turtlecoin && \
    cd /opt/turtlecoin && \
    mkdir build && \
    cd build && \
    export CXXFLAGS="-w -std=gnu++11" && \
    #cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo .. && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_FLAGS="-fassociative-math" -DCMAKE_CXX_FLAGS="-fassociative-math" -DSTATIC=true -DDO_TESTS=OFF .. && \
    make -j$(nproc)

FROM keymetrics/pm2:latest-stretch 

# Now we DO need these, for the auto-labeling of the image
ARG BUILD_DATE
ARG VCS_REF

# Good docker practice, plus we get microbadger badges
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-url="https://github.com/funkypenguin/automated-docker-builds.git" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.schema-version="2.2-r1"

RUN git clone https://github.com/turtlecoin/turtlecoind-ha.git /usr/local/turtlecoin-ha && mkdir /tmp/checkpoints/

ADD https://github.com/turtlecoin/checkpoints/raw/master/checkpoints.csv /tmp/checkpoints/

COPY --from=builder /opt/turtlecoin/build/src/* /usr/local/turtlecoin-ha/

RUN mkdir -p /var/lib/turtlecoind && npm install \
	nonce \
	shelljs \
	node-pty \
	sha256 \
	socket.io \
	turtlecoin-rpc

WORKDIR /usr/local/turtlecoin-ha
CMD [ "pm2-runtime", "start", "service.js" ]
