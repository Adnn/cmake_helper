# CMake helper

CMake scripts to provide helpers and factorize common setups for CMake based projects.

## Usage

This project should be added as a submodule to downstream project repository, cloning it in 'cmake/' subfolder:

    cd $PROJECT
    git submodule add git@github.com:Adnn/cmake_helper.git cmake

It is then a matter of including the `include.cmake` file at the root of cmake helpers
at the beginning of the root CMakeLists.txt of downstream project:

    cmake_minimum_required(VERSION 3.12)
    project(Downstream)

    # Include cmake_helper submodule
    include("cmake/include.cmake")

    ...
