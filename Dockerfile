FROM crystallang/crystal:latest


ENV XMAKE_ROOT=y
RUN apt update -y && apt install -y software-properties-common
RUN add-apt-repository ppa:xmake-io/xmake
RUN apt update -y

RUN apt install -y wget software-properties-common cmake python3 unzip openssh-client openssh-server libssh2-1 libssh2-1-dev xmake

RUN ln -s /usr/lib/x86_64-linux-gnu/* /usr/local/lib/.
ENTRYPOINT ["/bin/bash", "--init-file", "~/.xmake/profile", "-lc"]