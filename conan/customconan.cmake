# Cannot be a function: some invoked macro modify global variables
macro(conan_handle_compiler_settings)
    include(${CMAKE_BINARY_DIR}/conanbuildinfo.cmake)

    if(CONAN_EXPORTED)
        conan_message(STATUS "Conan: called by CMake conan helper")
    endif()

    if(CONAN_IN_LOCAL_CACHE)
        conan_message(STATUS "Conan: called inside local cache")
    endif()

    check_compiler_version()
    conan_set_std()
    conan_set_libcxx()
    conan_set_vs_runtime()
    # Since 3.15, setting the runtime flags explicitly does not work anymore
    set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
    if(CONAN_LINK_RUNTIME IN_LIST "/MD;/MDd")
            set(CMAKE_MSVC_RUNTIME_LIBRARY "${CMAKE_MSVC_RUNTIME_LIBRARY}DLL")
    endif()
endmacro()

include(${CMAKE_BINARY_DIR}/conan_paths.cmake)
conan_handle_compiler_settings()
