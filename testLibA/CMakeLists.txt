cmake_minimum_required(VERSION 3.25 FATAL_ERROR)

# ProjectWorkflow cmake modules
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../cmake")

project(PWLibA VERSION 0.0.0
    LANGUAGES C
    DESCRIPTION "Library without dependencies that exports it package"
    HOMEPAGE_URL "https://github.com/jasalamanca/ProjectWokflow.git")

include(GNUInstallDirs)
include(ProjectWorkflow)

# PW_install(PACKAGE) example
add_library(a STATIC)
target_sources(a PUBLIC FILE_SET HEADERS
    BASE_DIRS include
    FILES
    include/liba/a.h
    PRIVATE
    a.c)
install(TARGETS a EXPORT A
    FILE_SET HEADERS)

PW_install(PACKAGE LIBA VERSION "${PWLibA_VERSION}"
    EXPORTS A)
