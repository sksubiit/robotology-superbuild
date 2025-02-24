macro(set_tag tag_name tag_value)
    if(NOT ${tag_name})
        set(${tag_name} ${tag_value})
    endif()
endmacro()

# External projects
set_tag(osqp_REPOSITORY robotology-dependencies/osqp.git)
set_tag(osqp_TAG v0.6.3.1)
set_tag(manif_TAG 0.0.5)
set_tag(CppAD_TAG 20250000.2)
set_tag(proxsuite_TAG v0.7.1)
set_tag(casadi_TAG 3.6.6)
set_tag(casadi-matlab-bindings_TAG v3.6.6.0)

# Robotology projects
# Pin YARP and yarp-devices-ros2 to a version before the yarp::dev::ReturnValue changes
set_tag(YARP_TAG 43ba0305f8ca690cea5c2a8a6bcdcec60d3ddd0a)
set_tag(yarp-devices-ros2_TAG e4ba8fa2efe7486edd3ade40b2236e69acb6ab37)
set_tag(ICUB_TAG devel)
set_tag(RobotTestingFramework_TAG devel)
set_tag(blockTest_TAG devel)
set_tag(icub-tests_TAG devel)
set_tag(iDynTree_TAG master)
set_tag(icub-firmware_TAG devel)
set_tag(icub_firmware_shared_TAG devel)
set_tag(icub-firmware-build_TAG devel)
set_tag(yarp-matlab-bindings_TAG master)
set_tag(GazeboYARPPlugins_TAG devel)
set_tag(robots-configuration_TAG devel)
set_tag(icub-models_TAG devel)
set_tag(icub-gazebo_TAG devel)
set_tag(icub-gazebo-wholebody_TAG devel)
set_tag(whole-body-controllers_TAG master)
set_tag(gym-ignition_TAG v1.3.1)
