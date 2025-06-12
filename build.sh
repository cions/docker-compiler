#!/bin/bash

set -euo pipefail

: "${GCC:?GCC is not set}"
: "${TARGET:?TARGET is not set}"
: "${FORCE_BUILD:=false}"
: "${NO_PUSH:=false}"

binutils_configure_args=()
glibc_configure_args=()
gcc_configure_args=()
gcc_stage1_configure_args=()
gcc_stage2_configure_args=()
imagetags=()

case "${TARGET}" in
	aarch64-*)
		KERNEL_ARCH="arm64"
		QEMU_ARCH="aarch64"
		IMAGE_TAG="aarch64"
		;;
	alpha-*)
		KERNEL_ARCH="alpha"
		QEMU_ARCH="alpha"
		IMAGE_TAG="alpha"
		;;
	arm*-*)
		KERNEL_ARCH="arm"
		QEMU_ARCH="arm"
		IMAGE_TAG="arm"
		;;
	hppa-*)
		KERNEL_ARCH="parisc"
		QEMU_ARCH="hppa"
		IMAGE_TAG="hppa"
		;;
	i?86-*)
		KERNEL_ARCH="x86"
		QEMU_ARCH="i386"
		IMAGE_TAG="i386"
		;;
	ia64-*)
		KERNEL_ARCH="ia64"
		QEMU_ARCH="ia64"
		IMAGE_TAG="ia64"
		gcc_stage1_configure_args+=( "--with-system-libunwind" )
		;;
	loongarch64-*)
		KERNEL_ARCH="loongarch"
		QEMU_ARCH="loongarch64"
		IMAGE_TAG="loong64"
		;;
	m68k-*)
		KERNEL_ARCH="m68k"
		QEMU_ARCH="m68k"
		IMAGE_TAG="m68k"
		;;
	microblaze-*)
		KERNEL_ARCH="microblaze"
		QEMU_ARCH="microblaze"
		IMAGE_TAG="microblaze"
		;;
	mips-*)
		KERNEL_ARCH="mips"
		QEMU_ARCH="mips"
		IMAGE_TAG="mips"
		;;
	mipsel-*)
		KERNEL_ARCH="mips"
		QEMU_ARCH="mipsel"
		IMAGE_TAG="mipsel"
		;;
	mips64-*-gnuabi64)
		KERNEL_ARCH="mips"
		QEMU_ARCH="mips64"
		IMAGE_TAG="mips64"
		gcc_configure_args+=( "--with-abi=64" )
		;;
	mips64el-*-gnuabi64)
		KERNEL_ARCH="mips"
		QEMU_ARCH="mips64el"
		IMAGE_TAG="mips64el"
		gcc_configure_args+=( "--with-abi=64" )
		;;
	nios2-*)
		KERNEL_ARCH="nios2"
		QEMU_ARCH="nios2"
		IMAGE_TAG="nios2"
		;;
	or1k-*)
		KERNEL_ARCH="openrisc"
		QEMU_ARCH="or1k"
		IMAGE_TAG="or1k"
		;;
	powerpc-*)
		KERNEL_ARCH="powerpc"
		QEMU_ARCH="ppc"
		IMAGE_TAG="ppc"
		;;
	powerpc64-*)
		KERNEL_ARCH="powerpc"
		QEMU_ARCH="ppc64"
		IMAGE_TAG="ppc64"
		gcc_configure_args+=( "--with-long-double-128" )
		;;
	powerpc64le-*)
		KERNEL_ARCH="powerpc"
		QEMU_ARCH="ppc64le"
		IMAGE_TAG="ppc64le"
		gcc_configure_args+=( "--with-long-double-128" )
		;;
	riscv32-*)
		KERNEL_ARCH="riscv"
		QEMU_ARCH="riscv32"
		IMAGE_TAG="riscv32"
		glibc_configure_args+=( "libc_cv_slibdir=/lib" )
		;;
	riscv64-*)
		KERNEL_ARCH="riscv"
		QEMU_ARCH="riscv64"
		IMAGE_TAG="riscv64"
		glibc_configure_args+=( "libc_cv_slibdir=/lib" )
		;;
	s390x-*)
		KERNEL_ARCH="s390"
		QEMU_ARCH="s390x"
		IMAGE_TAG="s390x"
		;;
	sh4-*)
		KERNEL_ARCH="sh"
		QEMU_ARCH="sh4"
		IMAGE_TAG="sh4"
		gcc_configure_args+=( "--with-multilib-list=" )
		;;
	sparc-*)
		KERNEL_ARCH="sparc"
		QEMU_ARCH="sparc32plus"
		IMAGE_TAG="sparc"
		gcc_configure_args+=( "--with-cpu=v8" )
		;;
	sparc64-*)
		KERNEL_ARCH="sparc"
		QEMU_ARCH="sparc64"
		IMAGE_TAG="sparc64"
		;;
	x86_64-*)
		KERNEL_ARCH="x86_64"
		QEMU_ARCH="x86_64"
		IMAGE_TAG="x86_64"
		binutils_configure_args+=( "ac_cv_target=x86_64-cross-linux-gnu")
		gcc_configure_args+=( "ac_cv_target=x86_64-cross-linux-gnu")
		glibc_configure_args+=( "ac_cv_target=x86_64-cross-linux-gnu")
		;;
	xtensa-*)
		KERNEL_ARCH="xtensa"
		QEMU_ARCH="xtensa"
		IMAGE_TAG="xtensa"
		;;
	*)
		echo "Unsupported TARGET: ${TARGET}" >&2
		exit 1
