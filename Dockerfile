FROM debian:9 as builder

ARG BRANCH=v0.7.0
ENV BRANCH=${BRANCH}

# install build dependencies
# checkout the latest tag
# build and install
RUN apt-get update && \
    apt-get install -y \
      build-essential \
      gdb \
      libreadline-dev \
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

# TurtleCoind now needs libreadline 
RUN apt-get update && \
    apt-get install -y \
      libreadline-dev \
     && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/turtlecoin/turtlecoind-ha.git /usr/local/turtlecoin-ha && mkdir /tmp/checkpoints/

ADD https://github.com/turtlecoin/checkpoints/raw/master/checkpoints.csv /tmp/checkpoints/

COPY --from=builder /opt/turtlecoin/build/src/* /usr/local/turtlecoin-ha/

COPY ./funkypenguin-service.js /usr/local/turtlecoin-ha/

RUN mkdir -p /var/lib/turtlecoind && npm install \
	nonce \
	shelljs \
	node-pty \
	sha256 \
	socket.io \
	turtlecoin-rpc

WORKDIR /usr/local/turtlecoin-ha
CMD [ "pm2-runtime", "start", "funkypenguin-service.js" ]
