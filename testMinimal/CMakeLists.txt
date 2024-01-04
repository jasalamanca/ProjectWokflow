cmake_minimum_required(VERSION 3.25 FATAL_ERROR)

project(PWMinimalTest VERSION 0.0.1
    LANGUAGES C
    DESCRIPTION "Executable that consumes LIBA"
    HOMEPAGE_URL "https://github.com/jasalamanca/ProjectWokflow.git")

# find_package(LIBA 0.0.0 REQUIRED)
find_package(LIBA REQUIRED)
add_executable(MinimalTest)
target_sources(MinimalTest
    PRIVATE
    minimal_test.c)
target_link_libraries(MinimalTest PRIVATE a)
install(TARGETS MinimalTest)