esac

case "${TARGET}" in
	*-uclibc)
		DOCKERDIR="gcc-uclibc"
		UCLIBC_VERSION=1.0.52
		;;
	*)
		DOCKERDIR="gcc"
		;;
esac

case "${GCC}" in
	15)
		BUILDER=debian:bookworm
		BUILD_CC_VERSION=12
		KERNEL_VERSION=6.12.33
		BINUTILS_VERSION=2.44
		GCC_VERSION=15.1.0
		GLIBC_VERSION=2.41
		GMP_VERSION=6.3.0
		MPFR_VERSION=4.2.2
		MPC_VERSION=1.3.1
		imagetags+=( "15.1-${IMAGE_TAG}" "15-${IMAGE_TAG}" "${IMAGE_TAG}" )
		;;
	14)
		BUILDER=debian:bookworm
		BUILD_CC_VERSION=12
		KERNEL_VERSION=6.6.93
		BINUTILS_VERSION=2.42
		GCC_VERSION=14.3.0
		GLIBC_VERSION=2.39
		GMP_VERSION=6.3.0
		MPFR_VERSION=4.2.1
		MPC_VERSION=1.3.1
		imagetags+=( "14.3-${IMAGE_TAG}" "14-${IMAGE_TAG}" )
		;;
	13)
		BUILDER=debian:bookworm
		BUILD_CC_VERSION=12
		KERNEL_VERSION=6.1.141
		BINUTILS_VERSION=2.40
		GCC_VERSION=13.4.0
		GLIBC_VERSION=2.37
		GMP_VERSION=6.2.1
		MPFR_VERSION=4.2.0
		MPC_VERSION=1.3.1
		imagetags+=( "13.4-${IMAGE_TAG}" "13-${IMAGE_TAG}" )
		;;
	12)
		BUILDER=debian:bookworm
		BUILD_CC_VERSION=12
		KERNEL_VERSION=5.15.185
		BINUTILS_VERSION=2.40
		GCC_VERSION=12.4.0
		GLIBC_VERSION=2.37
		GMP_VERSION=6.2.1
		MPFR_VERSION=4.1.0
		MPC_VERSION=1.2.1
		imagetags+=( "12.4-${IMAGE_TAG}" "12-${IMAGE_TAG}" )
		;;
	11)
		BUILDER=debian:bullseye
		BUILD_CC_VERSION=10
		KERNEL_VERSION=5.10.238
		BINUTILS_VERSION=2.36
		GCC_VERSION=11.5.0
		GLIBC_VERSION=2.33
		GMP_VERSION=6.2.1
		MPFR_VERSION=4.1.0
		MPC_VERSION=1.2.1
		imagetags+=( "11.5-${IMAGE_TAG}" "11-${IMAGE_TAG}" )
		;;
	10)
		BUILDER=debian:bullseye
		BUILD_CC_VERSION=10
		KERNEL_VERSION=5.4.294
		BINUTILS_VERSION=2.34
		GCC_VERSION=10.5.0
		GLIBC_VERSION=2.31
		GMP_VERSION=6.2.0
		MPFR_VERSION=4.0.2
		MPC_VERSION=1.1.0
		imagetags+=( "10.5-${IMAGE_TAG}" "10-${IMAGE_TAG}" )
		;;
	9)
		BUILDER=debian:bullseye
		BUILD_CC_VERSION=9
		KERNEL_VERSION=4.19.325
		BINUTILS_VERSION=2.32
		GCC_VERSION=9.5.0
		GLIBC_VERSION=2.29
		GMP_VERSION=6.1.2
		MPFR_VERSION=4.0.2
		MPC_VERSION=1.1.0
		imagetags+=( "9.5-${IMAGE_TAG}" "9-${IMAGE_TAG}" )
		;;
	8)
		BUILDER=ubuntu:bionic
		BUILD_CC_VERSION=8
		KERNEL_VERSION=4.14.336
		BINUTILS_VERSION=2.30
		GCC_VERSION=8.5.0
		GLIBC_VERSION=2.27
		GMP_VERSION=6.1.2
		MPFR_VERSION=4.0.1
		MPC_VERSION=1.1.0
		imagetags+=( "8.5-${IMAGE_TAG}" "8-${IMAGE_TAG}" )
		;;
	7)
		BUILDER=ubuntu:bionic
		BUILD_CC_VERSION=7
		KERNEL_VERSION=4.9.337
		BINUTILS_VERSION=2.28
		GCC_VERSION=7.5.0
		GLIBC_VERSION=2.25
		GMP_VERSION=6.1.2
		MPFR_VERSION=3.1.5
		MPC_VERSION=1.0.3
		imagetags+=( "7.5-${IMAGE_TAG}" "7-${IMAGE_TAG}" )
		;;
	6)
		BUILDER=ubuntu:bionic
		BUILD_CC_VERSION=6
		KERNEL_VERSION=4.4.302
		BINUTILS_VERSION=2.26
		GCC_VERSION=6.5.0
		GLIBC_VERSION=2.23
		GMP_VERSION=6.1.0
		MPFR_VERSION=3.1.4
		MPC_VERSION=1.0.3
		glibc_configure_args+=( "libc_cv_ssp=no" "libc_cv_ssp_strong=no" )
		imagetags+=( "6.5-${IMAGE_TAG}" "6-${IMAGE_TAG}" )
		;;
	5)
		BUILDER=ubuntu:bionic
		BUILD_CC_VERSION=5
		KERNEL_VERSION=3.18.140
		BINUTILS_VERSION=2.24
		GCC_VERSION=5.5.0
		GLIBC_VERSION=2.21
		GMP_VERSION=5.1.3
		MPFR_VERSION=3.1.2
		MPC_VERSION=1.0.3
		glibc_configure_args+=( "libc_cv_ssp=no" )
		imagetags+=( "5.5-${IMAGE_TAG}" "5-${IMAGE_TAG}" )
		;;
	*)
		echo "Unsupported GCC: ${GCC}" >&2
		exit 1
