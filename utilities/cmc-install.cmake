## \brief Installs the provided files (optionally adding the DESTINATION prefix)
##        while preserving the relative path of each file (i.e. recreating folder hierarchy)
function(cmc_install_with_folders)
    set(optionsArgs "")
    set(oneValueArgs "DESTINATION")
    set(multiValueArgs "FILES")
    cmake_parse_arguments(CAS "${optionsArgs}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )

    foreach(_file ${CAS_FILES})
        get_filename_component(_dir ${_file} DIRECTORY)
    install(FILES ${_file} DESTINATION ${CAS_DESTINATION}/${_dir})
    endforeach()
endfunction()


## \brief Generate a package config file for TARGET, making it available:
##        * (at configure time) in the build tree
##        * (at install time) in the install tree
function(cmc_install_packageconfig TARGET)
    set(optionsArgs "")
    set(oneValueArgs "NAMESPACE")
    set(multiValueArgs "")
    cmake_parse_arguments(CAS "${optionsArgs}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )

    install(TARGETS ${TARGET} EXPORT ${TARGET}Targets)

    set(_targetfile ${TARGET}Targets.cmake)

    # Generate config files in the build tree, from the template in Config.cmake.in
    configure_file(${CMC_ROOT_DIR}/templates/PackageConfig.cmake.in
                   ${CMAKE_CURRENT_BINARY_DIR}/${TARGET}Config.cmake
                   @ONLY
    )

    # Install the config file over to the install tree
    install(
        FILES ${CMAKE_CURRENT_BINARY_DIR}/${TARGET}Config.cmake
        DESTINATION lib/cmake/${TARGET}
    )

    # build tree
    export(EXPORT ${TARGET}Targets
        NAMESPACE ${CAS_NAMESPACE}::
        FILE ${CMAKE_CURRENT_BINARY_DIR}/${_targetfile}
    )

    # install tree
    install(EXPORT ${TARGET}Targets
        FILE ${_targetfile}
        DESTINATION lib/cmake/${TARGET}
        NAMESPACE ${CAS_NAMESPACE}::
    )
endfunction()
