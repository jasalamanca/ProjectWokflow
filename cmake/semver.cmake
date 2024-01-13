include_guard(GLOBAL)
cmake_minimum_required(VERSION 3.25 FATAL_ERROR)

# Builds a config version file for semver versions.
# copy it along this semver.cmake file to be included
# Expects VERSION parameter to be set or ${PROJECT_NAME}_VERSION to be defined prior to calling this function.
# Expects ${PACKAGE_FIND_NAME}_FIND_SEMVER_VERSION to be defined before called find_package calls version file generated by this function.
function(semver_write_version_config filename)
    set(options_ )
    set(oneValueArgs_ VERSION)
    set(multiValueArgs_ )
    cmake_parse_arguments(SV "${options_}" "${oneValueArgs_}" "${multiValueArgs_}" ${ARGN})

    if (SV_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "Unknown arguments in semver_write_version_config \"${SV_UNPARSED_ARGUMENTS}\"")
    endif()

    if (NOT SV_VERSION)
        message("semver_write_version_config generating file with version '${${PROJECT_NAME}_VERSION}'")
        set(SV_VERSION "${${PROJECT_NAME}_VERSION}")
    endif()

    set(content_
"
# This is a semver (https://semver.org/spec/v2.0.0.html) version file for the Config-mode of find_package() generated by ProjectWorkflow.
# DO NOT EDIT IT!
#
# Semver version file generated for ${PROJECT_NAME} version ${SV_VERSION}
#
# File is created calling semver_write_version_config function on semver.cmake module.
# When no VERSION is set explicitly, expects \${PROJECT_NAME}_VERSION to be defined prior to calling this function.
# But cmake doesn't support prerelease nor build parts. So \${PROJECT_NAME}_VERSION must be overridden after project call.
# example
#   project(MyProject VERSION 1.2.3)
#   set(MyProject_VERSION \"1.2.3-alpha+build3\")
#
# Semver versions cannot be passed in directly via the find_package command,
# so you must define \${PACKAGE_FIND_NAME}_FIND_SEMVER_VERSION before find_package
# example (to locate version \"1.2.3-alpha+build3\")
#   set(OtherProject_FIND_SEMVER_VERSION \"1.2.3-alpha+build3\")
#   find_package(OtherProject 1.2.3)
# example (to locate range \"1.2.3-alpha+build3...<2\")
#   set(OtherProject_FIND_SEMVER_VERSION \"1.2.3-alpha+build3...<2\")
#   find_package(OtherProject 1.2.3...<2)
#
# The created file sets PACKAGE_VERSION_EXACT if the current version string and
# the requested version string are exactly the same and it sets
# PACKAGE_VERSION_COMPATIBLE if the current version is semver compatible with requested version.

# failure by default
set(PACKAGE_VERSION_COMPATIBLE FALSE)
set(PACKAGE_VERSION_EXACT FALSE)

# include semver tools that must be ready available
include(\"\${CMAKE_CURRENT_LIST_DIR}/semver.cmake\")

set(PACKAGE_VERSION \"${SV_VERSION}\")

# Update PACKAGE_FIND_VERSION and PACKAGE_FIND_VERSION_COMPLETE for completeness
set(PACKAGE_FIND_VERSION \"\${\${PACKAGE_FIND_NAME}_FIND_SEMVER_VERSION}\")
set(PACKAGE_FIND_VERSION_COMPLETE \"\${\${PACKAGE_FIND_NAME}_FIND_SEMVER_VERSION}\")

# Checking version
if(NOT PACKAGE_FIND_VERSION)
    # If no version specified accept this one
    set(PACKAGE_VERSION_COMPATIBLE TRUE)
else()
    semver_matches(\${PACKAGE_VERSION} \${PACKAGE_FIND_VERSION} matches_ exact_)
    if(PACKAGE_VERSION MATCHES [[^0\\..*]] AND NOT exact_)
        # If major version is 0 only exact search must be done.
        set(matches_ FALSE)
    endif()
    set(PACKAGE_VERSION_COMPATIBLE \${matches_})
    set(PACKAGE_VERSION_EXACT \${exact_})
endif()
")

# local eval for word size
if(CMAKE_SIZEOF_VOID_P)
  math(EXPR installedBits_ "${CMAKE_SIZEOF_VOID_P} * 8")
  string(APPEND content_
"
# check that the installed version has the same 32/64bit-ness as the one which is currently searching
if(CMAKE_SIZEOF_VOID_P AND NOT CMAKE_SIZEOF_VOID_P STREQUAL \"${CMAKE_SIZEOF_VOID_P}\")
    set(PACKAGE_VERSION \"\${PACKAGE_VERSION} (${installedBits_}bit)\")
    set(PACKAGE_VERSION_UNSUITABLE TRUE)
endif()
")
endif()

file(WRITE ${filename} ${content_})
endfunction()

# Checks if semver <version> matches semver version specification <spec>.
# Sets <matches> according to the check and <exact> will be true if and only if <version> and <spec> represent the same semver version.
#
# A semver version follows
#  <semver_version> ::= <basic>[-<prerelease>][+<build_metadata>]
#
# A cmake semver specification follows cmake ranges specification
#  <semver_range> ::= <semver_spec>[(...|...<)<semver_spec>]
#   <semver_spec> ::= <basic_spec>[-<prerelease>][+<build_metadata>]
#    <basic_spec> ::= <number>[.<number>[.<number>]]
#      Every missing <number> is substituted by 0 to form a version <basic> version.
function(semver_matches version spec matches exact)
    semver_splitVersion_(${version} base_ pre_ build_ isValidVersion_)
    if (NOT isValidVersion_)
        message(AUTHOR_WARNING "\"${version}\" is an invalid semver version")
        return()
    endif()

    semver_splitSpec_(${spec} minBase_ minPre_ minBuild_ minClosed_ maxBase_ maxPre_ maxBuild_ maxClosed_ isValidSpec_)
    if (NOT isValidSpec_)
        message(AUTHOR_WARNING "\"${spec}\" is an invalid semver specification")
        return()
    endif()

    # build metadata not used on comparisons
    # For the rest, calculate partial conditions
    semver_cmpBase_("${base_}" "${minBase_}" minBaseCmp_)
    semver_cmpBase_("${base_}" "${maxBase_}" maxBaseCmp_)
    semver_cmpPre_("${pre_}" "${minPre_}" minPreCmp_)
    semver_cmpPre_("${pre_}" "${maxPre_}" maxPreCmp_)
    semver_minOk_("${minBaseCmp_}" "${minClosed_}" minBaseOk_)
    semver_maxOk_("${maxBaseCmp_}" "${maxClosed_}" maxBaseOk_)
    semver_minOk_("${minPreCmp_}" "${minClosed_}" minPreOk_)
    semver_maxOk_("${maxPreCmp_}" "${maxClosed_}" maxPreOk_)

    # message(WARNING "'${minBaseCmp_}' '${maxBaseCmp_}' '${minPreCmp_}' '${maxPreCmp_}'")
    # message(WARNING "'${base_}' '${minBase_}' '${maxBase_}' '${pre_}' '${minPre_}' '${maxPre_}'")
    # message(WARNING "'${minBaseOk_}' '${maxBaseOk_}' '${minPreOk_}' '${maxPreOk_}'")

    if ((minBaseOk_ OR (NOT minClosed_ AND minBaseCmp_ EQUAL "0"))
            AND (maxBaseOk_ OR (NOT maxClosed_ AND maxBaseCmp_ EQUAL "0"))
            AND (NOT minBaseCmp_ EQUAL "0" OR (minBaseCmp_ EQUAL "0" AND minPreOk_))
            AND (NOT maxBaseCmp_ EQUAL "0" OR (maxBaseCmp_ EQUAL "0" AND maxPreOk_)))
        set(${matches} TRUE PARENT_SCOPE)
        if (base_ STREQUAL minBase_ AND base_ STREQUAL maxBase_
            AND ((NOT pre_ AND NOT minPre_ AND NOT maxPre_) OR (pre_ STREQUAL minPre_ AND pre_ STREQUAL maxPre_)))
            set(${exact} TRUE PARENT_SCOPE)
        endif()
    endif()
endfunction()

# If receives a semver version then returns base part, else returns full version received.
function(semver_toCMakeVersion version_ version_cmake_)
    semver_splitVersion_(${version_} base_ pre_ build_ valid_)
    if(valid_)
        set(version_cmake_ ${base_} PARENT_SCOPE)
    else()
        set(version_cmake_ ${version_} PARENT_SCOPE)
    endif()
endfunction()

# Splits a semver version and check if it is valid.
function(semver_splitVersion_ version base pre build isValidVer)
    # Separate base, prerelease and build metadata
    if(NOT ${version} MATCHES [[^([0-9\.]+)(\-([0-9a-zA-Z\.-]+))?(\+([0-9a-zA-Z\.-]+))?$]])
        set(${isValidVer} FALSE PARENT_SCOPE)
        return()
    endif()

    # Extract parts. To be more checked.

    set(base_ "${CMAKE_MATCH_1}")
    set(pre_ "${CMAKE_MATCH_3}")
    set(build_ "${CMAKE_MATCH_5}")

    # Check each fragment for validity.
    semver_validBaseVer_("${base_}" isValid_)
    if(NOT isValid_)
        set(${isValidVer} FALSE PARENT_SCOPE)
        return()
    endif()

    semver_validPreVer_("${pre_}" isValid_)
    if(NOT isValid_)
        set(${isValidVer} FALSE PARENT_SCOPE)
        return()
    endif()

    semver_validBuildVer_("${build_}" isValid_)
    if(NOT isValid_)
        set(${isValidVer} FALSE PARENT_SCOPE)
        return()
    endif()

    #Export all valid results
    set(${base} ${base_} PARENT_SCOPE)
    set(${pre} ${pre_} PARENT_SCOPE)
    set(${build} ${build_} PARENT_SCOPE)
    set(${isValidVer} TRUE PARENT_SCOPE)
endfunction()

function(semver_validBaseVer_ base isValid)
    if(base MATCHES [[^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$]])
        set(${isValid} TRUE PARENT_SCOPE)
    else()
        set(${isValid} FALSE PARENT_SCOPE)
    endif()
endfunction()

function(semver_validPreVer_ pre isValid)
    if(NOT pre
        OR pre MATCHES [[^((0|[1-9][0-9]*)|([0-9a-zA-Z-]*[a-zA-Z-][0-9a-zA-Z-]*))(\.((0|[1-9][0-9]*)|([0-9a-zA-Z-]*[a-zA-Z-][0-9a-zA-Z-]*)))*$]])
        set(${isValid} TRUE PARENT_SCOPE)
    else()
        set(${isValid} FALSE PARENT_SCOPE)
    endif()
endfunction()

function(semver_validBuildVer_ build isValid)
    if(NOT build
        OR build MATCHES [[^(([0-9]+)|([0-9a-zA-Z-]*[a-zA-Z-][0-9a-zA-Z-]*))(\.(([0-9]+)|([0-9a-zA-Z-]*[a-zA-Z-][0-9a-zA-Z-]*)))*$]])
        set(${isValid} TRUE PARENT_SCOPE)
    else()
        set(${isValid} FALSE PARENT_SCOPE)
    endif()
endfunction()

# Splits a semver specification, closed/open range ends and if it is valid.
# If a single version specification is passed, it is interpreted as a closed range from this version specification to itself.
function(semver_splitSpec_ spec minBase minPre minBuild minClosed maxBase maxPre maxBuild maxClosed isValidSpec)
    # Check for a range
    if(spec MATCHES [[^([0-9a-zA-Z\.\+-]+)\.\.\.(<?)([0-9a-zA-Z\.\+-]+)$]])
        semver_splitSimpleSpec_("${CMAKE_MATCH_1}" minBase_ minPre_ minBuild_ isValid_)
        if(NOT isValid_)
            set(${isValidSpec} FALSE PARENT_SCOPE)
            return()
        endif()
        set(minClosed_ TRUE)
        semver_splitSimpleSpec_("${CMAKE_MATCH_3}" maxBase_ maxPre_ maxBuild_ isValid_)
        if(NOT isValid_)
            set(${isValidSpec} FALSE PARENT_SCOPE)
            return()
        endif()
        if("${CMAKE_MATCH_2}" STREQUAL "<")
            set(maxClosed_ FALSE)
        else()
            set(maxClosed_ TRUE)
        endif()
    else()
        # Try simple spec
        semver_splitSimpleSpec_("${spec}" minBase_ minPre_ minBuild_ isValid_)
        if(NOT isValid_)
            set(${isValidSpec} FALSE PARENT_SCOPE)
            return()
        endif()
        set(minClosed_ TRUE)
        set(maxBase_ "${minBase_}")
        set(maxPre_ "${minPre_}")
        set(maxBuild_ "${minBuild_}")
        set(maxClosed_ TRUE)
    endif()

    #Export all valid results
    set(${minBase} ${minBase_} PARENT_SCOPE)
    set(${minPre} ${minPre_} PARENT_SCOPE)
    set(${minBuild} ${minBuild_} PARENT_SCOPE)
    set(${minClosed} ${minClosed_} PARENT_SCOPE)
    set(${maxBase} ${maxBase_} PARENT_SCOPE)
    set(${maxPre} ${maxPre_} PARENT_SCOPE)
    set(${maxBuild} ${maxBuild_} PARENT_SCOPE)
    set(${maxClosed} ${maxClosed_} PARENT_SCOPE)
    set(${isValidSpec} TRUE PARENT_SCOPE)
endfunction()

function(semver_splitSimpleSpec_ spec base pre build isValidSpec)
    # Separate base, prerelease and build metadata
    if(NOT spec MATCHES [[^([0-9\.]+)(\-[0-9a-zA-Z\.-]+)?(\+[0-9a-zA-Z\.-]+)?$]])
        set(${isValidSpec} FALSE PARENT_SCOPE)
        return()
    endif()

    # Extract parts. To be more checked.
    set(base_ "${CMAKE_MATCH_1}")
    set(pre_ "${CMAKE_MATCH_2}")
    if(pre_)
        string(SUBSTRING "${pre_}" 1 -1 pre_)
    endif()
    set(build_ "${CMAKE_MATCH_3}")
    if(build_)
        string(SUBSTRING "${build_}" 1 -1 build_)
    endif()

    # Check each fragment for validity.
    semver_validBaseSpec_("${base_}" isValid_)
    if(NOT isValid_)
        set(${isValidSpec} FALSE PARENT_SCOPE)
        return()
    endif()

    semver_validPreSpec_("${pre_}" isValid_)
    if(NOT isValid_)
        set(${isValidSpec} FALSE PARENT_SCOPE)
        return()
    endif()

    semver_validBuildSpec_("${build_}" isValid_)
    if(NOT isValid_)
        set(${isValidSpec} FALSE PARENT_SCOPE)
        return()
    endif()

    #Export all valid results
    set(${base} ${base_} PARENT_SCOPE)
    set(${pre} ${pre_} PARENT_SCOPE)
    set(${build} ${build_} PARENT_SCOPE)
    set(${isValidSpec} TRUE PARENT_SCOPE)
endfunction()

function(semver_validBaseSpec_ base isValid)
    if(base MATCHES [[^(0|[1-9][0-9]*)(\.(0|[1-9][0-9]*)(\.(0|[1-9][0-9]*))?)?$]])
        set(${isValid} TRUE PARENT_SCOPE)
    else()
        set(${isValid} FALSE PARENT_SCOPE)
    endif()
endfunction()

function(semver_validPreSpec_ pre isValid)
    set(numericId_ [[(0|[1-9][0-9]*)]])
    if(NOT pre
        OR pre MATCHES [[^((0|[1-9][0-9]*)|([0-9a-zA-Z-]*[a-zA-Z-][0-9a-zA-Z-]*))(\.((0|[1-9][0-9]*)|([0-9a-zA-Z-]*[a-zA-Z-][0-9a-zA-Z-]*)))*$]])
        set(${isValid} TRUE PARENT_SCOPE)
    else()
        set(${isValid} FALSE PARENT_SCOPE)
    endif()
endfunction()

function(semver_validBuildSpec_ build isValid)
    set(digits_ [[[0-9]+]])
    if(NOT build
        OR build MATCHES [[^(([0-9]+)|([0-9a-zA-Z-]*[a-zA-Z-][0-9a-zA-Z-]*))(\.(([0-9]+)|([0-9a-zA-Z-]*[a-zA-Z-][0-9a-zA-Z-]*)))*$]])
        set(${isValid} TRUE PARENT_SCOPE)
    else()
        set(${isValid} FALSE PARENT_SCOPE)
    endif()
endfunction()

# Compares version with respect to base_spec
# a la CMake
#   0.1.0 > 0
#   0.1.0 > 0.0
#   0.1.0 = 0.1
#   0.1.0 < 0.1.0
#   0.1.0 < 1
function(semver_cmpBase_ version spec cmp)
    if (version VERSION_LESS spec)
        set(${cmp} "-1" PARENT_SCOPE)
    elseif(version VERSION_GREATER spec)
        set(${cmp} "1" PARENT_SCOPE)
    else()
        set(${cmp} "0" PARENT_SCOPE)
    endif()
endfunction()

# Compares version with respect to pre_spec
# decimal sequence comparison and each component comparison as number or as string
#   0.0.0-alpha < 0.0.0
#   0.0.0-alpha < 0.0.0-beta
#   0.0.0-alpha.9 < 0.0.0-alpha.10
#   0.0.0-alpha.10 < 0.0.0-alpha.a
#   0.0.0-alpha.10 > 0.0.0-alpha
#   0.0.0-rc10 < 0.0.0-rc9
function(semver_cmpPre_ pre spec cmp)
    if(pre AND NOT spec)
        set(${cmp} "-1" PARENT_SCOPE)
        return()
    endif()

    if(NOT pre AND spec)
        set(${cmp} "1" PARENT_SCOPE)
        return()
    endif()

    if(NOT pre AND NOT spec)
        set(${cmp} "0" PARENT_SCOPE)
        return()
    endif()

    string(REGEX MATCHALL [=[[^\.]+]=] preParts_ "${pre}")
    string(REGEX MATCHALL "[^\\.]+" specParts_ "${spec}")

    foreach(prePart_ specPart_ IN ZIP_LISTS preParts_ specParts_)
        # At this point parts compared so far are equal
        if (DEFINED prePart_ AND NOT DEFINED specPart_)
            set(${cmp} "1" PARENT_SCOPE)
            return()
        elseif(NOT DEFINED prePart_ AND DEFINED specPart_)
            set(${cmp} "-1" PARENT_SCOPE)
            return()
        else()
            semver_cmpPrePart_(${prePart_} ${specPart_} partCmp_)
            if (NOT partCmp_ EQUAL "0")
                set(${cmp} ${partCmp_} PARENT_SCOPE)
                return()
            endif()
        endif()
    endforeach()

    set(${cmp} "0" PARENT_SCOPE)
endfunction()

function(semver_cmpPrePart_ pre spec cmp)
    if(pre MATCHES "^(0|[1-9][0-9]*)$" AND spec MATCHES "^(0|[1-9][0-9]*)$")
        if(pre LESS spec)
            set(${cmp} "-1" PARENT_SCOPE)
        elseif(pre GREATER spec)
            set(${cmp} "1" PARENT_SCOPE)
        else()
            set(${cmp} "0" PARENT_SCOPE)
        endif()
    else()
        if(pre STRLESS spec)
            set(${cmp} "-1" PARENT_SCOPE)
        elseif(pre STRGREATER spec)
            set(${cmp} "1" PARENT_SCOPE)
        else()
            set(${cmp} "0" PARENT_SCOPE)
        endif()
    endif()
endfunction()

function(semver_minOk_ cmp closed ok)
    if ((closed AND cmp GREATER_EQUAL "0") OR (NOT closed AND cmp GREATER "0"))
        set(${ok} TRUE PARENT_SCOPE)
    else()
        set(${ok} FALSE PARENT_SCOPE)
    endif()
endfunction()

function(semver_maxOk_ cmp closed ok)
    if ((closed AND cmp LESS_EQUAL "0") OR (NOT closed AND cmp LESS "0"))
        set(${ok} TRUE PARENT_SCOPE)
    else()
        set(${ok} FALSE PARENT_SCOPE)
    endif()
endfunction()
