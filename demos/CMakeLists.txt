include_directories(
    ${GTK_INCLUDE_DIRS})
link_directories(
    ${GTK_LIBRARY_DIRS})
add_definitions(
    ${GTK_CFLAGS_OTHER})

set(DEMOS
    clip-test
    clip-in
    composite-test
    gradient-test
    radial-test
    linear-gradient
    conical-test
    alpha-test
    screen-test
    convolution-test
    trap-test
    tri-test
    quad2quad
    checkerboard
    srgb-trap-test
    srgb-test
    scale
)

add_library(pixman_gtk_utils STATIC
    gtk-utils.c
    gtk-utils.h)
target_link_libraries(pixman_gtk_utils
    pixman_test_utils
    ${GTK_LIBRARIES})

foreach(program ${DEMOS})
    add_executable(pixman_${program}
        ${program}.c)
    set_target_properties(pixman_${program} PROPERTIES
        OUTPUT_NAME ${program})
    target_link_libraries(pixman_${program}
        pixman_gtk_utils)
endforeach()
