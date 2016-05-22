include(CMakeParseArguments)
include(CheckCSourceCompiles)

function(check_target_feature SOURCE FLAGS RESULT_VAR DESCRIPTION)
    cmake_parse_arguments("" "" "MSVC" "" ${ARGN})

    if(DEFINED ${RESULT_VAR})
        # We got a -D${RESULT_VAR}=... on command line; just put it
		# into the cache.
    elseif(MSVC)
        # Win32 has hardcoded default values
		if(${_MSVC})
			set(${RESULT_VAR} ON)
		else()
			set(${RESULT_VAR} OFF)
		endif()
    else()
        # Autodetect the feature (and then put it into cache).
        if(FLAGS MATCHES -x)
            # Only pass -x to compiler, not linker.
            set(CMAKE_REQUIRED_DEFINITIONS "${FLAGS}")
        else()
            set(CMAKE_REQUIRED_FLAGS "${FLAGS}")
        endif()
        check_c_source_compiles("${SOURCE}" ${RESULT_VAR})
    endif()
    set(${RESULT_VAR} ${${RESULT_VAR}} CACHE BOOL ${DESCRIPTION})
endfunction()
