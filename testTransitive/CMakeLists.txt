cmake_minimum_required(VERSION 3.25 FATAL_ERROR)

# ProjectWorkflow cmake modules
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../cmake")
include(ProjectWorkflow_Wrappers)

project(PWTransitiveTest VERSION 0.0.2
    LANGUAGES C
    DESCRIPTION "Executable that consumes LIBB and transitively LIBA"
    HOMEPAGE_URL "https://github.com/jasalamanca/ProjectWokflow.git")

find_package(LIBB 1.2.3 REQUIRED)
add_executable(TransitiveTest)
target_sources(TransitiveTest
    PRIVATE
    transitive_test.c)
target_link_libraries(TransitiveTest PRIVATE LIBB::b)
install(TARGETS TransitiveTest)

include(ProjectWorkflow)
PW_install(PACKAGE TransitiveTest)

include(FeatureSummary)
message(NOTICE "\nFEATURE SUMMARY\n--------------------------")
feature_summary(WHAT ALL)
