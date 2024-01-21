# ProjectWokflow
A CMake module to ease package config file creation

## Why to use ProjectWorkflow
Main motivation to write this CMake module is to automate very common patterns when creating packages.

Obviously this is a very simple and incomplete module. Mainly because packaging is a complex subject and 
also because is not my purpose to write a complete module for everybody.

If this simple packaging methods help you, feel free to use ProjectWorkflow.

Of course, comments and patches are welcomed, but be aware that this project is an experiment and my lack of spare time.

### Related
  - [Modern CMake Packaging: A Guide
Or, A Candle in the Dark](https://blog.vito.nyc/posts/cmake-pkg/)
  - [cmake-packages(7)](https://cmake.org/cmake/help/latest/manual/cmake-packages.7.html#creating-packages)
  - [install(EXPORT) command](https://cmake.org/cmake/help/latest/command/install.html#export)
  - [CMakePackageConfigHelpers module](https://cmake.org/cmake/help/latest/module/CMakePackageConfigHelpers.html)
  - [install(FILES) command](https://cmake.org/cmake/help/latest/command/install.html#files)
  - [Installing a Config.cmake file](https://www.f-ax.de/dev/2020/10/07/cmake-config-package.html)
  - [CMakeFindDependencyMacro module](https://cmake.org/cmake/help/latest/module/CMakeFindDependencyMacro.html)
  - [Semantic Versioning 2.0.0](https://semver.org/)
  - [Support for version suffixes](https://gitlab.kitware.com/cmake/cmake/-/issues/16716)
  - [find_package command](https://cmake.org/cmake/help/latest/command/find_package.html)
  - [write_basic_package_version_file command](https://cmake.org/cmake/help/latest/module/CMakePackageConfigHelpers.html#command:write_basic_package_version_file)
  - [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)

## How to use ProjectWorkflow

To use this module simply copy cmake directory to your project and add 
```cmake
# ProjectWorkflow cmake modules
list(APPEND CMAKE_MODULE_PATH "<path_to_cmake>")
```
to your CMakeLists.txt

> 📝 As you have CMake experience, you know that *CMAKE_MODULE_PATH* could be passed from command line as a more general method.

## Modules documentation
ProjectWorkflow provides:
  - [ProjectWorkflow](#projectworkflow-module) to ease installing packages and using semver versioning schema.
  - [ProjectWorkflow_Wrappers](#projectworkflow_wrappers-module) to better integrate ProjectWorkflow with standard CMake commands.
  - [semver](#semver-module) with semver support commands.
  
### ProjectWorkflow module

[PW_install(PACKAGE)](#PW_installPACKAGE)
```cmake
PW_install(
    PACKAGE <pkg_name> 
    [VERSION <version>]
    [COMPATIBILITY (Semver|AnyNewerVersion|SameMajorVersion|SameMinorVersion|ExactVersion)]
    [NAMESPACE <namespace>]
    [EXPORTS <export_name> ... ]
    [PACKAGES <pkg_name> ... ])
```

#### PW_install(PACKAGE)
PW_install(PACKAGE) generates targets export files, package config file and a package version file in a coherent manner.

Apply common parameters to install(EXPORT), configure_package_config_file and install(FILES) typical sequence of commands.

Also generates a stereotypical input file for configure_package_config_file, avoiding this boilerplate.

If you want to use semver versions, please use ProyectWorkflow_Wrappers module. If not posible remember:
  - You MUST set <PROJECT_NAME>_VERSION to semver version you want 
  after calling *project* command because semver version are incompatible with *project* command 
  and before callin *PW_install* or *semver_write_version_config* commands.

  example for project command.
```cmake
    project(MyProject VERSION 1.2.3)
    set(MyProject_VERSION "1.2.3-alpha+build3")
```
  - You can pass VERSION parameter to *PW_install* or *semver_write_version_config* commands if you need to change version on generated configuration files.
  - You MUST set <PACKAGE_NAME>_FIND_SEMVER_VERSION before calling *find_package* command, because semver versions cannot be passed in directly via the *find_package* command.

  example to locate version "1.2.3-alpha+build3"  
```cmake
   set(OtherProject_FIND_SEMVER_VERSION "1.2.3-alpha+build3")
   find_package(OtherProject 1.2.3)
```

  example to locate range "1.2.3-alpha+build3...<2"
```cmake
   set(OtherProject_FIND_SEMVER_VERSION "1.2.3-alpha+build3...<2")
   find_package(OtherProject 1.2.3...<2)
```

Parameters:
  - **PACKAGE** Introduces the package name.
  - **VERSION** Sets package version. If not set, <PROJECT_NAME>_VERSION is used.
  - **COMPATIBILITY** Sets package version mode. If not set, 'Semver' is used.

  Semver is new for semantic version support.
  The rest are supported by *write_basic_package_version_file*.

  - **NAMESPACE** Sets package namespace. If not set, *<pkg_name>::* is used.
  - **EXPORTS** For each <export_name> indicated, a target export file is generated and is included with the necessary path.
  - **PACKAGES** For each <pkg_name> indicated, a *find_package* is included in configuration file, with necessary parameters.

*PW_install(PACKAGE)* will generate:
  - *<pkg_name>Config.cmake*
  - *<pkg_name>ConfigVersion.cmake*
  - *<export_name>.cmake* for each indicated <export_name>

### ProjectWorkflow_Wrappers module

Overrides some CMake commands to ease integration when semver versions are used or to update internal information.

It is a tricky module but, as you could see, a convenient one.

To use this module you must include it before fist call to *project* command.

CMakeLists.txt example.
```cmake
cmake_minimum_required(VERSION 3.25 FATAL_ERROR)

# Add path to locate ProjectWorkflow cmake modules
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../cmake")

# Include wrappers
include(ProjectWorkflow_Wrappers)

# Call project
project(YourProject VERSION 1.2.3-rc0)

# Include ProjectWorkflow to use PW_install
include(ProjectWorkflow)

# rest of you project CMakeLists.txt
...
```

Overrides this CMake commands:
  - **project** To integrate semver versions so you can do
  ```cmake
      project(MyProject VERSION 1.2.3-alpha+build3)
  ```
  directly and don't need to do and remenber  
  ```cmake
      project(MyProject VERSION 1.2.3)
      set(MyProject_VERSION "1.2.3-alpha+build3")
  ```
  - **find_package** To integrate semver versions so you can do
  ```cmake
     find_package(OtherProject 1.2.3-alpha+build3...<2)
  ```
  directly and don't need to do and remenber  
  ```cmake
     set(OtherProject_FIND_SEMVER_VERSION "1.2.3-alpha+build3...<2")
     find_package(OtherProject 1.2.3...<2)
  ```
  
### semver module

[semver_write_version_config()](#semver_write_version_config)
```cmake
semver_write_version_config(<filename>
    [VERSION <semver_version>])
```

[semver_matches](#semver_matches)
```cmake
semver_matches(<semver_version> <semver_spec> <version_matches> <is_exact>)
```

[semver_validToCMakeVersion](#semver_validToCMakeVersion)
```cmake
semver_validToCMakeVersion(<semver_version> <version_cmake>)
```

[semver_validToCMakeSpec](#semver_validToCMakeSpec)
```cmake
semver_validToCMakeSpec(<semver_spec> <spec_cmake>)
```

[semver_specIntersection](#semver_specIntersection)
```cmake
semver_specIntersection(<semver_spec1> <semver_spec2> <semver_spec_intersection>)
```

#### semver_write_version_config()
Builds a configuration version file for semver versions and writes it to *filename*.

Parameters:
  - **filename** The filename where to write version file.
  - **VERSION** Sets package version. If not set, <PROJECT_NAME>_VERSION is used.

#### semver_matches()
Checks if semver <semver_version> matches semver version specification <semver_spec>.

Sets <version_matches> according to the check and <is_exact> will be true if and only if <semver_version> and <semver_spec> represent the same semver version.

Parameters:
  - **semver_version** The version to be checked.
```
<semver_version> ::= <basic>[-<pre_release>][+<build_metadata>]
  Each part follows [Semantic Versioning 2.0.0](https://semver.org/)
```
  - **semver_spec** Cmake semver specification to be matched. Follows cmake ranges specification.
```
<semver_range> ::= <semver_spec>[(...|...<)<semver_spec>]
 <semver_spec> ::= <basic_spec>[-<pre_release>][+<build_metadata>]
  <basic_spec> ::= <number>[.<number>[.<number>]]
    Every missing <number> is substituted by 0 to form a version <basic> version.
    See [Semantic Versioning 2.0.0](https://semver.org/) for details.
```
  - **version_matches** True or false indicating if <semver_version> matches <semver_spec>.
  - **is_exact** True if <semver_version> and <semver_spec> represent same semver version.

#### semver_validToCMakeVersion()
If receives a semver version then returns \<basic> part, else returns empty string.

Parameters:
  - **semver_version** A possibly semver version.
  - **version_cmake** <semver_version> transformed to be compatible with CMake versions.

#### semver_validToCMakeSpec()
If receives a semver specification then returns a CMake compatible transformation of a version search specification 
else an empty string is returned.

Parameters:
  - **semver_spec** A possibly semver version specification (version range).
  - **spec_cmake** <semver_spec> transformed to be compatible with CMake version ranges when <semver_spec> is a valid semver specification
or the empty string when <semver_spec> is not a semver valid specification.

#### semver_specIntersection()
Receives 2 semver specifications and returns a new semver specification that is their intersection
or empty string if intersection does not exist.

Parameters:
  - **<semver_spec1>** First semver version specification.
  - **<semver_spec2>** Second semver version specification.
  - **<semver_spec_intersection>** Semver version specification for intersection or empty string if intersection is empty.
