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

# Searches version field on find_package arguments.
# When a version is found, sets <spec> to this value and <cmakeSpec> to nearest
# CMake compatible version specification.
# When not version found, <spec> and <cmakeSpec> are unset.
# Whatever argument that is not a version is returned on <rest>.
function(PW_extractFPversion_ spec cmakeSpec rest)
    # We are only interested in version argument to support semver.
    # Search for version on not positional arguments.
    set(spec_ "")
    set(cmakeSpec_ "")
    set(rest_ "")
    foreach(word_ ${ARGN})
        if(spec_)
            list(APPEND rest_ "${word_}")
        else()
            semver_validToCMakeSpec("${word_}" cmakeSpec_)
            # if word_ is semver and also CMake, use it as CMake specification.
            if(cmakeSpec_)
                set(spec_ "${word_}")
            else()
                list(APPEND rest_ "${word_}")
            endif()
        endif()
    endforeach()

    set(${spec} "${spec_}" PARENT_SCOPE)
    set(${cmakeSpec} "${cmakeSpec_}" PARENT_SCOPE)
    set(${rest} "${rest_}" PARENT_SCOPE)
endfunction()

macro(find_package pkgName)
    PW_extractFPversion_(semverSpec_ cmakeSpec_ rest_ ${ARGN})

    if(NOT semverSpec_)
        # No version. None special to do.
    elseif(NOT ${pkgName}_FIND_SEMVER_VERSION)
        # Version and no previous semver version
        if("${semverSpec_}" STREQUAL "${cmakeSpec_}")
            # A cmake compatible version, so don't set <pkg_name>_FIND_SEMVER_VERSION
        else()
            # Really a semver version, so set <pkg_name>_FIND_SEMVER_VERSION
            set(${pkgName}_FIND_SEMVER_VERSION "${semverSpec_}")
        endif()
    else()
        # Version and previous semver version
        if("${semverSpec_}" STREQUAL "${${pkgName}_FIND_SEMVER_VERSION}")
            # We search exactly for previous semver version. None special to do.
        else()
            # Maybe some one is setting <pkg_name>_FIND_SEMVER_VERSION calling find_package with cmake compatible version like us.
            semver_validToCMakeSpec("${${pkgName}_FIND_SEMVER_VERSION}" previousSpec_)
            if("${semverSpec_}" STREQUAL "${previousSpec_}")
                # Looks like some one was searching this version before, so none special to do
            else()
                # Looks like we are searching for a diferente version
                # Calculate intersection an continue checking
                semver_specIntersection("${semverSpec_}" "${${pkgName}_FIND_SEMVER_VERSION}" intersection_)
                if (NOT intersection_)
                    message(FATAL_ERROR "Incompatible '${semverSpec_}' and previous '${${pkgName}_FIND_SEMVER_VERSION}' for package ${pkgName}")
                else()
                    # Update <pkg_name>_FIND_SEMVER_VERSION with version intersection
                    set(${pkgName}_FIND_SEMVER_VERSION "${intersection_}")
                    # and update cmakeSpec_ accordingly
                    semver_validToCMakeSpec("${intersection_}" cmakeSpec_)
                endif()
            endif()
        endif()
    endif()

    # Always delegate on previous find_package
    if(${pkgName}_FIND_SEMVER_VERSION)
        message("${pkgName}_FIND_SEMVER_VERSION=${${pkgName}_FIND_SEMVER_VERSION}")
    endif()
    message("_find_package(${pkgName} ${cmakeSpec_} ${rest_})")
    _find_package(${pkgName} ${cmakeSpec_} ${rest_})

    # Update some find_package internals
    if(${pkgName}_FOUND AND ${pkgName}_FIND_SEMVER_VERSION)
        set_property(GLOBAL PROPERTY _CMAKE_${pkgName}_REQUIRED_VERSION "${${pkgName}_FIND_SEMVER_VERSION}")
    endif()

    # No leak local variables
    unsetall_(semverSpec_ cmakeSpec_ rest_ previousSpec_ intersection_)
endmacro()
