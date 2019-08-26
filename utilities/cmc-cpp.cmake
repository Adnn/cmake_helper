function(cmc_cpp_all_warnings_as_errors TARGET)

    set(gnuoptions "AppleClang" "Clang" "GNU")
    if (CMAKE_CXX_COMPILER_ID IN_LIST gnuoptions)
        set(option "-Werror")
    elseif(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
        set(option "-WX")
    endif()

    # Enables all warnings
    # Except on Windows, where all warnings create too many problems with system headers
    if (NOT WIN32)
        target_compile_options(${TARGET} PRIVATE -Wall)
    endif()

    target_compile_options(${TARGET} PRIVATE ${option})
    target_link_libraries(${TARGET} PRIVATE ${option})

endfunction()