esac

unsupported() {
	echo "Unsupported combination: GCC=${GCC}, TARGET=${TARGET}" >&2
	if [[ -n "${CI+set}" ]]; then
		exit 0
	fi
	exit 1
}

case "${GCC}:${TARGET}" in
	[5-9]:*-uclibc)
		KERNEL_VERSION=5.4.294
		;;
esac

case "${GCC}:${TARGET}" in
	7:hppa-*)
		GLIBC_VERSION=2.26
		;;
	5:hppa-*)
		GLIBC_VERSION=2.23
		;;
	5:ia64-* | 1[4-5]:ia64-*)
		unsupported
		;;
	11:ia64-*)
		BINUTILS_VERSION=2.34
		;;
	[5-9]:loongarch64-* | 1[0-2]:loongarch64-*)
		unsupported
		;;
	[5-6]:m68k-*)
		gcc_stage1_configure_args+=( '--with-headers="${PREFIX}/${TARGET}/usr/include"' )
		;;
	[5-7]:microblaze-*)
		unsupported
		;;
	1[4-5]:nios2-*)
		unsupported
		;;
	11:nios2-*)
		GLIBC_VERSION=2.34
		;;
	6:nios2-*)
		BINUTILS_VERSION=2.28
		;;
	5:nios2-*)
		KERNEL_VERSION=4.4.302
		BINUTILS_VERSION=2.28
		GLIBC_VERSION=2.23
		;;
	[5-9]:or1k-*)
		unsupported
		;;
	5:powerpc64*-*)
		GLIBC_VERSION=2.22
		;;
	[7-9]:riscv32-* | 10:riscv32-*)
		KERNEL_VERSION=5.4.294
		GLIBC_VERSION=2.33
		;;
	[7-8]:riscv64-*)
		KERNEL_VERSION=4.19.325
		BINUTILS_VERSION=2.30
		GLIBC_VERSION=2.27
		;;
	[5-6]:riscv*-*)
		unsupported
		;;
	[5-7]:sh4-*)
		BINUTILS_VERSION=2.30
		GLIBC_VERSION=2.26
		;;
	1[0-5]:sparc-*)
		gcc_configure_args+=( "--with-cpu=v9" )
		;;
	[5-9]:sparc-*)
		BINUTILS_VERSION=2.24
		GLIBC_VERSION=2.21
		gcc_stage2_configure_args+=(
			"--disable-libcilkrts"
			"--disable-libitm"
			"--disable-libsanitizer"
		)
		glibc_configure_args+=( "libc_cv_ssp=no" )
		;;
	[5-6]:sparc64-*)
		glibc_configure_args+=( 'CFLAGS="-g -O2 -Wa,-Av9a -mvis"' )
		;;
	5:x86_64-*)
		BINUTILS_VERSION=2.26
		;;
