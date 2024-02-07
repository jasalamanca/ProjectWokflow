include_guard(GLOBAL)
cmake_minimum_required(VERSION 3.25 FATAL_ERROR)

include(semver)

function(unsetall_)
    foreach(var_ ${ARGN})
        unset(${var_} PARENT_SCOPE)
    endforeach()
endfunction()

# Wrapper of project command to put semver versions.
macro(project prjName)
    set(options_ )
    set(oneValueArgs_ VERSION)
    set(multiValueArgs_ )
    cmake_parse_arguments(PW_PRJ "${options_}" "${oneValueArgs_}" "${multiValueArgs_}" ${ARGN})

    # Call original project with semver base version and then set <PROJECT_NAME>_VERSION with full semver version.
    semver_splitVersion_(${PW_PRJ_VERSION} base_ pre_ build_ isValidVersion_)
    if(NOT isValidVersion_)
        set(base_ ${PW_PRJ_VERSION}) # if not a valid semver, pass full version and let CMake check it.
    endif()
    _project(${prjName} VERSION ${base_} ${PW_PRJ_UNPARSED_ARGUMENTS})
    set(${prjName}_VERSION ${PW_PRJ_VERSION})

    # No leak local variables
    unsetall_(options_ oneValueArgs_ multiValueArgs_ base_ pre_ build_ isValidVersion_)
endmacro()
