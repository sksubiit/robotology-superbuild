# Copyright (C) Fondazione Istituto Italiano di Tecnologia
# CopyPolicy: Released under the terms of the LGPLv2.1 or later, see LGPL.TXT

# Redefine find_or_build_package, ycm_ep_helper and rob_sup_pure_python_ycm_ep_helper
# as macros to extract metadata necessary for conda recipe
# generation from the RobotologySuperbuildLogic file.
# Note that these were originally functions, but they are re-defined as macros so that
# all the variables that they create are placed in the global scope, and in this script
# we can access variables such as ${_YH_${_cmake_pkg}_CMAKE_ARGS}
macro(ycm_ep_helper _name)
  # Check arguments
  set(_options )
  set(_oneValueArgs TYPE
                    STYLE
                    COMPONENT
                    FOLDER
                    EXCLUDE_FROM_ALL
                    REPOSITORY  # GIT, SVN and HG
                    TAG         # GIT and HG only
                    REVISION    # SVN only
                    USERNAME    # SVN only
                    PASSWORD    # SVN only
                    TRUST_CERT  # SVN only
                    TEST_BEFORE_INSTALL
                    TEST_AFTER_INSTALL
                    TEST_EXCLUDE_FROM_MAIN
                    CONFIGURE_SOURCE_DIR # DEPRECATED Since YCM 0.10
                    SOURCE_SUBDIR)
  set(_multiValueArgs CMAKE_ARGS
                      CMAKE_CACHE_ARGS
                      CMAKE_CACHE_DEFAULT_ARGS
                      DEPENDS
                      DOWNLOAD_COMMAND
                      UPDATE_COMMAND
                      PATCH_COMMAND
                      CONFIGURE_COMMAND
                      BUILD_COMMAND
                      INSTALL_COMMAND
                      TEST_COMMAND
                      CLEAN_COMMAND)

  cmake_parse_arguments(_YH_${_name} "${_options}" "${_oneValueArgs}" "${_multiValueArgs}" "${ARGN}")

  get_property(_projects GLOBAL PROPERTY YCM_PROJECTS)
  list(APPEND _projects ${_name})
  list(REMOVE_DUPLICATES _projects)
  set_property(GLOBAL PROPERTY YCM_PROJECTS ${_projects})
endmacro()

macro(ROB_SUP_PURE_PYTHON_YCM_EP_HELPER _name)
  # Check arguments
  set(_options)
  set(_oneValueArgs COMPONENT
                    FOLDER
                    REPOSITORY
                    TAG)
  set(_multiValueArgs DEPENDS)

  cmake_parse_arguments(_PYH_${_name} "${_options}" "${_oneValueArgs}" "${_multiValueArgs}" "${ARGN}")

  ycm_ep_helper(${_name} TYPE GIT
                         STYLE GITHUB
                         REPOSITORY ${_PYH_${_name}_REPOSITORY}
                         DEPENDS ${_PYH_${_name}_DEPENDS}
                         TAG ${_PYH_${_name}_TAG}
                         COMPONENT ${_PYH_${_name}_COMPONENT}
                         FOLDER ${_PYH_${_name}_FOLDER})

  # Set this variable so that RobotologySuperbuildGenerateCondaRecipes.cmake pass this information to the
  # Python scripts that generates the conda recipes
  set(${_name}_CONDA_BUILD_TYPE "pure_python")
endmacro()

macro(find_or_build_package _pkg)
  get_property(_superbuild_pkgs GLOBAL PROPERTY YCM_PROJECTS)
  if(NOT ${_pkg} IN_LIST _superbuild_pkgs)
    include(Build${_pkg})
  endif()
endmacro()

set(metametadata_file ${CMAKE_CURRENT_BINARY_DIR}/conda/robotology-superbuild-conda-metametadata.yaml)

