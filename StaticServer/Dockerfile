FROM swift:latest as builder
WORKDIR /root
COPY . .

RUN apt-get update
RUN apt-get install -y --no-install-recommends apt-utils
RUN apt-get -y install wget
RUN apt-get -y install tar

RUN wget -O libevent-2.1.12-stable.tar.gz https://github.com/libevent/libevent/releases/download/release-2.1.12-stable/libevent-2.1.12-stable.tar.gz
RUN tar -xzvf libevent-2.1.12-stable.tar.gz && cd libevent-2.1.12-stable && ./configure --disable-openssl && make && make install

RUN swift build -c release

FROM swift:slim
WORKDIR /root
COPY --from=builder /root .
COPY --from=builder /usr/local/lib/libevent* /usr/lib/x86_64-linux-gnu/

EXPOSE 80
CMD ./.build/release/StaticServer