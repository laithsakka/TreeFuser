FROM ubuntu:18.04

# (1) Dependencies
# ----------------------------------------

RUN apt-get update -y && \
    apt-get install -y wget git \
        build-essential cmake ninja-build python
# gcc g++ automake autoconf make 

# OpenFST doesn't seem to be packaged for Ubuntu (SFST is..)
RUN cd /tmp && \
    wget -nv http://www.openfst.org/twiki/pub/FST/FstDownload/openfst-1.6.9.tar.gz && \
    tar xf openfst-1.6.9.tar.gz && \
    cd openfst-1.6.9 && ./configure && make && make install
  # sha256=de5959c0c7decd920068aa4f9405769842b955719d857fd5d858fcacf0998bda

RUN mkdir /build
WORKDIR /build

# Current Master on both [2018.11.04]:
ENV LLVM_SHA  97d7bcd5c024ee6aec4eecbc723bb6d4f4c3dc3d
ENV CLANG_SHA 6093fea79d46ed6f9846e7f069317ae996149c69

# https://git.llvm.org/git/llvm.git/
# https://github.com/llvm-mirror/llvm
# https://github.com/llvm-mirror/clang

# Fetching llvm/clang -
# # OPTION 1:
# # Problem here - this seems to sometimes work and sometimes not
# #  ("does not allow request for unadvertised object")!
# #
# # Git doesn't support direct checkout of a commit:
# RUN mkdir llvm && cd llvm && git init && \
#     git remote add origin https://github.com/llvm-mirror/llvm && \
#     git fetch --depth 1 origin ${LLVM_SHA} && git checkout FETCH_HEAD
# RUN cd llvm/tools && mkdir clang && cd clang && git init && \
#    git remote add origin https://github.com/llvm-mirror/clang && \
#    git fetch --depth 1 origin ${CLANG_SHA} && git checkout FETCH_HEAD

# OPTION 2:  Download tarballs.
RUN cd /tmp && wget -nv https://github.com/llvm-mirror/llvm/archive/${LLVM_SHA}.tar.gz && \
    tar xf ${LLVM_SHA}.tar.gz && mv llvm-${LLVM_SHA} /build/llvm

RUN cd /tmp && wget --progress=dot:giga https://github.com/llvm-mirror/clang/archive/${CLANG_SHA}.tar.gz && \
    tar xf ${CLANG_SHA}.tar.gz && mv clang-${CLANG_SHA} /build/llvm/tools/clang


# ENV CLANG_TOOLS_EXTRA_SHA e936bbdce059a887ec69b05c8c701ff0c77d1f51
# #RUN apt-get install -y subversion
# # svn co http://llvm.org/svn/llvm-project/clang-tools-extra/trunk extra
# RUN cd llvm/tools/clang/tools && \
#     git clone https://git.llvm.org/git/clang-tools-extra.git && \
#     cd clang-tools-extra && \
#     git checkout ${CLANG_TOOLS_EXTRA_SHA}


# (2) TreeFuser
# ----------------------------------------

ADD tree-fuser /build/llvm/tools/clang/tools/tree-fuser

RUN echo 'add_clang_subdirectory(tree-fuser)' >> /build/llvm/tools/clang/tools/CMakeLists.txt

# RUN apt-get install -y z3
# RUN apt-get install -y build-essential libc++-dev binutils

RUN mkdir /build/llvm-bld && cd llvm-bld && \
    cmake -G Ninja ../llvm && \
    ninja tree-fuser
