# ProjectWokflow

A CMake module to ease package config file creation

## Why to use ProjectWorkflow

Main motivation to write this CMake module is to automate very common patterns when creating packages.

Obviously this is a very simple and incomplete module. Mainly because packaging is a complex subject and also because is not my purpose to write a complete module for everybody.

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

## How to use ProjectWorkflow

To use this module simply copy cmake directory to your project and add 
```cmake
# ProjectWorkflow cmake modules
list(APPEND CMAKE_MODULE_PATH "<path_to_cmake>")
```
to your CMakeLists.txt

> 📝 As you have CMake experience, you know that *CMAKE_MODULE_PATH* could be passed from command line as a more general method.

## Modules API

### PW_install(PACKAGE)

```
PW_install(
    PACKAGE <pkg_name> 
    [VERSION \<version>]
    [COMPATIBILITY <Semver|AnyNewerVersion|SameMajorVersion|SameMinorVersion|ExactVersion>]
    [NAMESPACE \<namespace>]
    [EXPORTS <export_name> ... ])
```

PW_install(PACKAGE) generates targets export files, package config file and a package version file in a coherent manner.

Apply common parameters to install(EXPORT), configure_package_config_file and install(FILES) typical sequence of commands.
Also generates a stereotypical input file for configure_package_config_file, avoiding this boilerplate.

If you want to use semver versions remember:
- You MUST set <PROJECT_NAME>_VERSION to semver you want.
  
  after calling *project* command because semver version are incompatible with *project* command.
  
  and before callin *PW_install* or *semver_write_version_config* commands.
  
```
example
    project(MyProject VERSION 1.2.3)
    set(MyProject_VERSION "1.2.3-alpha+build3")
```

- You can pass VERSION parameter to *PW_install* or *semver_write_version_config* commands if you need to change version on generated configuration files.
- You MUST set <PACKAGE_NAME>_FIND_SEMVER_VERSION before calling *find_package* command, because semver versions cannot be passed in directly via the *find_package* command.
```
example (to locate version "1.2.3-alpha+build3")
   set(OtherProject_FIND_SEMVER_VERSION "1.2.3-alpha+build3")
   find_package(OtherProject 1.2.3)
 example (to locate range "1.2.3-alpha+build3...<2")
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

PW_install(PACKAGE) will generate:
- *<pkg_name>Config.cmake*
- *<pkg_name>ConfigVersion.cmake*
- *<export_name>.cmake* for each indicated <export_name>

### semver_write_version_config()

```
semver_write_version_config(filename
    [VERSION <version>])
```

Builds a configuration version file for semver versions and writes it to *filename*.

Parameters:
- **filename** The filename where to write version file.
- **VERSION** Sets package version. If not set, <PROJECT_NAME>_VERSION is used.