macro(generate_metametadata_file)
  # Metametadata file name
  file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/conda)
  set(metametadata_file_contents "conda-packages-metametadata:\n")

  get_property(_superbuild_pkgs GLOBAL PROPERTY YCM_PROJECTS)
  foreach(_cmake_pkg IN LISTS _superbuild_pkgs)
    # Compute conda version
    # We do it for all packages as this is also necessary
    # for packages for which <_cmake_pkg>_CONDA_PKG_CONDA_FORGE_OVERRIDE
    # is defined when generating the metapackages
    if(DEFINED ${_cmake_pkg}_TAG)
     set(${_cmake_pkg}_CONDA_TAG ${${_cmake_pkg}_TAG})
    else()
     set(${_cmake_pkg}_CONDA_TAG ${_YH_${_cmake_pkg}_TAG})
    endif()

    if(NOT DEFINED ${_cmake_pkg}_CONDA_VERSION)
      set(${_cmake_pkg}_CONDA_VERSION ${${_cmake_pkg}_CONDA_TAG})
    endif()

    # If the build_type is not defined, it is assumed to be cmake
    if(NOT DEFINED ${_cmake_pkg}_CONDA_BUILD_TYPE)
      set(${_cmake_pkg}_CONDA_BUILD_TYPE "cmake")
    endif()


    # If a package is already available in conda-forge, we use
    # that one by defining appropriately the <_cmake_pkg>_CONDA_PACKAGE_NAME
    # and <_cmake_pkg>_CONDA_PKG_CONDA_FORGE_OVERRIDE variables
    if(DEFINED ${_cmake_pkg}_CONDA_PKG_CONDA_FORGE_OVERRIDE AND
       "${${_cmake_pkg}_CONDA_PKG_CONDA_FORGE_OVERRIDE}")
      continue()
    endif()

    # Compute conda CMake options
    set(${_cmake_pkg}_CONDA_CMAKE_ARGS ${_YH_${_cmake_pkg}_CMAKE_ARGS})
    list(APPEND ${_cmake_pkg}_CONDA_CMAKE_ARGS ${_YH_${_cmake_pkg}_CMAKE_CACHE_ARGS})
    list(APPEND ${_cmake_pkg}_CONDA_CMAKE_ARGS ${_YH_${_cmake_pkg}_CMAKE_CACHE_DEFAULT_ARGS})
    # Convert YCM_EP_ADDITIONAL_CMAKE_ARGS to list
    string(REPLACE " " ";" YCM_EP_ADDITIONAL_CMAKE_ARGS_AS_LIST "${YCM_EP_ADDITIONAL_CMAKE_ARGS}")
    list(APPEND ${_cmake_pkg}_CONDA_CMAKE_ARGS ${YCM_EP_ADDITIONAL_CMAKE_ARGS_AS_LIST})

    # Escape backlash for insertion in yaml
    string(REPLACE "\\" "\\\\" ${_cmake_pkg}_CONDA_CMAKE_ARGS "${${_cmake_pkg}_CONDA_CMAKE_ARGS}")


    # Compute conda dependencies
    # Always append so dependencies not tracked by the superbuild can be injected by
    # defining a ${_cmake_pkg}_CONDA_DEPENDENCIES in CondaGenerationOptions.cmake
    foreach(_cmake_dep IN LISTS _YH_${_cmake_pkg}_DEPENDS)
      list(APPEND ${_cmake_pkg}_CONDA_DEPENDENCIES ${${_cmake_dep}_CONDA_PKG_NAME})
    endforeach()
    
    # If vtk is in the dependencies, we also need libboost-devel
    # See https://github.com/robotology/robotology-superbuild/issues/1276
    if("vtk" IN_LIST ${_cmake_pkg}_CONDA_DEPENDENCIES)
      list(APPEND ${_cmake_pkg}_CONDA_DEPENDENCIES "libboost-devel")
    endif()

    # Compute conda github repository
    # We remove the trailing .git (if present)
    string(REPLACE ".git" "" ${_cmake_pkg}_CONDA_GIHUB_REPO "${_YH_${_cmake_pkg}_REPOSITORY}")

    # Dump metametadata in yaml format
    string(APPEND metametadata_file_contents "  ${${_cmake_pkg}_CONDA_PKG_NAME}:\n")
    string(APPEND metametadata_file_contents "    name: ${${_cmake_pkg}_CONDA_PKG_NAME}\n")
    string(APPEND metametadata_file_contents "    version: ${${_cmake_pkg}_CONDA_VERSION}\n")
    string(APPEND metametadata_file_contents "    github_repo: ${${_cmake_pkg}_CONDA_GIHUB_REPO}\n")
    string(APPEND metametadata_file_contents "    github_tag: ${${_cmake_pkg}_CONDA_TAG}\n")
    string(APPEND metametadata_file_contents "    conda_build_number: ${CONDA_BUILD_NUMBER}\n")
    string(APPEND metametadata_file_contents "    build_type: ${${_cmake_pkg}_CONDA_BUILD_TYPE}\n")

    if(_YH_${_cmake_pkg}_SOURCE_SUBDIR)
      string(APPEND metametadata_file_contents "    source_subdir: ${_YH_${_cmake_pkg}_SOURCE_SUBDIR}\n")
    endif()


    if(NOT "${${_cmake_pkg}_CONDA_CMAKE_ARGS}" STREQUAL "")
      string(APPEND metametadata_file_contents "    cmake_args:\n")
      foreach(_cmake_arg IN LISTS ${_cmake_pkg}_CONDA_CMAKE_ARGS)
        string(APPEND metametadata_file_contents "      - \"${_cmake_arg}\"\n")
      endforeach()
      # If some project requires python, add the appropriate CMake option so the 
      # See https://github.com/robotology/robotology-superbuild/pull/749#issuecomment-845936017
      if("python" IN_LIST ${_cmake_pkg}_CONDA_DEPENDENCIES)
        if(WIN32)
          string(APPEND metametadata_file_contents "      - \"-DPython3_EXECUTABLE:PATH=%PYTHON%\"\n")
          string(APPEND metametadata_file_contents "      - \"-DPython_EXECUTABLE:PATH=%PYTHON%\"\n")
        else()
          string(APPEND metametadata_file_contents "      - \"-DPython3_EXECUTABLE:PATH=$PYTHON\"\n")
          string(APPEND metametadata_file_contents "      - \"-DPython_EXECUTABLE:PATH=$PYTHON\"\n")
        endif()
      endif()
    endif()

    if(NOT "${${_cmake_pkg}_CONDA_DEPENDENCIES}" STREQUAL "")
      string(APPEND metametadata_file_contents "    dependencies:\n")
      foreach(_dep IN LISTS ${_cmake_pkg}_CONDA_DEPENDENCIES)
        string(APPEND metametadata_file_contents "      - ${_dep}\n")
      endforeach()
    endif()
    
    if(NOT "${${_cmake_pkg}_CONDA_BUILD_DEPENDENCIES_EXPLICIT}" STREQUAL "")
      string(APPEND metametadata_file_contents "    build_dependencies_explicit:\n")
      foreach(_build_dep IN LISTS ${_cmake_pkg}_CONDA_BUILD_DEPENDENCIES_EXPLICIT)
        string(APPEND metametadata_file_contents "      - ${_build_dep}\n")
      endforeach()
    endif()

    if(NOT "${${_cmake_pkg}_CONDA_ENTRY_POINTS}" STREQUAL "")
      string(APPEND metametadata_file_contents "    entry_points:\n")
      foreach(_entry_point IN LISTS ${_cmake_pkg}_CONDA_ENTRY_POINTS)
        string(APPEND metametadata_file_contents "      - ${_entry_point}\n")
      endforeach()
    endif()
    
    # By default we rely on properly set run_exports configurations in conda recipes
    # to avoid to manually set run dependencies. However, in some cases (cmake-only 
    # libraries, header-only libraries) run_exports is not used, so it is necessary 
    # to manually specify them as run dependencies
    if("ycm-cmake-modules" IN_LIST ${_cmake_pkg}_CONDA_DEPENDENCIES)
      list(APPEND ${_cmake_pkg}_CONDA_RUN_DEPENDENCIES_EXPLICIT "ycm-cmake-modules")
    endif()
    if("eigen" IN_LIST ${_cmake_pkg}_CONDA_DEPENDENCIES)
      list(APPEND ${_cmake_pkg}_CONDA_RUN_DEPENDENCIES_EXPLICIT "eigen")
    endif()
    if(NOT "${${_cmake_pkg}_CONDA_RUN_DEPENDENCIES_EXPLICIT}" STREQUAL "")
      string(APPEND metametadata_file_contents "    run_dependencies_explicit:\n")
      foreach(_dep IN LISTS ${_cmake_pkg}_CONDA_RUN_DEPENDENCIES_EXPLICIT)
        string(APPEND metametadata_file_contents "      - ${_dep}\n")
      endforeach()
    endif()


    # If some dependency require opengl to build and we are on Linux, add the required packages
    # See https://conda-forge.org/docs/maintainer/knowledge_base.html?#libgl
    if(${CMAKE_SYSTEM_NAME} STREQUAL "Linux")
      if("qt" IN_LIST ${_cmake_pkg}_CONDA_DEPENDENCIES OR
         "qt-main" IN_LIST ${_cmake_pkg}_CONDA_DEPENDENCIES OR
         "freeglut" IN_LIST ${_cmake_pkg}_CONDA_DEPENDENCIES OR
         "glew" IN_LIST ${_cmake_pkg}_CONDA_DEPENDENCIES OR
         "glfw" IN_LIST ${_cmake_pkg}_CONDA_DEPENDENCIES OR
         "irrlicht" IN_LIST ${_cmake_pkg}_CONDA_DEPENDENCIES OR
         "idyntree" IN_LIST ${_cmake_pkg}_CONDA_DEPENDENCIES OR
         "vtk" IN_LIST ${_cmake_pkg}_CONDA_DEPENDENCIES)
        string(APPEND metametadata_file_contents "    require_opengl_linux: true\n")
      endif()
    endif()

    # If some dependency requires numpy, add the appropriate runtime dependency
    # See https://conda-forge.org/docs/maintainer/knowledge_base.html#building-against-numpy
    if("python" IN_LIST ${_cmake_pkg}_CONDA_DEPENDENCIES)
      string(APPEND metametadata_file_contents "    add_python_runtime_dep: true\n")
    endif()

    # If some dependency requires numpy, add the appropriate runtime dependency
    # See https://conda-forge.org/docs/maintainer/knowledge_base.html#building-against-numpy
    if("numpy" IN_LIST ${_cmake_pkg}_CONDA_DEPENDENCIES)
      string(APPEND metametadata_file_contents "    add_numpy_runtime_dep: true\n")
    endif()

    string(APPEND metametadata_file_contents "\n")
    
    string(APPEND metametadata_file_contents "\n")
  endforeach()

  # If we generate robotology-distro metapackages, we need also to add the
  # conda-metapackages-metametadata: section that will be used to generate the metapackages recipes
  # To the people from the future: I am really sorry about the amount of "meta" in these names
  if(CONDA_GENERATE_ROBOTOLOGY_METAPACKAGES)
    string(APPEND metametadata_file_contents "conda-metapackages-metametadata:\n")
    string(APPEND metametadata_file_contents "  robotology_superbuild_version: ${CONDA_ROBOTOLOGY_SUPERBUILD_VERSION}\n")
    string(APPEND metametadata_file_contents "  conda_build_number: ${CONDA_BUILD_NUMBER}\n")
    string(APPEND metametadata_file_contents "  robotology_all_packages: \n")
    foreach(_cmake_pkg IN LISTS _superbuild_pkgs)
      string(APPEND metametadata_file_contents "    - name: ${${_cmake_pkg}_CONDA_PKG_NAME}\n")
      string(APPEND metametadata_file_contents "      version: \"${${_cmake_pkg}_CONDA_VERSION}\"\n")
    endforeach()

  endif()

  file(WRITE ${metametadata_file} ${metametadata_file_contents})
  message(STATUS "Saved metametadata in ${metametadata_file}")
