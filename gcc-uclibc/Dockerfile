ARG BASE_IMAGE="debian:latest"
ARG BUILDER="debian:latest"
ARG BUILD_CC_VERSION
ARG PREFIX="/opt"
ARG BUILD="x86_64-host-linux-gnu"
ARG TARGET
ARG KERNEL_ARCH
ARG QEMU_ARCH

ARG KERNEL_VERSION
ARG BINUTILS_VERSION
ARG GCC_VERSION
ARG UCLIBC_VERSION
ARG GMP_VERSION
ARG MPFR_VERSION
ARG MPC_VERSION

ARG BINUTILS_CONFIGURE_ARGS
ARG GCC_CONFIGURE_ARGS
ARG GCC_STAGE1_CONFIGURE_ARGS
ARG GCC_STAGE2_CONFIGURE_ARGS


FROM debian:testing AS qemu

RUN apt-get update \
 && apt-get install -y --no-install-recommends qemu-user-static


FROM ${BUILDER} AS builder

WORKDIR /
SHELL ["/bin/bash", "-c"]

ARG BUILD_CC_VERSION
ENV DEBIAN_FRONTEND="noninteractive"
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        bison \
        bzip2 \
        ca-certificates \
        curl \
        file \
        g++-${BUILD_CC_VERSION} \
        gawk \
        libc6-dev \
        make \
        python3 \
        rsync \
        texinfo \
        xz-utils \
 && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-${BUILD_CC_VERSION} 100 \
 && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-${BUILD_CC_VERSION} 100

ARG GCC_VERSION
RUN curl -fsSLO "https://ftpmirror.gnu.org/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.xz" \
 && tar xf "gcc-${GCC_VERSION}.tar.xz" \
 && rm "gcc-${GCC_VERSION}.tar.xz"
ARG GMP_VERSION
RUN curl -fsSLO "https://ftpmirror.gnu.org/gmp/gmp-${GMP_VERSION}.tar.xz" \
 && tar xf "gmp-${GMP_VERSION}.tar.xz" \
 && mv "gmp-${GMP_VERSION}" "gcc-${GCC_VERSION}/gmp" \
 && rm "gmp-${GMP_VERSION}.tar.xz"
ARG MPFR_VERSION
RUN curl -fsSLO "https://ftpmirror.gnu.org/mpfr/mpfr-${MPFR_VERSION}.tar.xz" \
 && tar xf "mpfr-${MPFR_VERSION}.tar.xz" \
 && mv "mpfr-${MPFR_VERSION}" "gcc-${GCC_VERSION}/mpfr" \
 && rm "mpfr-${MPFR_VERSION}.tar.xz"
ARG MPC_VERSION
RUN curl -fsSLO "https://ftpmirror.gnu.org/mpc/mpc-${MPC_VERSION}.tar.gz" \
 && tar xf "mpc-${MPC_VERSION}.tar.gz" \
 && mv "mpc-${MPC_VERSION}" "gcc-${GCC_VERSION}/mpc" \
 && rm "mpc-${MPC_VERSION}.tar.gz"
ARG KERNEL_VERSION
RUN curl -fsSLO "https://cdn.kernel.org/pub/linux/kernel/v${KERNEL_VERSION%%.*}.x/linux-${KERNEL_VERSION}.tar.xz" \
 && tar xf "linux-${KERNEL_VERSION}.tar.xz" \
 && rm "linux-${KERNEL_VERSION}.tar.xz"
ARG BINUTILS_VERSION
RUN curl -fsSLO "https://ftpmirror.gnu.org/binutils/binutils-${BINUTILS_VERSION}.tar.xz" \
 || curl -fsSLO "https://ftpmirror.gnu.org/binutils/binutils-${BINUTILS_VERSION}.tar.bz2" \
 && tar xf "binutils-${BINUTILS_VERSION}.tar".* \
 && rm "binutils-${BINUTILS_VERSION}.tar".*
