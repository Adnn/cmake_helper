## \brief Installs the provided files (optionally adding the DESTINATION prefix)
##        while preserving the relative path of each file (i.e. recreating folder hierarchy).
##
## \arg DESTINATION required path that will be prefixed to the provided FILES
## \arg FILES list of relative paths to files, prepended with DESTINATION when installed
function(cmc_install_with_folders)
    set(optionsArgs "")
    set(oneValueArgs "DESTINATION")
    set(multiValueArgs "FILES")
    cmake_parse_arguments(CAS "${optionsArgs}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )

    if (NOT CAS_DESTINATION)
        message(AUTHOR_WARNING "DESTINATION value is required, skip installation for FILES")
        return()
    endif()

    foreach(_file ${CAS_FILES})
        get_filename_component(_dir ${_file} DIRECTORY)
        install(FILES ${_file} DESTINATION ${CAS_DESTINATION}/${_dir})
    endforeach()
endfunction()


## \brief Internal helper function to generate config check files in both buid and install trees.
##
function(_version_files PACKAGE_NAME INSTALL_DESTINATION VERSION VERSION_COMPATIBILITY)
    # Build tree
    include(CMakePackageConfigHelpers)
    write_basic_package_version_file(${CMAKE_BINARY_DIR}/${PACKAGE_NAME}ConfigVersion.cmake
                                     VERSION ${VERSION}
                                     COMPATIBILITY ${VERSION_COMPATIBILITY})
    # Install tree
    install(FILES ${CMAKE_BINARY_DIR}/${PACKAGE_NAME}ConfigVersion.cmake
            DESTINATION ${INSTALL_DESTINATION})
endfunction()


## \brief Generate a package config file for TARGET, making it available:
##        * (at configure time) in the build tree
##        * (at install time) in the install tree
##
## \arg EXPORTNAME Name of the export set for which targets files are generated.
## \arg FIND_FILE optional find file templates (see cmc_find_dependencies for syntax), invoked
##      by the generated Config file for TARGET. Allows finding external dependencies, while
##      keeping the list of said external dependencies DRY (thanks to the template re-use).
## \arg VERSION_COMPATIBILITY optional version compatibility mode for the created package.
##      Accepted values are the values for COMPATIBILITY of write_basic_package_version_file:
##      https://cmake.org/cmake/help/latest/module/CMakePackageConfigHelpers.html#generating-a-package-version-file
##      When absent, no version checks are made.
##      When provided, the VERSION property of TARGET will be used as package version.
## \arg DEPENDS_COMPONENTS optional list of internal dependencies (i.e, other targets defined under
##      the same top level CMake project). Invoked by the generated Config file for TARGET.
##      Allows to satisfy internal dependencies when the package is found by downstream.
## \arg NAMESPACE Prepended to all targets written in the export set.
function(cmc_install_packageconfig TARGET EXPORTNAME)
    set(optionsArgs "")
    set(oneValueArgs "NAMESPACE" "FIND_FILE" "VERSION_COMPATIBILITY")
    set(multiValueArgs "DEPENDS_COMPONENTS")
    cmake_parse_arguments(CAS "${optionsArgs}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )

    # suffixes with **root** project name, to group with root config in case of componentized repo
    set(_main_config_name ${CMAKE_PROJECT_NAME})
    set(_install_destination ${CMC_INSTALL_CONFIGPACKAGE_PREFIX}/${_main_config_name})

    # If a find file is provided to find upstreams
    set(_findupstream_file ${TARGET}FindUpstream.cmake)
    if (CAS_FIND_FILE)
        # No value for REQUIRED and QUIET substition, to remove them
        set (find_package "find_dependency")
        # build tree
        configure_file(${CAS_FIND_FILE} ${CMAKE_BINARY_DIR}/${_findupstream_file} @ONLY)
        #install tree
        install(FILES ${CMAKE_BINARY_DIR}/${_findupstream_file}
                DESTINATION ${_install_destination})
    endif()

    # If a list of required internal components is provided
    if (CAS_DEPENDS_COMPONENTS)
        list(JOIN CAS_DEPENDS_COMPONENTS " " _joined_components)
        set(FIND_INTERNAL_COMPONENTS
            "find_dependency(${_main_config_name} CONFIG COMPONENTS ${_joined_components})")
    endif()

    set(_targetfile "${EXPORTNAME}.cmake")

    # Generate config files in the build tree
    configure_file(${CMC_ROOT_DIR}/templates/PackageConfig.cmake.in
                   ${CMAKE_BINARY_DIR}/${TARGET}Config.cmake
                   @ONLY)

    # Install the config file over to the install tree
    install(
        FILES ${CMAKE_BINARY_DIR}/${TARGET}Config.cmake
        DESTINATION ${_install_destination})

    # build tree
    export(EXPORT ${EXPORTNAME}
        NAMESPACE ${CAS_NAMESPACE}::
        FILE ${CMAKE_BINARY_DIR}/${_targetfile})

    # install tree
    install(EXPORT ${EXPORTNAME}
        FILE ${_targetfile}
        DESTINATION ${_install_destination}
        NAMESPACE ${CAS_NAMESPACE}::)

    #
    # Optional version logic
    #
    if (CAS_VERSION_COMPATIBILITY)
        get_target_property(_version ${TARGET} VERSION)
        if(NOT _version)
            message(SEND_ERROR "VERSION property must be set on target ${TARGET} before setting its VERSION_COMPATIBILITY")
        endif()
        _version_files(${TARGET} ${_install_destination} ${_version} ${CAS_VERSION_COMPATIBILITY})
    endif()
endfunction()


## \brief Generate the root package config file for a project providing several components
##        (typically, a repository containing several libraries).
##
## \arg VERSION_COMPATIBILITY optional version compatibility mode for the created package.
##      Accepted values are the values for COMPATIBILITY of write_basic_package_version_file:
##      https://cmake.org/cmake/help/latest/module/CMakePackageConfigHelpers.html#generating-a-package-version-file
##      When absent, no version checks are made.
##      When provided, CMAKE_PROJECT_VERSION will be used as package version.
##
## This config file should be found by downstream in its call to find_package(... COMPONENTS ...)
function(cmc_install_root_component_config)
    set(oneValueArgs "VERSION_COMPATIBILITY")
    cmake_parse_arguments(CAS "${optionsArgs}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )

    # Ensures the root config is found when looking for the name of the root project
    set(PACKAGE_NAME "${CMAKE_PROJECT_NAME}")

    # Generate root config files in the build tree
    configure_file(${CMC_ROOT_DIR}/templates/ComponentPackageRootConfig.cmake.in 
                   ${CMAKE_BINARY_DIR}/${PACKAGE_NAME}Config.cmake
                   @ONLY)

    # Install the root config file over to the install tree
    install(FILES ${CMAKE_BINARY_DIR}/${PACKAGE_NAME}Config.cmake
            DESTINATION ${CMC_INSTALL_CONFIGPACKAGE_PREFIX}/${PACKAGE_NAME})

    if (CAS_VERSION_COMPATIBILITY)
        if(NOT CMAKE_PROJECT_VERSION)
            message(SEND_ERROR "Top level CMake project must have a version set before setting VERSION_COMPATIBILITY")
        endif()
        _version_files(${PACKAGE_NAME} ${CMC_INSTALL_CONFIGPACKAGE_PREFIX}/${PACKAGE_NAME}
                       ${CMAKE_PROJECT_VERSION} ${CAS_VERSION_COMPATIBILITY})
    endif()
endfunction()
