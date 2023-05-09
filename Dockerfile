FROM crystallang/crystal:1.8.1-alpine

RUN apk add --no-cache wget build-base cmake python3 unzip openssh libssh2

RUN wget https://github.com/libgit2/libgit2/archive/refs/tags/v1.3.2.zip -O libgit2.zip
RUN unzip libgit2.zip && cd libgit2-1.3.2 && mkdir build && cd build && cmake .. && cmake --build . --target install





