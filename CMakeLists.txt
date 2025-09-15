project(pixman C ASM)
cmake_minimum_required(VERSION 3.0)
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH}
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/")

include(CheckTypeSize)
include(CheckIncludeFile)
include(CheckFunctionExists)
include(CheckLibraryExists)
include(CheckSymbolExists)
include(CheckInline)
include(CheckCFlag)
include(CheckTargetFeature)

# Versioning
file(READ meson.build meson_build)
string(REGEX REPLACE ".*version : '([0-9]+\\.[0-9]+\\.[0-9]+)'.*" "\\1"
                     PIXMAN_VERSION ${meson_build})
string(REGEX REPLACE "([0-9]+)\\.[0-9]+\\.[0-9]+" "\\1"
                     PIXMAN_VERSION_MAJOR ${PIXMAN_VERSION})
string(REGEX REPLACE "[0-9]+\\.([0-9]+)\\.[0-9]+" "\\1"
                     PIXMAN_VERSION_MINOR ${PIXMAN_VERSION})
string(REGEX REPLACE "[0-9]+\\.[0-9]+\\.([0-9]+)" "\\1"
                     PIXMAN_VERSION_MICRO ${PIXMAN_VERSION})
message(STATUS "Building pixman version ${PIXMAN_VERSION}")

# Building
set(PIXMAN_BUILD_TESTS  ON CACHE BOOL "Build and run regression tests")
set(PIXMAN_BUILD_DEMOS  ON CACHE BOOL "Build demo code")

if(PIXMAN_BUILD_TESTS)
    enable_testing()
endif()

# Configuration
include_directories(
    ${CMAKE_CURRENT_BINARY_DIR}/pixman
    ${CMAKE_CURRENT_SOURCE_DIR}/pixman
)

find_library(LIBM_LIBRARY m)
if(LIBM_LIBRARY)
    set(CMAKE_REQUIRED_LIBRARIES ${LIBM_LIBRARY})
endif()

set(WORDS_BIGENDIAN ${CMAKE_WORDS_BIGENDIAN})
check_inline()

check_function_exists(getisax HAVE_GETISAX)
check_type_size(long SIZEOF_LONG)

if(NOT MSVC)
	check_c_flag(-Wall)
	check_c_flag(-Wdeclaration-after-statement)
	check_c_flag(-Wno-unused-local-typedefs)
	check_c_flag(-fno-strict-aliasing)
endif()

if(NOT MSVC)
    # Currently, OpenMP code cannot be built with MSVC; it fails with
    # "utils.h:23: 'threadprivate' is only valid for global or static data items"
    find_package(OpenMP)
    if(OPENMP_FOUND)
       set(USE_OPENMP ${OPENMP_FOUND})
       set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${OpenMP_C_FLAGS}")
    endif()
endif()

set(LOONGSON_MMI_FLAGS "-march=loongson2f")
check_target_feature(
"#ifndef __mips_loongson_vector_rev
#error Loongson Multimedia Instructions are only available on Loongson
#endif
#if defined(__GNUC__) && (__GNUC__ < 4 || (__GNUC__ == 4 && __GNUC_MINOR__ < 4))
#error Need GCC >= 4.4 for Loongson MMI compilation
#endif
#include <pixman/loongson-mmintrin.h>
int main () {
    union {
        __m64 v;
        char c[8];
    } a = { .c = {1, 2, 3, 4, 5, 6, 7, 8} };
    int b = 4;
    __m64 c = _mm_srli_pi16 (a.v, b);
    return 0;
}"
    "${LOONGSON_MMI_FLAGS} -I${CMAKE_CURRENT_SOURCE_DIR}"
    USE_LOONGSON_MMI "Enable Loongson MMI fast paths"
    MSVC OFF)

if(MSVC)
    set(X86_MMX_FLAGS "-w14710 -w14714")
else()
    set(X86_MMX_FLAGS "-mmmx -Winline")
endif()
if(${CMAKE_SIZEOF_VOID_P} EQUAL 4)
    set(USE_X86_MMX_MSVC ON)
else()
    set(USE_X86_MMX_MSVC OFF)
endif()
check_target_feature(
"#if defined(__GNUC__) && (__GNUC__ < 3 || (__GNUC__ == 3 && __GNUC_MINOR__ < 4))
#error Need GCC >= 3.4 for MMX intrinsics
#endif
#include <mmintrin.h>
#include <stdint.h>

/* Check support for block expressions */
#define _mm_shuffle_pi16(A, N)                      \\\\
    ({                                  \\\\
    __m64 ret;                          \\\\
                                    \\\\
    /* Some versions of clang will choke on K */            \\\\
    asm (\"pshufw %2, %1, %0\\\\n\\\\t\"                    \\\\
         : \"=y\" (ret)                       \\\\
         : \"y\" (A), \"K\" ((const int8_t)N)               \\\\
    );                              \\\\
                                    \\\\
    ret;                                \\\\
    })

int main () {
    __m64 v = _mm_cvtsi32_si64 (1);
    __m64 w;

    w = _mm_shuffle_pi16(v, 5);

    /* Some versions of clang will choke on this */
    asm (\"pmulhuw %1, %0\\\\n\\\\t\"
    : \"+y\" (w)
    : \"y\" (v)
    );

    return _mm_cvtsi64_si32 (v);
}"
    "${X86_MMX_FLAGS}"
    USE_X86_MMX "Use x86 MMX compiler intrinsics"
    MSVC ${USE_X86_MMX_MSVC})

