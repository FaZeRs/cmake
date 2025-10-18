# Helper function to configure cppcheck command
function(
  _configure_cppcheck_command
  WARNINGS_AS_ERRORS
  CPPCHECK_OPTIONS
  OUTPUT_VAR)
  find_program(CPPCHECK cppcheck)

  if(CPPCHECK)
    if(CMAKE_GENERATOR MATCHES ".*Visual Studio.*")
      set(CPPCHECK_TEMPLATE "vs")
    else()
      set(CPPCHECK_TEMPLATE "gcc")
    endif()

    if("${CPPCHECK_OPTIONS}" STREQUAL "")
      # Enable all warnings that are actionable by the user of this toolset
      # style should enable the other 3, but we'll be explicit just in case
      set(SUPPRESS_DIR "*:${CMAKE_CURRENT_BINARY_DIR}/_deps/*.h")

      message(STATUS "CPPCHECK_OPTIONS suppress: ${SUPPRESS_DIR}")
      set(CPPCHECK_COMMAND
          ${CPPCHECK} --template=${CPPCHECK_TEMPLATE} --enable=style,performance,warning,portability --inline-suppr
          # We cannot act on a bug/missing feature of cppcheck
          --suppress=cppcheckError --suppress=internalAstError
          # if a file does not have an internalAstError, we get an unmatchedSuppression error
          --suppress=unmatchedSuppression
          # noisy and incorrect sometimes
          --suppress=passedByValue
          # ignores code that cppcheck thinks is invalid C++
          --suppress=syntaxError --suppress=preprocessorErrorDirective
          # ignores static_assert type failures
          --suppress=knownConditionTrueFalse --inconclusive --suppress=${SUPPRESS_DIR})
    else()
      # if the user provides a CPPCHECK_OPTIONS with a template specified, it will override this template
      set(CPPCHECK_COMMAND ${CPPCHECK} --template=${CPPCHECK_TEMPLATE} ${CPPCHECK_OPTIONS})
    endif()

    if(NOT
       "${CMAKE_CXX_STANDARD}"
       STREQUAL
       "")
      set(CPPCHECK_COMMAND ${CPPCHECK_COMMAND} --std=c++${CMAKE_CXX_STANDARD})
    endif()

    if(${WARNINGS_AS_ERRORS})
      list(APPEND CPPCHECK_COMMAND --error-exitcode=2)
    endif()

    message(STATUS "CPPCHECK_COMMAND: ${CPPCHECK_COMMAND}")
    set(${OUTPUT_VAR}
        "${CPPCHECK_COMMAND}"
        PARENT_SCOPE)
    set(${OUTPUT_VAR}_FOUND
        TRUE
        PARENT_SCOPE)
  else()
    set(${OUTPUT_VAR}_FOUND
        FALSE
        PARENT_SCOPE)
    message(${WARNING_MESSAGE} "cppcheck requested but executable not found")
  endif()
endfunction()

macro(
  enable_cppcheck_target
  target
  WARNINGS_AS_ERRORS
  CPPCHECK_OPTIONS)
  _configure_cppcheck_command(${WARNINGS_AS_ERRORS} "${CPPCHECK_OPTIONS}" CPPCHECK_COMMAND)
  if(CPPCHECK_COMMAND_FOUND)
    set_target_properties(${target} PROPERTIES CXX_CPPCHECK "${CPPCHECK_COMMAND}")
  endif()
endmacro()

macro(enable_cppcheck_global WARNINGS_AS_ERRORS CPPCHECK_OPTIONS)
  _configure_cppcheck_command(${WARNINGS_AS_ERRORS} "${CPPCHECK_OPTIONS}" CMAKE_CXX_CPPCHECK)
endmacro()