endmacro()

macro(generate_conda_recipes)
  set(python_generation_script "${CMAKE_CURRENT_SOURCE_DIR}/conda/python/generate_conda_recipes_from_metametadata.py")
  set(generated_conda_recipes_dir "${CMAKE_CURRENT_BINARY_DIR}/conda/generated_recipes")
  file(MAKE_DIRECTORY ${generated_conda_recipes_dir})
  if(CONDA_GENERATE_ROBOTOLOGY_METAPACKAGES)
    set(python_generation_script_additional_options "--generate_distro_metapackages")
  else()
    set(python_generation_script_additional_options "")
  endif()
  execute_process(COMMAND python ${python_generation_script} -i ${metametadata_file} -o ${generated_conda_recipes_dir} ${python_generation_script_additional_options} RESULT_VARIABLE CONDA_GENERATION_SCRIPT_RETURN_VALUE)
  if(CONDA_GENERATION_SCRIPT_RETURN_VALUE STREQUAL "0")
    message(STATUS "conda recipes correctly generated in ${generated_conda_recipes_dir}.")
    message(STATUS "To build the generated conda recipes, navigate to the directory and run conda build . in it.")
  else()
    message(FATAL_ERROR "Error in execution of script ${python_generation_script}")
  endif()
endmacro()


