# Changelog for project ProjectWorkflow

## [Unreleased]

---

## [0.1.0] - 2024-01-21
Introduces wrappers for CMake commands to acomodate semver versions.

### Added
  - ProjectWorkflow_Wrappers module.
  - [semver] semver_matches command.
  - [semver] semver_validToCMakeVersion command.
  - [semver] semver_validToCMakeSpec command.
  - [semver] semver_specIntersection command.

### Changed
  - [pw] Version is removed from path where package configuration files are installed.

### Fixed
  - [semver] semver_matches always set responses.
  - [pw] PW_install when creating package configuration file, for transitive packages, 
    will set <package_name>_FIND_SEMVER_VERSION only if strictly necessary.
    
---

## [0.0.0] - 2024-01-08
Initial support for installing configuration and semver version files for packages.

### Added
- [pw] PW_install(PACKAGE)
- [semver] semver_write_version_config()

---