if(MSVC)
    set(SSE2_FLAGS "")
else()
    set(SSE2_FLAGS "-msse2 -Winline")
endif()
check_target_feature(
"#if defined(__GNUC__) && (__GNUC__ < 4 || (__GNUC__ == 4 && __GNUC_MINOR__ < 2))
#   if !defined(__amd64__) && !defined(__x86_64__)
#      error Need GCC >= 4.2 for SSE2 intrinsics on x86
#   endif
#endif
#include <mmintrin.h>
#include <xmmintrin.h>
#include <emmintrin.h>
int param;
int main () {
    __m128i a = _mm_set1_epi32 (param), b = _mm_set1_epi32 (param + 1), c;
    c = _mm_xor_si128 (a, b);
    return _mm_cvtsi128_si32(c);
}"
    "${SSE2_FLAGS}"
    USE_SSE2 "Use SSE2 compiler intrinsics"
    MSVC ON)

if(MSVC)
    set(SSSE3_FLAGS "")
else()
    set(SSSE3_FLAGS "-mssse3 -Winline")
endif()
check_target_feature(
"#include <mmintrin.h>
#include <xmmintrin.h>
#include <emmintrin.h>
#include <tmmintrin.h>
int param;
int main () {
    __m128i a = _mm_set1_epi32 (param), b = _mm_set1_epi32 (param + 1), c;
    c = _mm_maddubs_epi16 (a, b);
    return _mm_cvtsi128_si32(c);
}"
    "${SSSE3_FLAGS}"
    USE_SSSE3 "Use SSSE3 compiler intrinsics"
    MSVC ON)

if(APPLE)
    set(VMX_FLAGS "-faltivec")
else()
    set(VMX_FLAGS "-maltivec -mabi=altivec")
endif()
check_target_feature(
"#if defined(__GNUC__) && (__GNUC__ < 3 || (__GNUC__ == 3 && __GNUC_MINOR__ < 4))
#error Need GCC >= 3.4 for sane altivec support
#endif
#include <altivec.h>
int main () {
    vector unsigned int v = vec_splat_u32 (1);
    v = vec_sub (v, v);
    return 0;
}"
    "${VMX_FLAGS}"
    USE_VMX "Use VMX compiler intrinsics"
    MSVC OFF)

check_target_feature(
".text
.arch armv6
.object_arch armv4
.arm
.altmacro
#ifndef __ARM_EABI__
#error EABI is required (to be sure that calling conventions are compatible)
#endif
.globl main
main:
pld [r0]
uqadd8 r0, r0, r0"
    "-x assembler-with-cpp"
    USE_ARM_SIMD "Use ARM SIMD assembly optimizations"
    MSVC OFF)

check_target_feature(
".text
.fpu neon
.arch armv7a
.object_arch armv4
.eabi_attribute 10, 0
.arm
.altmacro
#ifndef __ARM_EABI__
#error EABI is required (to be sure that calling conventions are compatible)
#endif
.globl main
main:
pld [r0]
vmovn.u16 d0, q0"
    "-x assembler-with-cpp"
    USE_ARM_NEON "Use ARM NEON assembly optimizations"
    MSVC OFF)

set(IWMMXT_FLAGS "-flax-vector-conversions -Winline -march=iwmmxt")
set(PIXMAN_ENABLE_IWMMXT2 ON CACHE BOOL
    "Build ARM IWMMXT fast paths with -march=iwmmxt2")
if(PIXMAN_ENABLE_IWMMXT2)
    set(IWMMXT_FLAGS "${IWMMXT_FLAGS}2")
endif()
check_target_feature(
"#ifndef __arm__
#error IWMMXT is only available on ARM
#endif
#ifndef __IWMMXT__
#error IWMMXT not enabled (with -march=iwmmxt)
#endif
#if defined(__GNUC__) && (__GNUC__ < 4 || (__GNUC__ == 4 && __GNUC_MINOR__ < 8))
#error Need GCC >= 4.8 for IWMMXT intrinsics
#endif
#include <mmintrin.h>
int main () {
    union {
        __m64 v;
        char c[8];
    } a = { .c = {1, 2, 3, 4, 5, 6, 7, 8} };
    int b = 4;
    __m64 c = _mm_srli_si64 (a.v, b);
}"
    "${IWMMXT_FLAGS}"
    USE_ARM_IWMMXT "Use ARM IWMMXT compiler intrinsics"
    MSVC OFF)

