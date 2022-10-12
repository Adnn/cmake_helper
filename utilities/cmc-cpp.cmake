## \brief Enable all warnings as error for provided TARGET.
##        Additionally raises the warning level except for MSVC.
function(cmc_cpp_all_warnings_as_errors TARGET)
    set(oneValueArgs "ENABLED")
    cmake_parse_arguments(CAS "${optionsArgs}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    # If the optional one-value-arg ENABLED is omitted, warning_as_error is also enabled.
    if (NOT DEFINED CAS_ENABLED OR CAS_ENABLED)
        set(gnuoptions "AppleClang" "Clang" "GNU")
        if (CMAKE_CXX_COMPILER_ID IN_LIST gnuoptions)
            set(option "-Werror")
            # Enables all warnings
            # Except on MSVC, where all warnings create too many problems with system headers
            target_compile_options(${TARGET} PRIVATE "-Wall")
        elseif(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
            set(option "-WX")
            target_compile_options(${TARGET} PRIVATE "-W3")
            # Disable specific warnings
            # ASAN enabled without debug information emission. Enable debug info for better ASAN error reporting
            target_compile_options(${TARGET} PRIVATE "/wd5072")
            # ASAN recommendation to use /DEBUG
            target_link_options(${TARGET} PRIVATE "/ignore:4302")
        endif()

        # The option is given as both compile option and link option
        # Note:: target_link_options is only available from 3.13
        target_compile_options(${TARGET} PRIVATE ${option})
        target_link_options(${TARGET} PRIVATE ${option})
    endif()

endfunction()


## \brief Define a CMake variable containing the enumeration of available sanitizers.
function(cmc_cpp_define_sanitizer_enum)
    set(sanitizers "None" "Address")
    set(BUILD_CONF_Sanitizer "None" CACHE STRING "Enable a sanitizer.")
    set_property(CACHE BUILD_CONF_Sanitizer PROPERTY STRINGS ${sanitizers})
endfunction()


## \brief Enable (Clang) sanitizers.
function(cmc_cpp_sanitizer TARGET TYPE)
    if (TYPE STREQUAL "None")
        # nothing to do here
    elseif (TYPE STREQUAL "Address")
        set(gnuoptions "AppleClang" "Clang" "GNU")
        if (CMAKE_CXX_COMPILER_ID IN_LIST gnuoptions)
            target_compile_options(${TARGET_NAME} PRIVATE /fsanitize=address)
            target_link_options(${TARGET_NAME} PRIVATE /fsanitize=address)
        elseif(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
            target_compile_options(${TARGET_NAME} PRIVATE /fsanitize=address)
            target_link_options(${TARGET_NAME} PRIVATE /INCREMENTAL:NO)
            # Apparently not recognized by MSVC linker, leading to a warning
            #target_link_options(${TARGET_NAME} PRIVATE /fsanitize=address)
        endif()
    else()
        message(SEND_ERROR "Sanitizer type '${TYPE}' not supported. Aborting.")
    endif()
endfunction()