# Explicitly add YCM as it is not handled as other projects
get_property(_projects GLOBAL PROPERTY YCM_PROJECTS)
list(APPEND _projects YCM)
set_property(GLOBAL PROPERTY YCM_PROJECTS ${_projects})
set(_YH_YCM_REPOSITORY robotology/ycm.git)
# Use ycm-cmake-modules as name as in debian
set(YCM_CONDA_PKG_NAME ycm-cmake-modules)
set(YCM_CONDA_PKG_CONDA_FORGE_OVERRIDE ON)

include(RobotologySuperbuildLogic)
include(CondaGenerationOptions)

get_property(_superbuild_pkgs GLOBAL PROPERTY YCM_PROJECTS)

# First of all: define the conda package name of each cmake project
# This needs to be done first for all packages as it is used later
# when referring to dependencies
foreach(_cmake_pkg IN LISTS _superbuild_pkgs)
  # Unless the <_cmake_pkg>_CONDA_PKG_NAME variable is explicitly defined,
  # we use the git repo name as the conda pkg name as the convention are similar
  # (lowercase names, separated by dash)
  if(NOT DEFINED ${_cmake_pkg}_CONDA_PKG_NAME)
    string(REGEX MATCH "^[^\/:]+\/([^\/:]+).git$" UNUSED_REGEX_MATCH_OUTPUT "${_YH_${_cmake_pkg}_REPOSITORY}")
    set(${_cmake_pkg}_CONDA_PKG_NAME ${CMAKE_MATCH_1})
    if("${${_cmake_pkg}_CONDA_PKG_NAME}" STREQUAL "")
      message(FATAL_ERROR "Error in extracting conda package name for CMake package ${_cmake_pkg} with repo ${_YH_${_cmake_pkg}_REPOSITORY}")
    endif()
  endif()
endforeach()

# Second step: generate the ${CMAKE_CURRENT_BINARY_DIR}/conda/robotology-superbuild-conda-metametadata.yaml,
# that contains in yaml form the dependencies and options information contained
# in the CMake scripts of the robotology-superbuild
generate_metametadata_file()

# Third step: generate the conda recipes from the metametadata in
# ${CMAKE_CURRENT_BINARY_DIR}/conda/generate_recipes
generate_conda_recipes()