# Helper function to configure clang-tidy command
function(
  _configure_clang_tidy_command
  WARNINGS_AS_ERRORS
  IS_GLOBAL
  OUTPUT_VAR)
  find_program(CLANGTIDY clang-tidy)

  if(CLANGTIDY)
    # construct the clang-tidy command line
    set(CLANG_TIDY_COMMAND ${CLANGTIDY} -extra-arg=-Wno-unknown-warning-option
                           -extra-arg=-Wno-ignored-optimization-argument -extra-arg=-Wno-unused-command-line-argument)

    # add -p flag for global mode
    if(${IS_GLOBAL})
      list(APPEND CLANG_TIDY_COMMAND -p)
    endif()

    # set standard
    if(NOT
       "${CMAKE_CXX_STANDARD}"
       STREQUAL
       "")
      if("${CLANG_TIDY_OPTIONS_DRIVER_MODE}" STREQUAL "cl")
        set(CLANG_TIDY_COMMAND ${CLANG_TIDY_COMMAND} -extra-arg=/std:c++${CMAKE_CXX_STANDARD})
      else()
        set(CLANG_TIDY_COMMAND ${CLANG_TIDY_COMMAND} -extra-arg=-std=c++${CMAKE_CXX_STANDARD})
      endif()
    endif()

    # set warnings as errors
    if(${WARNINGS_AS_ERRORS})
      list(APPEND CLANG_TIDY_COMMAND -warnings-as-errors=*)
    endif()

    if(${IS_GLOBAL})
      message("Also setting clang-tidy globally")
    else()
      message(STATUS "CLANG_TIDY_COMMAND: ${CLANG_TIDY_COMMAND}")
    endif()

    set(${OUTPUT_VAR}
        "${CLANG_TIDY_COMMAND}"
        PARENT_SCOPE)
    set(${OUTPUT_VAR}_FOUND
        TRUE
        PARENT_SCOPE)
  else()
    set(${OUTPUT_VAR}_FOUND
        FALSE
        PARENT_SCOPE)
    message(${WARNING_MESSAGE} "clang-tidy requested but executable not found")
  endif()
endfunction()

macro(enable_clang_tidy_target target WARNINGS_AS_ERRORS)
  _configure_clang_tidy_command(${WARNINGS_AS_ERRORS} FALSE CLANG_TIDY_COMMAND)
  if(CLANG_TIDY_COMMAND_FOUND)
    set_target_properties(${target} PROPERTIES CXX_CLANG_TIDY "${CLANG_TIDY_COMMAND}")
  endif()
endmacro()

macro(enable_clang_tidy_global WARNINGS_AS_ERRORS)
  _configure_clang_tidy_command(${WARNINGS_AS_ERRORS} TRUE CMAKE_CXX_CLANG_TIDY)
endmacro()

# Helper function to configure include-what-you-use
function(_configure_include_what_you_use OUTPUT_VAR)
  find_program(INCLUDE_WHAT_YOU_USE include-what-you-use)

  if(INCLUDE_WHAT_YOU_USE)
    set(${OUTPUT_VAR}
        ${INCLUDE_WHAT_YOU_USE}
        PARENT_SCOPE)
    set(${OUTPUT_VAR}_FOUND
        TRUE
        PARENT_SCOPE)
  else()
    set(${OUTPUT_VAR}_FOUND
        FALSE
        PARENT_SCOPE)
    message(${WARNING_MESSAGE} "include-what-you-use requested but executable not found")
  endif()
endfunction()

macro(enable_include_what_you_use_target target)
  _configure_include_what_you_use(INCLUDE_WHAT_YOU_USE)
  if(INCLUDE_WHAT_YOU_USE_FOUND)
    set_target_properties(${target} PROPERTIES CXX_INCLUDE_WHAT_YOU_USE ${INCLUDE_WHAT_YOU_USE})
  endif()
endmacro()

macro(enable_include_what_you_use_global)
  _configure_include_what_you_use(CMAKE_CXX_INCLUDE_WHAT_YOU_USE)
endmacro()