set(MIPS_DSPR2_FLAGS "-mdspr2")
check_target_feature(
"#if !(defined(__mips__) &&  __mips_isa_rev >= 2)
#error MIPS DSPr2 is currently only available on MIPS32r2 platforms.
#endif
int
main ()
{
    int c = 0, a = 0, b = 0;
    __asm__ __volatile__ (
        \"precr.qb.ph %[c], %[a], %[b]          \\\\n\\\\t\"
        : [c] \"=r\" (c)
        : [a] \"r\" (a), [b] \"r\" (b)
    );
    return c;
}"
    "${MIPS_DSPR2_FLAGS}"
    USE_MIPS_DSPR2 "Enable MIPS DSPr2 fast paths"
    MSVC OFF)

check_c_source_compiles(
"int main () {
    /* Most modern architectures have a NOP instruction, so this is a fairly generic test. */
    asm volatile ( \"\\\\tnop\\\\n\" : : : \"cc\", \"memory\" );
    return 0;
}"
    USE_GCC_INLINE_ASM)

find_package(PkgConfig)
if(PKGCONFIG_FOUND)
    pkg_check_modules(GTK gtk+-2.0>=2.16)
endif()

set(PIXMAN_TIMERS OFF CACHE BOOL "Enable TIMER_BEGIN/TIMER_END macros")

check_function_exists(posix_memalign      HAVE_POSIX_MEMALIGN)
check_function_exists(sigaction           HAVE_SIGACTION)
check_function_exists(alarm               HAVE_ALARM)
check_include_file   (sys/mman.h          HAVE_SYS_MMAN_H)
check_function_exists(mmap                HAVE_MMAP)
check_function_exists(mprotect            HAVE_MPROTECT)
check_function_exists(getpagesize         HAVE_GETPAGESIZE)
check_include_file   (fenv.h              HAVE_FENV_H)
check_function_exists(feenableexcept      HAVE_FEENABLEEXCEPT)
check_symbol_exists  (FE_DIVBYZERO fenv.h HAVE_FEDIVBYZERO)
check_function_exists(gettimeofday        HAVE_GETTIMEOFDAY)
check_c_source_compiles(
"#include <math.h>
int main() {sqrtf(0.0); return 0;}"
	HAVE_SQRTF)
if(NOT HAVE_SQRTF)
    set(sqrtf sqrt)
endif()

foreach(keyword "__thread" "__declspec(thread)")
    check_c_source_compiles(
"#if defined(__MINGW32__) && !(__GNUC__ > 4 || (__GNUC__ == 4 && __GNUC_MINOR__ >= 5))
#error This MinGW version has broken __thread support
#endif
#ifdef __OpenBSD__
#error OpenBSD has broken __thread support
#endif

int ${keyword} test;
int main() { return 0; }"
        HAVE_TLS_${keyword})
    if(HAVE_TLS_${keyword})
        set(TLS ${keyword})
        break()
    endif()
endforeach()

find_package(Threads)
set(HAVE_PTHREADS ${CMAKE_USE_PTHREADS_INIT})
link_libraries(${CMAKE_THREAD_LIBS_INIT})

check_c_source_compiles(
"#if defined(__GNUC__) && (__GNUC__ > 2 || (__GNUC__ == 2 && __GNUC_MINOR__ >= 7))
/* attribute 'constructor' is supported since gcc 2.7, but some compilers
 * may only pretend to be gcc, so let's try to actually use it
 */
static int x = 1;
static void __attribute__((constructor)) constructor_function () { x = 0; }
int main (void) { return x; }
#else
#error not gcc or gcc version is older than 2.7
#endif"
    TOOLCHAIN_SUPPORTS_ATTRIBUTE_CONSTRUCTOR)

check_c_source_compiles(
"__float128 a = 1.0Q, b = 2.0Q; int main (void) { return a + b; }"
    HAVE_FLOAT128)

check_c_source_compiles(
"unsigned int x = 11; int main (void) { return __builtin_clz(x); }"
    HAVE_BUILTIN_CLZ)

check_c_source_compiles(
"unsigned int __attribute__ ((vector_size(16))) e, a, b;
int main (void) { e = a - ((b << 27) + (b >> (32 - 27))) + 1; return e[0]; }"
    HAVE_GCC_VECTOR_EXTENSIONS)

set(HAVE_LIBPNG ${PNG_FOUND})

add_definitions(-DHAVE_CONFIG_H)
configure_file(
    cmake/config.h.in
    ${CMAKE_CURRENT_BINARY_DIR}/pixman/pixman-config.h)

# Components
add_subdirectory(pixman)
if(PIXMAN_BUILD_TESTS)
    add_subdirectory(test)
endif()
if(PIXMAN_BUILD_DEMOS AND GTK_FOUND)
    add_subdirectory(demos)
endif()
