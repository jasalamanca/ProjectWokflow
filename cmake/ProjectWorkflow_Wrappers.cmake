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

# find_package(<PackageName> [version] [EXACT] [QUIET] [MODULE]
#              [REQUIRED] [[COMPONENTS] [components...]]
#              [OPTIONAL_COMPONENTS components...]
#              [REGISTRY_VIEW  (64|32|64_32|32_64|HOST|TARGET|BOTH)]
#              [GLOBAL]
#              [NO_POLICY_SCOPE]
#              [BYPASS_PROVIDER])

# find_package(<PackageName> [version] [EXACT] [QUIET]
#              [REQUIRED] [[COMPONENTS] [components...]]
#              [OPTIONAL_COMPONENTS components...]
#              [CONFIG|NO_MODULE]
#              [GLOBAL]
#              [NO_POLICY_SCOPE]
#              [BYPASS_PROVIDER]
#              [NAMES name1 [name2 ...]]
#              [CONFIGS config1 [config2 ...]]
#              [HINTS path1 [path2 ... ]]
#              [PATHS path1 [path2 ... ]]
#              [REGISTRY_VIEW  (64|32|64_32|32_64|HOST|TARGET|BOTH)]
#              [PATH_SUFFIXES suffix1 [suffix2 ...]]
#              [NO_DEFAULT_PATH]
#              [NO_PACKAGE_ROOT_PATH]
#              [NO_CMAKE_PATH]
#              [NO_CMAKE_ENVIRONMENT_PATH]
#              [NO_SYSTEM_ENVIRONMENT_PATH]
#              [NO_CMAKE_PACKAGE_REGISTRY]
#              [NO_CMAKE_BUILDS_PATH] # Deprecated; does nothing.
#              [NO_CMAKE_SYSTEM_PATH]
#              [NO_CMAKE_INSTALL_PREFIX]
#              [NO_CMAKE_SYSTEM_PACKAGE_REGISTRY]
#              [CMAKE_FIND_ROOT_PATH_BOTH |
#               ONLY_CMAKE_FIND_ROOT_PATH |
#               NO_CMAKE_FIND_ROOT_PATH])
macro(find_package pkgName)
    # We are only interested in version argument to support semver
    # search for version on not positional arguments
    set(haveSemverSpec_ False)
    set(rest_ "")
    foreach(word_ ${ARGN})
        if(haveSemverSpec_)
            list(APPEND rest_ "${word_}")
        else()
            semver_validToCMakeSpec(${word_} specCmake_)
            if(specCmake_)
                set(haveSemverSpec_ True)
                set(semverSpec_ "${word_}")
            else()
                list(APPEND rest_ "${word_}")
            endif()
        endif()
    endforeach()

    if(haveSemverSpec_)
        set(${pkgName}_FIND_SEMVER_VERSION "${semverSpec_}")
        _find_package(${pkgName} ${specCmake_} ${rest_})
    else()
        _find_package(${pkgName} ${rest_})
    endif()

    # No leak local variables
    unsetall_(haveSemverSpec_ semverSpec_ rest_ word_ specCmake_)
endmacro()