esac


DOCKERFILE_HASH="$(b2sum -l 256 "${DOCKERDIR}/Dockerfile" | awk '{ print $1 }')"

skip_to_build() {
	if [[ "${FORCE_BUILD}" != "false" ]]; then
		return 1
	fi

	TMPDIR="${RUNNER_TEMP:-"${TMPDIR:-/tmp}"}"

        go run github.com/regclient/regclient/cmd/regctl@latest image inspect \
		--format '{{json .Config.Labels}}' "ghcr.io/cions/gcc:${imagetags[0]}" > "${TMPDIR}/labels.json.in" || return 1
	jq -Sc '.' < "${TMPDIR}/labels.json.in" > "${TMPDIR}/labels.json"

	cat > "${TMPDIR}/expected.json.in" <<EOF
{
	"compiler.binutils.version": "${BINUTILS_VERSION}",
	"compiler.dockerfile": "${DOCKERFILE_HASH}",
	"compiler.gcc.version": "${GCC_VERSION}",
	"compiler.gmp.version": "${GMP_VERSION}",
	"compiler.kernel.version": "${KERNEL_VERSION}",
	"compiler.mpc.version": "${MPC_VERSION}",
	"compiler.mpfr.version": "${MPFR_VERSION}",
	"compiler.target": "${TARGET}",
	"org.opencontainers.image.source": "https://github.com/cions/docker-compiler"
}
EOF

	case "${DOCKERDIR}" in
		*-uclibc)
			jq -Sc --arg version "${UCLIBC_VERSION}" '.["compiler.uclibc.version"] |= $version' < "${TMPDIR}/expected.json.in" > "${TMPDIR}/expected.json"
			;;
		*)
			jq -Sc --arg version "${GLIBC_VERSION}" '.["compiler.glibc.version"] |= $version' < "${TMPDIR}/expected.json.in" > "${TMPDIR}/expected.json"
			;;
	esac

	printf "labels.json: "; jq -CS '.' "${TMPDIR}/labels.json"
	printf "Expected Labels: "; jq -CS '.' "${TMPDIR}/expected.json"

	diff -q "${TMPDIR}/labels.json" "${TMPDIR}/expected.json"
}

if skip_to_build; then
	echo "Image already exists. Skip to build." >&2
	exit 0
