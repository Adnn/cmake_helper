set (CMC_ROOT_DIR ${CMAKE_CURRENT_LIST_DIR})

# Where to look for the files defined by this project
list(APPEND CMAKE_MODULE_PATH 
     "${CMC_ROOT_DIR}/templates"
     "${CMC_ROOT_DIR}/utilities")
