set(TESTPROGRAMS
    oob-test
    infinite-loop
    trap-crasher
    fence-image-self-test
    region-translate-test
    fetch-test
    a1-trap-test
    prng-test
    radial-invalid
    pdf-op-test
    region-test
    combiner-test
    scaling-crash-test
    alpha-loop
    scaling-helpers-test
    thread-test
    rotate-test
    alphamap
    gradient-crash-test
    pixel-test
    matrix-test
    composite-traps-test
    region-contains-test
    glyph-test
    solid-test
    stress-test
    cover-test
    blitters-test
    affine-test
    scaling-test
    composite
    tolerance-test
)

set(OTHERPROGRAMS
    lowlevel-blt-bench
    radial-perf-test
    check-formats
    scaling-bench
    affine-bench
)

add_library(pixman_test_utils STATIC
    utils.c
    utils-prng.c
    utils.h
    utils-prng.h)
target_link_libraries(pixman_test_utils
    pixman)

foreach(program ${TESTPROGRAMS} ${OTHERPROGRAMS})
    add_executable(pixman_${program}
        ${program}.c)
    set_target_properties(pixman_${program} PROPERTIES
        OUTPUT_NAME ${program})
    target_link_libraries(pixman_${program}
        pixman_test_utils)
endforeach()

foreach(program ${TESTPROGRAMS})
    add_test(NAME ${program} COMMAND pixman_${program})
    set_tests_properties(${program} PROPERTIES SKIP_RETURN_CODE 77)
endforeach()