ARG UCLIBC_VERSION
RUN curl -fsSLO "https://downloads.uclibc-ng.org/releases/${UCLIBC_VERSION}/uClibc-ng-${UCLIBC_VERSION}.tar.xz" \
 && tar xf "uClibc-ng-${UCLIBC_VERSION}.tar.xz" \
 && rm "uClibc-ng-${UCLIBC_VERSION}.tar.xz"

RUN sed -i '/^cc1libdir =/s@= .*@= $(libdir)/gcc/$(target_noncanonical)/$(gcc_version)@' /gcc-${GCC_VERSION}/libcc1/Makefile.in \
 && sed -i '/^#define XCHAL_HAVE_BE/s/1/0/' gcc-${GCC_VERSION}/include/xtensa-config.h \
 && sed -i '/^#define XCHAL_HAVE_BE/s/1/0/' binutils-${BINUTILS_VERSION}/include/xtensa-config.h

ARG PREFIX
ARG TARGET

ENV PATH="${PREFIX}/bin:${PATH}"

RUN mkdir -p "${PREFIX}/${TARGET}"{/lib,/usr/lib,/usr/local/lib} \
 && ln -sf "lib" "${PREFIX}/${TARGET}/lib32" \
 && ln -sf "lib" "${PREFIX}/${TARGET}/lib64" \
 && ln -sf "lib" "${PREFIX}/${TARGET}/usr/lib32" \
 && ln -sf "lib" "${PREFIX}/${TARGET}/usr/lib64" \
 && ln -sf "lib" "${PREFIX}/${TARGET}/usr/local/lib32" \
 && ln -sf "lib" "${PREFIX}/${TARGET}/usr/local/lib64"

WORKDIR /linux-${KERNEL_VERSION}
ARG KERNEL_ARCH
RUN make ARCH="${KERNEL_ARCH}" INSTALL_HDR_PATH="${PREFIX}/${TARGET}/usr" headers_install

