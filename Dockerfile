# WHAT IS THIS FOR?
# This is a copy of Dockerfile, but prior to compiling, will set difficult to 500, resets all the
# seed nodes to RFC1918 addresses (to avoid annoying mainnet), and mixes up the network ID.
# Useless for mainnet, but used to setup a testnet with checkpoints, and not have to spend days mining to get to the next block!
#
FROM debian:9 as builder

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
    git clone https://github.com/turtlecoin/turtlecoin.git /opt/turtlecoin && \
    cd /opt/turtlecoin && \
    sed -i '/std::vector<uint64_t> timestamps_o(timestamps);/i \\/*\n   Lower difficulty to static 500 for testnet\n   The rest of this function is ignored\n*\/\nreturn 500;\n\n' src/CryptoNoteCore/Currency.cpp && \
    sed -i -e 's/"104.236.227.176:11897",/"172.16.76.11:11897",/g' src/CryptoNoteConfig.h && \
    sed -i -e 's/"46.101.132.184:11897",/"172.16.76.12:11897",/g' src/CryptoNoteConfig.h && \
    sed -i -e 's/"163.172.147.52:11897",/"172.16.76.13:11897",/g' src/CryptoNoteConfig.h && \
    sed -i -e 's/"51.15.138.214:11897",/"192.168.76.11:11897",/g' src/CryptoNoteConfig.h && \
    sed -i -e 's/"51.15.137.77:11897",/"192.168.76.12:11897",/g' src/CryptoNoteConfig.h && \
    sed -i -e 's/"174.138.68.141:11897", \/\/\^ rock/"192.168.76.13:11897",/g' src/CryptoNoteConfig.h && \
    sed -i -e 's/"145.239.88.119:11999", \/\/cision/"10.0.76.11:11897",/g' src/CryptoNoteConfig.h && \
    sed -i -e 's/"142.44.242.106:11897", \/\/tom/"10.0.76.12:11897",/g' src/CryptoNoteConfig.h && \
    sed -i -e 's/"165.227.252.132:11897" \/\/iburnmycd/"10.0.76.13:11897",/g' src/CryptoNoteConfig.h && \
    sed -i -e 's/0xcf, 0x52, 0x57/0x52, 0xcf, 0x57/' src/P2p/P2pNetworks.h && \
    mkdir build && \
    cd build && \
    export CXXFLAGS="-w -std=gnu++11" && \
    #cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo .. && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_FLAGS="-fassociative-math" -DCMAKE_CXX_FLAGS="-fassociative-math" -DSTATIC=true -DDO_TESTS=OFF .. && \
    make -j$(nproc)

FROM debian:9-slim
RUN mkdir -p /usr/local/bin
WORKDIR /usr/local/bin
COPY --from=builder /opt/turtlecoin/build/src/TurtleCoind .
COPY --from=builder /opt/turtlecoin/build/src/walletd .
COPY --from=builder /opt/turtlecoin/build/src/simplewallet .
COPY --from=builder /opt/turtlecoin/build/src/miner .
RUN mkdir -p /var/lib/turtlecoind && mkdir /tmp/checkpoints && mkdir /log
ADD https://github.com/turtlecoin/checkpoints/raw/master/checkpoints.csv /tmp/checkpoints
WORKDIR /var/lib/turtlecoind
ENTRYPOINT ["/usr/local/bin/TurtleCoind"]
CMD ["--no-console","--data-dir","/var/lib/turtlecoind","--rpc-bind-ip","0.0.0.0","--rpc-bind-port","11898","--p2p-bind-port","11897","--enable-cors=*","--enable_blockexplorer","--load-checkpoints","/tmp/checkpoints/checkpoints.csv","--log-file","/log/TurtleCoind.log"]
