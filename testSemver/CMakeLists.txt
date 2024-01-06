cmake_minimum_required(VERSION 3.25 FATAL_ERROR)

# ProjectWorkflow cmake modules
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../cmake")

project(PWSemverTest)

include(semver)

function(check_semver_version_ version checkBase checkPre checkBuild checkValid)
    semver_splitVersion_(${version} base_ pre_ build_ valid_)
    if((NOT valid_ AND checkValid) OR (valid_ AND NOT checkValid))
        if(checkValid)
            message(FATAL_ERROR "\"${version}\" is NOT valid!!")
        else()
            message(FATAL_ERROR "\"${version}\" is valid!!")
        endif()
    endif()

    if(valid_)
        if(NOT "${base_}" STREQUAL "${checkBase}")
            message(FATAL_ERROR "From \"${version}\" 1-> \"${base_}\" differs from \"${checkBase}\"")
        endif()
        if(NOT "${pre_}" STREQUAL "${checkPre}")
            message(FATAL_ERROR "From \"${version}\" 2-> \"${pre_}\" differs from \"${checkPre}\"")
        endif()
        if(NOT "${build_}" STREQUAL "${checkBuild}")
            message(FATAL_ERROR "From \"${version}\" 3-> \"${build_}\" differs from \"${checkBuild}\"")
        endif()
    endif()
endfunction()


# Check versions
check_semver_version_("0" "" "" "" FALSE)
check_semver_version_("0.0" "" "" "" FALSE)
check_semver_version_("0.0.0" "0.0.0" "" "" TRUE)
check_semver_version_("0.0.01" "" "" "" FALSE)
check_semver_version_("0.10.9876543210" "0.10.9876543210" "" "" TRUE)
check_semver_version_("1.2.3-alpha" "1.2.3" "alpha" "" TRUE)
check_semver_version_("1.2.3+alpha" "1.2.3" "" "alpha" TRUE)
check_semver_version_("1.2.3-alpha+alpha" "1.2.3" "alpha" "alpha" TRUE)
check_semver_version_("1.2.3-a." "1.2.3" "a." "" FALSE)
check_semver_version_("1.2.3-a.-" "1.2.3" "a.-" "" TRUE)
check_semver_version_("1.2.3-a.-." "1.2.3" "a.-." "" FALSE)
check_semver_version_("1.2.3-a.-.0" "1.2.3" "a.-.0" "" TRUE)
check_semver_version_("1.2.3-a.-.01" "1.2.3" "a.-.01" "" FALSE)
check_semver_version_("1.2.3-rc3" "1.2.3" "rc3" "" TRUE)