fi

echo "Configuration:"
echo "    DOCKERDIR: ${DOCKERDIR}"
echo "    DOCKERFILE_HASH: ${DOCKERFILE_HASH}"
echo "    BUILDER: ${BUILDER}"
echo "    BUILD_CC_VERSION: ${BUILD_CC_VERSION}"
echo "    TARGET: ${TARGET}"
echo "    KERNEL_ARCH: ${KERNEL_ARCH}"
echo "    QEMU_ARCH: ${QEMU_ARCH}"
echo "    KERNEL_VERSION: ${KERNEL_VERSION}"
echo "    BINUTILS_VERSION: ${BINUTILS_VERSION}"
echo "    GCC_VERSION: ${GCC_VERSION}"
echo "    GLIBC_VERSION: ${GLIBC_VERSION:-}"
echo "    UCLIBC_VERSION: ${UCLIBC_VERSION:-}"
echo "    GMP_VERSION: ${GMP_VERSION}"
echo "    MPFR_VERSION: ${MPFR_VERSION}"
echo "    MPC_VERSION: ${MPC_VERSION}"
echo "    BINUTILS_CONFIGURE_ARGS: ${binutils_configure_args[*]}"
echo "    GCC_CONFIGURE_ARGS: ${gcc_configure_args[*]}"
echo "    GCC_STAGE1_CONFIGURE_ARGS: ${gcc_stage1_configure_args[*]}"
echo "    GCC_STAGE2_CONFIGURE_ARGS: ${gcc_stage2_configure_args[*]}"
echo "    GLIBC_CONFIGURE_ARGS: ${glibc_configure_args[*]}"


buildargs=()

for tag in "${imagetags[@]}"; do
	buildargs+=(
		--tag "cions/gcc:${tag}"
		--tag "ghcr.io/cions/gcc:${tag}"
	)
done

buildargs+=(
	--build-arg BUILDER="${BUILDER}"
	--build-arg BUILD_CC_VERSION="${BUILD_CC_VERSION}"
	--build-arg DOCKERFILE_HASH="${DOCKERFILE_HASH}"
	--build-arg TARGET="${TARGET}"
	--build-arg KERNEL_ARCH="${KERNEL_ARCH}"
	--build-arg QEMU_ARCH="${QEMU_ARCH}"
	--build-arg KERNEL_VERSION="${KERNEL_VERSION}"
	--build-arg BINUTILS_VERSION="${BINUTILS_VERSION}"
	--build-arg GCC_VERSION="${GCC_VERSION}"
	--build-arg GMP_VERSION="${GMP_VERSION}"
	--build-arg MPFR_VERSION="${MPFR_VERSION}"
	--build-arg MPC_VERSION="${MPC_VERSION}"
	--build-arg BINUTILS_CONFIGURE_ARGS="${binutils_configure_args[*]}"
	--build-arg GCC_CONFIGURE_ARGS="${gcc_configure_args[*]}"
	--build-arg GCC_STAGE1_CONFIGURE_ARGS="${gcc_stage1_configure_args[*]}"
	--build-arg GCC_STAGE2_CONFIGURE_ARGS="${gcc_stage2_configure_args[*]}"
)

case "${DOCKERDIR}" in
	*-uclibc)
		buildargs+=(
			--build-arg UCLIBC_VERSION="${UCLIBC_VERSION}"
		)
		;;
	*)
		buildargs+=(
			--build-arg GLIBC_VERSION="${GLIBC_VERSION}"
			--build-arg GLIBC_CONFIGURE_ARGS="${glibc_configure_args[*]}"
		)
		;;
esac

execute() {
	if [[ -n "${GITHUB_ACTIONS+set}" ]]; then
		printf '[%s]%s\n' "command" "$*"
	else
		printf '\x1b[1;36m%s\x1b[0m\n' "$*"
	fi
	"$@"
}

execute docker build "${buildargs[@]}" "${DOCKERDIR}"

if [[ "${NO_PUSH}" == "false" ]]; then
	for tag in "${imagetags[@]}"; do
		execute docker push "cions/gcc:${tag}"
		execute docker push "ghcr.io/cions/gcc:${tag}"
	done
fi
