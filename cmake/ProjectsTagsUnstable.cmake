macro(set_tag tag_name tag_value)
    if(NOT ${tag_name})
        set(${tag_name} ${tag_value})
    endif()
endmacro()

# External projects
set_tag(osqp_TAG v0.6.2)
set_tag(manif_REPOSITORY robotology-dependencies/manif.git)
set_tag(manif_TAG 0.0.4.102)
set_tag(qhull_TAG 2020.2)
set_tag(CppAD_TAG 20230000.0)
set_tag(casadi_TAG 3.5.5.4)
set_tag(casadi-matlab-bindings_TAG v3.5.5.2)

# Robotology projects
set_tag(YARP_TAG master)
set_tag(ICUB_TAG devel)
set_tag(RobotTestingFramework_TAG devel)
set_tag(blockTest_TAG devel)
set_tag(WBToolbox_TAG devel)
set_tag(BlockFactory_TAG devel)
set_tag(icub-tests_TAG devel)
set_tag(iDynTree_TAG devel)
set_tag(icub_firmware_shared_TAG devel)
set_tag(yarp-matlab-bindings_TAG master)
set_tag(GazeboYARPPlugins_TAG devel)
set_tag(robots-configuration_TAG devel)
set_tag(icub-models_TAG devel)
set_tag(icub-gazebo_TAG devel)
set_tag(icub-gazebo-wholebody_TAG devel)
set_tag(whole-body-controllers_TAG master)
set_tag(gym-ignition_TAG v1.3.1)
