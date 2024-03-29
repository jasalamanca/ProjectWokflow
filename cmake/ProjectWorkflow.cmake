include_guard(GLOBAL)
cmake_minimum_required(VERSION 3.25 FATAL_ERROR)

include(GNUInstallDirs)
# Prepare CMake scripts destination
# From GnuInstallDirs
set(PW_INSTALL_CMAKEROOTDIR "${CMAKE_INSTALL_LIBDIR}/cmake")
set(PW_INSTALL_NOARCH_CMAKEROOTDIR "${CMAKE_INSTALL_DATAROOTDIR}/cmake")

include(CMakePackageConfigHelpers)
include(semver)

macro(set_or_default_ var_ valueVar_ default_)
    if (DEFINED ${valueVar_})
        set(${var_} ${${valueVar_}})
    else()
        set(${var_} ${default_})
    endif()
endmacro()

# Builds a stereotyped and simple config file
function(write_config_in_ filename_)
    set(options_ )
    set(oneValueArgs_ PACKAGE)
    set(multiValueArgs_ EXPORTS EXTERNAL_EXPORTS PACKAGES)
    cmake_parse_arguments(PWI "${options_}" "${oneValueArgs_}" "${multiValueArgs_}" ${ARGN})

    foreach(package_ ${PWI_PACKAGES})
        # Check if package_ really was found and used on build
        if (${package_}_FOUND)
            list(APPEND transitivePackages_ ${package_})
        else()
            message(AUTHOR_WARNING "Seems package '${package_}' was not found nor used on build of '${PWI_PACKAGE}'")
        endif()
    endforeach()

    set(content_
"
# File automatically generated by ProjectWorkflow
# DON'T EDIT IT!
#
# Configuration file generated for ${PROJECT_NAME} version ${${PROJECT_NAME}_VERSION}
#
# Standard CMakePackageConfigHelpers module initialization.
# Paths and so on.
@PACKAGE_INIT@
")

if(transitivePackages_)
    string(APPEND content_
"

# Propagate QUIET
set(quiet_)
if(\${CMAKE_FIND_PACKAGE_NAME}_FIND_QUIETLY)
  set(quiet_ QUIET)
endif()

# Find all packages used during build and needed by dependent projects
")

foreach(package_ ${transitivePackages_})
    if(NOT ${package_}_VERSION)
string(APPEND content_
    "find_package(${package_} REQUIRED \${quiet_})
    ")
    else()
        semver_validToCMakeVersion("${${package_}_VERSION}" versionCmake_)
        if(versionCmake_ AND NOT "${${package_}_VERSION}" STREQUAL "${versionCmake_}")
string(APPEND content_
    "if(NOT ${package_}_FIND_SEMVER_VERSION)
        set(${package_}_FIND_SEMVER_VERSION ${${package_}_VERSION})
    elseif(NOT \"${package_}_FIND_SEMVER_VERSION\" STREQUAL \"${${package_}_VERSION}\")
        message(WARNING \"Package version for ${package_} was '${package_}_FIND_SEMVER_VERSION' and now '${${package_}_VERSION}' is required\")
        message(WARNING \"Previous package version is preserved!!!\")
    endif()
    find_package(${package_} \"${versionCmake_}\" REQUIRED \${quiet_})
    ")
        else()
string(APPEND content_
    "find_package(${package_} \"${${package_}_VERSION}\" REQUIRED \${quiet_})
    ")
        endif()
    endif()
endforeach()
endif()

if(PWI_EXPORTS OR PWI_EXTERNAL_EXPORTS)
    string(APPEND content_
"

# Include all exported targets
# Also targets not managed with install(TARGETS) like add_jar
foreach(export_ ${PWI_EXPORTS} ${PWI_EXTERNAL_EXPORTS})
    set(export_filename_ \"\${CMAKE_CURRENT_LIST_DIR}/\${export_}.cmake\")
    if(EXISTS \${export_filename_})
        include(\"\${CMAKE_CURRENT_LIST_DIR}/\${export_}.cmake\")
    else()
        cmake_path(GET export_filename_ FILENAME export_filename_only_)
        message(FATAL_ERROR \"Mandatory file \${export_filename_only_} for ${PWI_PACKAGE} package does not exists!\")
    endif()
endforeach()
")
endif()

string(APPEND content_
"

# Check all components found
check_required_components(${PWI_PACKAGE})
")

    file(WRITE ${filename_} ${content_})
endfunction()

# Install a simple package config file, it version file and all the exports and targets
function(PW_install)
    set(options_ )
    set(oneValueArgs_ PACKAGE VERSION NAMESPACE COMPATIBILITY COMPONENT)
    set(multiValueArgs_ EXPORTS EXTERNAL_EXPORTS PACKAGES)
    cmake_parse_arguments(PWI "${options_}" "${oneValueArgs_}" "${multiValueArgs_}" ${ARGN})

    if (PWI_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "Unknown arguments in PW_install \"${PWI_UNPARSED_ARGUMENTS}\"")
    endif()

    if (NOT PWI_PACKAGE)
        message(FATAL_ERROR "PW_install without package name")
    endif()

    if (NOT PWI_EXPORTS AND NOT PWI_EXTERNAL_EXPORTS)
        message(AUTHOR_WARNING "PW_install without exports or external exports")
    endif()

    if (NOT PWI_COMPATIBILITY)
        message(STATUS "PW_install for package ${PWI_PACKAGE} without version compatibility. Semver by default.")
        set(PWI_COMPATIBILITY "Semver")
    endif()

    set_or_default_(packageVersion_ PWI_VERSION "${${PROJECT_NAME}_VERSION}")
    set_or_default_(packageNamespace_ PWI_NAMESPACE "${PWI_PACKAGE}::")

    set(INSTALL_CMAKEDIR_ "${PW_INSTALL_CMAKEROOTDIR}/${PWI_PACKAGE}")
    message("Writing to ${INSTALL_CMAKEDIR_}")

    foreach(export_ ${PWI_EXPORTS})
        install(EXPORT ${export_}
            FILE ${export_}.cmake
            NAMESPACE ${packageNamespace_}
            DESTINATION "${INSTALL_CMAKEDIR_}"
            COMPONENT "${PWI_COMPONENT}"
        )
    endforeach()

    set(config_file_ "${CMAKE_CURRENT_BINARY_DIR}/${PWI_PACKAGE}Config.cmake")
    set(config_file_in_ "${config_file_}.in")

    write_config_in_(${config_file_in_} ${ARGN})
    configure_package_config_file(${config_file_in_} ${config_file_}
        INSTALL_DESTINATION "${INSTALL_CMAKEDIR_}")

    set(config_version_file_ "${CMAKE_CURRENT_BINARY_DIR}/${PWI_PACKAGE}ConfigVersion.cmake")
    if("Semver" STREQUAL PWI_COMPATIBILITY)
        set(version_files_ "${config_version_file_}"
            "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/semver.cmake") # relative to this file
        semver_write_version_config("${config_version_file_}"
            VERSION "${packageVersion_}")
    else()
        set(version_files_ "${config_version_file_}")
        write_basic_package_version_file("${config_version_file_}"
            VERSION "${packageVersion_}"
            COMPATIBILITY "${PWI_COMPATIBILITY}")
    endif()

    install(FILES "${config_file_}" ${version_files_}
        DESTINATION "${INSTALL_CMAKEDIR_}"
        COMPONENT "${PWI_COMPONENT}"
    )
endfunction()
