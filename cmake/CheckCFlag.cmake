include(CheckCSourceCompiles)

function(check_c_flag FLAG)
    string(REPLACE "-" "_" ESCAPED_FLAG ${FLAG})

    set(CMAKE_REQUIRED_FLAGS ${FLAG})
    check_c_source_compiles(
"int main(int argc, char **argv) { (void)argc; (void)argv; return 0; }"
        HAS${ESCAPED_FLAG})
    if(${HAS${ESCAPED_FLAG}})
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${FLAG}" PARENT_SCOPE)
    endif()
endfunction()
