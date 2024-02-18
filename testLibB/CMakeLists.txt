cmake_minimum_required(VERSION 3.25 FATAL_ERROR)

# ProjectWorkflow cmake modules
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../cmake")
include(ProjectWorkflow_Wrappers)

project(PWLibB VERSION 1.2.3
    LANGUAGES C
    DESCRIPTION "Library that dependens on LIBA and that exports it package"
    HOMEPAGE_URL "https://github.com/jasalamanca/ProjectWokflow.git")

include(GNUInstallDirs)
include(ProjectWorkflow)

add_library(b STATIC)
target_sources(b PUBLIC FILE_SET HEADERS
    BASE_DIRS include
    FILES
    include/libb/b.h
    PRIVATE
    b.c)
find_package(LIBA 0.0.0-rc0 REQUIRED)
target_link_libraries(b PRIVATE LIBA::a)
install(TARGETS b EXPORT B
    FILE_SET HEADERS)

# To test with no PW/semver packages
find_package(OpenSSL REQUIRED)
target_link_libraries(b PRIVATE OpenSSL::SSL)

PW_install(PACKAGE LIBB
    EXPORTS B
    PACKAGES LIBA OpenSSL)

include(FeatureSummary)
message(NOTICE "\nFEATURE SUMMARY\n--------------------------")
feature_summary(WHAT ALL)
