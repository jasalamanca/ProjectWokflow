cmake_minimum_required(VERSION 3.25 FATAL_ERROR)

# ProjectWorkflow cmake modules
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../cmake")

project(PWLibB VERSION 1.2.3
    LANGUAGES C
    DESCRIPTION "Library that dependens on LIBA and that exports it package"
    HOMEPAGE_URL "https://github.com/jasalamanca/ProjectWokflow.git")

set(PWLibB_VERSION "1.2.3")

include(GNUInstallDirs)
include(ProjectWorkflow)

add_library(b STATIC)
target_sources(b PUBLIC FILE_SET HEADERS
    BASE_DIRS include
    FILES
    include/libb/b.h
    PRIVATE
    b.c)
set(LIBA_FIND_SEMVER_VERSION "0.0.0-rc0")
find_package(LIBA 0 REQUIRED)
target_link_libraries(b PRIVATE LIBA::a)
install(TARGETS b EXPORT B
    FILE_SET HEADERS)

PW_install(PACKAGE LIBB
    EXPORTS B
    PACKAGES LIBA)

include(FeatureSummary)
message(NOTICE "\nFEATURE SUMMARY\n--------------------------")
feature_summary(WHAT ALL)
