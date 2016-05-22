include(CheckCSourceCompiles)

function(check_inline)
    foreach(keyword inline __inline__ __inline)
        set(CMAKE_REQUIRED_DEFINITIONS "-Dinline=${keyword}")
        check_c_source_compiles(
"static inline void x(){}
int main(int argc, char **argv) { (void)argc; (void)argv; return 0; }"
            USE_INLINE_${keyword})
        if(USE_INLINE_${keyword})
            if(NOT keyword STREQUAL "inline")
                set(USE_INLINE ${keyword} PARENT_SCOPE)
            endif()
            break()
        endif()
    endforeach()
endfunction()
