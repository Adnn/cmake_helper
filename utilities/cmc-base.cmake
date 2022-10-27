# \brief Include the configuration file ouptut by conanfile's generate(), if any.
#
# \arg FILENAME optional filename of the conan generated cmake config file.
#               Defaults to 'conanuser_config.cmake'.
macro(cmc_include_conan_configuration)
    set(optionsArgs "")
    set(oneValueArgs "FILENAME")
    set(multiValueArgs "")
    cmake_parse_arguments(CAS "${optionsArgs}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    set(_filename "${CAS_FILENAME}")
    if (NOT _filename)
        set(_filename "generators/conanuser_config.cmake")
    endif()

    include(${PROJECT_BINARY_DIR}/${_filename} OPTIONAL)
    ## MultiConfigGenerator (like MSVC) do not create a build_type subfolder
    ## SingleConfigGenerator (like Clang) create a build_type subfolder
    ## thus their binary folder do not contain the generators folder it is in their parent folder
    include(${PROJECT_BINARY_DIR}/../${_filename} OPTIONAL)
endmacro()


## \brief Configures TARGET so downstream and itself can find its headers with #include<> syntax.
##
## Allows downstream to include <${TARGET}/[xx/]yy.h> from both build and install trees.
## Also allows this project to include its own headers from the build tree using a similar syntax.
##
## \arg BUILDTREE_DIRECTORY optional path set as the include directory for the build tree,
##                          defaults to the parent of the current source dir.
## \arg ADD_BINARY_DIR optional if specified, add the current binary dir with provided visibility.
function(cmc_target_current_include_directory TARGET)
    set(optionsArgs "")
    set(oneValueArgs "BUILDTREE_DIRECTORY;ADD_BINARY_DIR")
    set(multiValueArgs "")
    cmake_parse_arguments(CAS "${optionsArgs}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    set(_buildtree_dir "${CAS_BUILDTREE_DIRECTORY}")
    if (NOT _buildtree_dir)
        set(_buildtree_dir "${CMAKE_CURRENT_SOURCE_DIR}/..")
    endif()
    # Normalize the path
    cmake_path(NORMAL_PATH _buildtree_dir)

    target_include_directories(${TARGET}
        INTERFACE
            $<BUILD_INTERFACE:${_buildtree_dir}>
            # This target subdir is intended as a separation layer:
            # Actual headers should be installed in include/${TARGET}/${TARGET}
            # and included as `#include<${TARGET}/yy.h` as to not expose sibling components
            $<INSTALL_INTERFACE:include/${TARGET}>)

    # Unless the target is an INTERFACE library, its headers are made accessible to its build tree
    get_target_property(_target_type ${TARGET} TYPE)
    if(NOT _target_type STREQUAL INTERFACE_LIBRARY)
        target_include_directories(${TARGET}
            PRIVATE
                $<BUILD_INTERFACE:${_buildtree_dir}>)
    endif()

    # Add the current binary dir if the option is specified
    if (CAS_ADD_BINARY_DIR)
        target_include_directories(${TARGET}
            ${CAS_ADD_BINARY_DIR}
                $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}>)
    endif()
endfunction()


## \brief Find dependencies by configuring a find file then including the result.
##
## The input template should look like a normal list of find_package(...)
## except that "find_package", "QUIET" and "REQUIRED" should all be enclosed in '@'.
## This function will only remove the enclosing '@' and invoke the resulting file,
## yet the template will later be usable by cmc_install_packageconfig where substitutions occur.
##
## \arg FILE optional input template, defaults to "CMakeFinds.cmake.in".
function(cmc_find_dependencies)
    set(optionsArgs "")
    set(oneValueArgs "FILE")
    set(multiValueArgs "")
    cmake_parse_arguments(CAS "${optionsArgs}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    set(_file "${CAS_FILE}")
    if (NOT _file)
        set(_file "CMakeFinds.cmake.in")
    endif()

    set(REQUIRED "REQUIRED")
    set(QUIET "QUIET")
    set(find_package "find_package") # Use the actual find_package function
    configure_file(${_file} CMakeFinds.cmake @ONLY)
    include(${CMAKE_CURRENT_BINARY_DIR}/CMakeFinds.cmake)
endfunction()
