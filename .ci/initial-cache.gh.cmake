# Dependencies options
set(ROBOTOLOGY_USES_GAZEBO ON CACHE BOOL "")
set(ROBOTOLOGY_USES_GZ ON CACHE BOOL "")
# ROBOTOLOGY_USES_MUJOCO is not really used as of January 2024
set(ROBOTOLOGY_USES_MUJOCO OFF CACHE BOOL "")
set(ROBOTOLOGY_USES_PCL_AND_VTK ON CACHE BOOL "")

# Octave is not supported on Windows or on Conda
if(NOT WIN32 AND NOT DEFINED ENV{CONDA_PREFIX})
  set(ROBOTOLOGY_USES_OCTAVE ON CACHE BOOL "")
endif()

if(NOT WIN32 OR DEFINED ENV{CONDA_PREFIX})
  set(ROBOTOLOGY_USES_PYTHON ON CACHE BOOL "")
endif()

# Profiles options
set(ROBOTOLOGY_ENABLE_ROBOT_TESTING ON CACHE BOOL "")
set(ROBOTOLOGY_ENABLE_ICUB_HEAD ON CACHE BOOL "")
set(ROBOTOLOGY_ENABLE_DYNAMICS ON CACHE BOOL "")
# ROBOTOLOGY_ENABLE_DYNAMICS_FULL_DEPS is only supported on Windows with conda
if(NOT (WIN32 AND NOT DEFINED ENV{CONDA_PREFIX}))
  set(ROBOTOLOGY_ENABLE_DYNAMICS_FULL_DEPS ON CACHE BOOL "")
endif()
set(ROBOTOLOGY_ENABLE_HUMAN_DYNAMICS ON CACHE BOOL "")
set(ROBOTOLOGY_ENABLE_ICUB_BASIC_DEMOS ON CACHE BOOL "")
set(ROBOTOLOGY_ENABLE_TELEOPERATION ON CACHE BOOL "")
set(ROBOTOLOGY_ENABLE_GRASPING OFF CACHE BOOL "")

if(NOT (WIN32 OR APPLE))
  set(ROBOTOLOGY_ENABLE_EVENT_DRIVEN ON CACHE BOOL "")
endif()

# ROBOTOLOGY_USES_ESDCAN is enabled in CI and conda packages on Windows
if(WIN32)
  set(ROBOTOLOGY_USES_ESDCAN ON CACHE BOOL "")
endif()
