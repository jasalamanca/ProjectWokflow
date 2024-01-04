# ProjectWokflow

A CMake module to ease package config file creation

## Why to use ProjectWorkflow

Main motivation to write this CMake module is to automate very common patterns when creating packages.

Obviously this is a very simple and incomplete module. Mainly because packages is a complex subject and also because is not my purpouse to write a complete module for everybody.

If this simple packaging methods help you, feel free to use ProjectWorkflow.

Of course, comments and patches are welcomed, but be aware that this project is an experiment and my lack of spare time.

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

> PW_install(PACKAGE <pkg_name> [VERSION \<version>] [EXPORTS <export_name> ... ])

PW_install(PACKAGE) generates targets export files, package config file and a package version file in a coherent manner.
Apply common parameters to install(EXPORT), configure_package_config_file and install(FILES) typical sequence of commands.
Also generates a stereotypical input file for configure_package_config_file, avoiding this boilerplate.

- **PACKAGE** Introduces the package name.
- **VERSION** Establishes package version. If not set, <pkg_name>_VERSION is used.
- **EXPORTS** For each <export_name> indicated, a target export file is generated and is included with the necessary path.

PW_install(PACKAGE) will generate:
- *<pkg_name>Config.cmake*
- *<pkg_name>ConfigVersion.cmake*
- *<export_name>.cmake* for each indicated <export_name>