WORKDIR /build-binutils
ARG BINUTILS_CONFIGURE_ARGS
RUN eval "declare -a binutils_configure_args=(${BINUTILS_CONFIGURE_ARGS})" \
 && ../binutils-${BINUTILS_VERSION}/configure \
            --build="${BUILD}" \
            --target="${TARGET}" \
            --prefix="${PREFIX}" \
            --with-sysroot="${PREFIX}/${TARGET}" \
            --disable-multilib \
            --disable-nls \
            --disable-werror \
            "${binutils_configure_args[@]}" \
 && make -j"$(nproc)" \
 && make install-strip \
 && GLOBIGNORE="" rm -rf ./*

WORKDIR /build-gcc-stage1
ARG GCC_CONFIGURE_ARGS
ARG GCC_STAGE1_CONFIGURE_ARGS
RUN eval "declare -a gcc_configure_args=(${GCC_CONFIGURE_ARGS})" \
 && eval "declare -a gcc_stage1_configure_args=(${GCC_STAGE1_CONFIGURE_ARGS})" \
 && ../gcc-${GCC_VERSION}/configure \
            --prefix="${PREFIX}" \
            --with-toolexeclibdir="${PREFIX}/${TARGET}/usr/lib" \
            --build="${BUILD}" \
            --target="${TARGET}" \
            --without-headers \
            --enable-languages="c,c++" \
            --disable-decimal-float \
            --disable-gcov \
            --disable-libada \
            --disable-libatomic \
            --disable-libgomp \
            --disable-libitm \
            --disable-libmpx \
            --disable-libphobos \
            --disable-libquadmath \
            --disable-libsanitizer \
            --disable-libssp \
            --disable-libstdcxx \
            --disable-libvtv \
            --disable-lto \
            --disable-multilib \
            --disable-nls \
            --disable-shared \
            --disable-threads \
            "${gcc_configure_args[@]}" \
            "${gcc_stage1_configure_args[@]}" \
 && make -j"$(nproc)" \
 && make install-strip \
 && GLOBIGNORE="" rm -rf ./*

WORKDIR /uClibc-ng-${UCLIBC_VERSION}
COPY ${TARGET}-config .config
RUN make -j"$(nproc)" \
 && make PREFIX="${PREFIX}/${TARGET}" install \
 && make realclean

WORKDIR /build-gcc-stage2
ARG GCC_STAGE2_CONFIGURE_ARGS
RUN eval "declare -a gcc_configure_args=(${GCC_CONFIGURE_ARGS})" \
 && eval "declare -a gcc_stage2_configure_args=(${GCC_STAGE2_CONFIGURE_ARGS})" \
 && ../gcc-${GCC_VERSION}/configure \
            --prefix="${PREFIX}" \
            --with-sysroot="${PREFIX}/${TARGET}" \
            --with-build-sysroot="${PREFIX}/${TARGET}" \
            --with-toolexeclibdir="${PREFIX}/${TARGET}/usr/lib" \
            --with-gxx-include-dir="${PREFIX}/${TARGET}/usr/include/c++" \
            --build="${BUILD}" \
            --target="${TARGET}" \
            --enable-languages="c,c++" \
            --enable-__cxa_atexit \
            --disable-libstdcxx-pch \
            --disable-multilib \
            --disable-nls \
            "${gcc_configure_args[@]}" \
            "${gcc_stage2_configure_args[@]}" \
 && make -j"$(nproc)" \
 && make install-strip \
 && GLOBIGNORE="" rm -rf ./*

WORKDIR ${PREFIX}/bin
RUN for f in ${TARGET}-*; do ln -sf "${f}" "${f#${TARGET}-}"; done

ARG QEMU_ARCH
COPY --from=qemu /bin/sh /usr/bin/[q]emu-${QEMU_ARCH}-static ${PREFIX}/bin/

RUN rm -rf "${PREFIX}/bin/sh" "${PREFIX}/share/info" "${PREFIX}/share/man"


FROM ${BASE_IMAGE}

ARG PREFIX
ARG TARGET
ARG QEMU_ARCH
ARG KERNEL_VERSION
ARG BINUTILS_VERSION
ARG GCC_VERSION
ARG UCLIBC_VERSION
ARG GMP_VERSION
ARG MPFR_VERSION
ARG MPC_VERSION
ARG DOCKERFILE_HASH=unset

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        ca-certificates \
        cmake \
        curl \
        git \
        make \
 && rm -rf /var/lib/apt/lists/*

COPY --from=builder "${PREFIX}" "${PREFIX}"

ENV PATH="${PREFIX}/bin:${PATH}" \
    TARGET="${TARGET}" \
    PREFIX="${PREFIX}/${TARGET}" \
    AR="${TARGET}-ar" \
    AS="${TARGET}-as" \
    CC="${TARGET}-gcc" \
    CXX="${TARGET}-g++" \
    LD="${TARGET}-ld" \
    NM="${TARGET}-nm" \
    OBJCOPY="${TARGET}-objcopy" \
    OBJDUMP="${TARGET}-objdump" \
    RANLIB="${TARGET}-ranlib" \
    READELF="${TARGET}-readelf" \
    STRIP="${TARGET}-strip" \
    QEMU="qemu-${QEMU_ARCH}-static" \
    QEMU_LD_PREFIX="${PREFIX}/${TARGET}" \
    QEMU_SET_ENV="LD_LIBRARY_PATH=${PREFIX}/${TARGET}/usr/local/lib:${PREFIX}/${TARGET}/usr/lib:${PREFIX}/${TARGET}/lib"

LABEL org.opencontainers.image.source="https://github.com/cions/docker-compiler" \
      compiler.target="${TARGET}" \
      compiler.kernel.version="${KERNEL_VERSION}" \
      compiler.binutils.version="${BINUTILS_VERSION}" \
      compiler.gcc.version="${GCC_VERSION}" \
      compiler.uclibc.version="${UCLIBC_VERSION}" \
      compiler.gmp.version="${GMP_VERSION}" \
      compiler.mpfr.version="${MPFR_VERSION}" \
      compiler.mpc.version="${MPC_VERSION}" \
      compiler.dockerfile="${DOCKERFILE_HASH}"
