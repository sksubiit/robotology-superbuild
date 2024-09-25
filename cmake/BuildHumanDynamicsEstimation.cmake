# Copyright (C) 2018  iCub Facility, Istituto Italiano di Tecnologia
# CopyPolicy: Released under the terms of the LGPLv2.1 or later, see LGPL.TXT

include(YCMEPHelper)
include(FindOrBuildPackage)

find_or_build_package(YARP QUIET)
find_or_build_package(ICUB QUIET)
find_or_build_package(iDynTree QUIET)
find_or_build_package(osqp QUIET)
find_or_build_package(OsqpEigen QUIET)
find_or_build_package(robometry QUIET)

if(WIN32)
    list(APPEND HDE_CMAKE_ARGS -DXSENS_MVN_USE_SDK:BOOL=${ROBOTOLOGY_USES_XSENS_MVN_SDK} -DENABLE_XsensSuit:BOOL=${ROBOTOLOGY_USES_XSENS_MVN_SDK} )
endif()

ycm_ep_helper(HumanDynamicsEstimation TYPE GIT
              STYLE GITHUB
              REPOSITORY robotology/human-dynamics-estimation.git
              TAG master
              COMPONENT human_dynamics
              FOLDER src
              CMAKE_ARGS -DHUMANSTATEPROVIDER_ENABLE_VISUALIZER:BOOL=ON ${HDE_CMAKE_ARGS}
              DEPENDS iDynTree
                      YARP
                      osqp
                      OsqpEigen
                      ICUB
                      robometry)

set(HumanDynamicsEstimation_CONDA_DEPENDENCIES eigen)
