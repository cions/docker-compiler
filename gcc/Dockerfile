ARG PREFIX=/opt
ARG BUILDER=debian:bullseye
ARG BUILD_CC_VERSION=10
ARG TARGET=aarch64-linux-gnu
ARG KERNEL_ARCH=arm64
ARG QEMU_ARCH=aarch64

ARG KERNEL_VERSION=5.10.70
ARG BINUTILS_VERSION=2.36
ARG GCC_VERSION=11.2.0
ARG GLIBC_VERSION=2.33
ARG GMP_VERSION=6.2.1
ARG MPFR_VERSION=4.1.0
ARG MPC_VERSION=1.2.1


FROM debian:testing AS qemu

RUN apt-get update -qq \
 && apt-get install -qy --no-install-recommends \
        qemu-user-static \
 && rm -rf /var/lib/apt/lists/*


FROM ${BUILDER} AS builder

SHELL ["bash", "-c"]

ARG BUILD_CC_VERSION
RUN apt-get update -qq \
 && apt-get install -qy --no-install-recommends \
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
 && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-${BUILD_CC_VERSION} 100 \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /
ARG GCC_VERSION
RUN curl -fsSLO "https://ftpmirror.gnu.org/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.xz" \
 && tar xf "gcc-${GCC_VERSION}.tar.xz" \
 && rm "gcc-${GCC_VERSION}.tar.xz"
ARG GMP_VERSION
RUN curl -fsSLO "https://ftpmirror.gnu.org/gmp/gmp-${GMP_VERSION}.tar.xz" \
 && tar xf "gmp-${GMP_VERSION}.tar.xz" \
 && mv "../gmp-${GMP_VERSION}" "gcc-${GCC_VERSION}/gmp" \
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
RUN curl -fsSLO "https://cdn.kernel.org/pub/linux/kernel/v$(echo ${KERNEL_VERSION} | cut -d. -f1).x/linux-${KERNEL_VERSION}.tar.xz" \
 && tar xf "linux-${KERNEL_VERSION}.tar.xz" \
 && rm "linux-${KERNEL_VERSION}.tar.xz"
ARG BINUTILS_VERSION
RUN curl -fsSLO "https://ftpmirror.gnu.org/binutils/binutils-${BINUTILS_VERSION}.tar.xz" \
 || curl -fsSLO "https://ftpmirror.gnu.org/binutils/binutils-${BINUTILS_VERSION}.tar.bz2" \
 && tar xf "binutils-${BINUTILS_VERSION}.tar".* \
 && rm "binutils-${BINUTILS_VERSION}.tar".*
ARG GLIBC_VERSION
RUN curl -fsSLO "https://ftpmirror.gnu.org/glibc/glibc-${GLIBC_VERSION}.tar.xz" \
 && tar xf "glibc-${GLIBC_VERSION}.tar.xz" \
 && rm "glibc-${GLIBC_VERSION}.tar.xz"

ARG PREFIX
ARG TARGET

ENV PATH="${PREFIX}/bin:${PATH}"

RUN mkdir -p "${PREFIX}/${TARGET}/lib" "${PREFIX}/${TARGET}/usr/lib" "${PREFIX}/${TARGET}/usr/local/lib" \
 && ln -sf "lib" "${PREFIX}/${TARGET}/lib32" \
 && ln -sf "lib" "${PREFIX}/${TARGET}/lib64" \
 && ln -sf "lib" "${PREFIX}/${TARGET}/usr/lib32" \
 && ln -sf "lib" "${PREFIX}/${TARGET}/usr/lib64" \
 && ln -sf "lib" "${PREFIX}/${TARGET}/usr/local/lib32" \
 && ln -sf "lib" "${PREFIX}/${TARGET}/usr/local/lib64"

RUN sed -i '/^cc1libdir =/s@= .*@= $(libdir)/gcc/$(target_noncanonical)/$(gcc_version)@' /gcc-${GCC_VERSION}/libcc1/Makefile.in

WORKDIR /linux-${KERNEL_VERSION}
ARG KERNEL_ARCH
RUN make ARCH="${KERNEL_ARCH}" INSTALL_HDR_PATH="${PREFIX}/${TARGET}/usr" headers_install

WORKDIR /build-binutils
ARG BINUTILS_CONFIGURE_ARGS=""
RUN eval "declare -a binutils_configure_args=(${BINUTILS_CONFIGURE_ARGS})" \
 && ../binutils-${BINUTILS_VERSION}/configure \
            --build="x86_64-pc-linux-gnu" \
            --target="${TARGET}" \
            --prefix="${PREFIX}" \
            --with-sysroot="${PREFIX}/${TARGET}" \
            --enable-gold \
            --disable-multilib \
            --disable-nls \
            --disable-werror \
            "${binutils_configure_args[@]}" \
 && make -j"$(nproc)" \
 && make install-strip \
 && GLOBIGNORE="" rm -rf ./*

WORKDIR /build-gcc-stage1
ARG GCC_CONFIGURE_ARGS=""
ARG GCC_STAGE1_CONFIGURE_ARGS=""
RUN eval "declare -a gcc_configure_args=(${GCC_CONFIGURE_ARGS})" \
 && eval "declare -a gcc_stage1_configure_args=(${GCC_STAGE1_CONFIGURE_ARGS})" \
 && ../gcc-${GCC_VERSION}/configure \
            --prefix="${PREFIX}" \
            --with-toolexeclibdir="${PREFIX}/${TARGET}/usr/lib" \
            --build="x86_64-pc-linux-gnu" \
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

WORKDIR /build-glibc
ARG GLIBC_CONFIGURE_ARGS=""
RUN eval "declare -a glibc_configure_args=(${GLIBC_CONFIGURE_ARGS})" \
 && ../glibc-${GLIBC_VERSION}/configure \
            --prefix="/usr" \
            --build="x86_64-pc-linux-gnu" \
            --host="${TARGET}" \
            --with-headers="${PREFIX}/${TARGET}/usr/include" \
            --enable-kernel=3.2 \
            --disable-multilib \
            --disable-nls \
            --disable-werror \
            "${glibc_configure_args[@]}" \
 && make -j"$(nproc)" \
 && make DESTDIR="${PREFIX}/${TARGET}" install \
 && GLOBIGNORE="" rm -rf ./*

WORKDIR /build-gcc-stage2
ARG GCC_STAGE2_CONFIGURE_ARGS=""
RUN eval "declare -a gcc_configure_args=(${GCC_CONFIGURE_ARGS})" \
 && eval "declare -a gcc_stage2_configure_args=(${GCC_STAGE2_CONFIGURE_ARGS})" \
 && ../gcc-${GCC_VERSION}/configure \
            --prefix="${PREFIX}" \
            --with-sysroot="${PREFIX}/${TARGET}" \
            --with-build-sysroot="${PREFIX}/${TARGET}" \
            --with-toolexeclibdir="${PREFIX}/${TARGET}/usr/lib" \
            --with-gxx-include-dir="${PREFIX}/${TARGET}/usr/include/c++" \
            --build="x86_64-pc-linux-gnu" \
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

ARG QEMU_ARCH
COPY --from=qemu /bin/sh /usr/bin/[q]emu-${QEMU_ARCH}-static ${PREFIX}/bin/

RUN rm -rf "${PREFIX}/bin/sh" "${PREFIX}/share/info" "${PREFIX}/share/man"


FROM debian:bullseye-slim

ARG PREFIX
ARG TARGET
ARG QEMU_ARCH
ARG KERNEL_VERSION
ARG BINUTILS_VERSION
ARG GCC_VERSION
ARG GLIBC_VERSION
ARG GMP_VERSION
ARG MPFR_VERSION
ARG MPC_VERSION
ARG DOCKERFILE_HASH=unset

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
    QEMU_SET_ENV="LD_LIBRARY_PATH=${PREFIX}/${TARGET}/usr/local/lib:${PREFIX}/${TARGET}/lib:${PREFIX}/${TARGET}/usr/lib"

LABEL org.opencontainers.image.source="https://github.com/cions/docker-crossdev" \
      crossdev.target="${TARGET}" \
      crossdev.kernel.version="${KERNEL_VERSION}" \
      crossdev.binutils.version="${BINUTILS_VERSION}" \
      crossdev.gcc.version="${GCC_VERSION}" \
      crossdev.glibc.version="${GLIBC_VERSION}" \
      crossdev.gmp.version="${GMP_VERSION}" \
      crossdev.mpfr.version="${MPFR_VERSION}" \
      crossdev.mpc.version="${MPC_VERSION}" \
      crossdev.dockerfile="${DOCKERFILE_HASH}"
