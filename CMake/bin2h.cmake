include(CMakeParseArguments)

# Function to wrap a given string into multiple lines at the given column position.
# Parameters:
#   VARIABLE    - The name of the CMake variable holding the string.
#   AT_COLUMN   - The column position at which string will be wrapped.
function(WRAP_STRING)
    set(oneValueArgs VARIABLE AT_COLUMN)
    cmake_parse_arguments(WRAP_STRING "${options}" "${oneValueArgs}" "" ${ARGN})

    string(LENGTH ${${WRAP_STRING_VARIABLE}} stringLength)
    math(EXPR offset "0")

    while(stringLength GREATER 0)

        if(stringLength GREATER ${WRAP_STRING_AT_COLUMN})
            math(EXPR length "${WRAP_STRING_AT_COLUMN}")
        else()
            math(EXPR length "${stringLength}")
        endif()

        string(SUBSTRING ${${WRAP_STRING_VARIABLE}} ${offset} ${length} line)
        set(lines "${lines}\n${line}")

        math(EXPR stringLength "${stringLength} - ${length}")
        math(EXPR offset "${offset} + ${length}")
    endwhile()

    set(${WRAP_STRING_VARIABLE} "${lines}" PARENT_SCOPE)
endfunction()

# Function to embed contents of a file as byte array in C/C++ header file(.h). The header file
# will contain a byte array and integer variable holding the size of the array.
# Parameters
#   SOURCE_FILE     - The path of source file whose contents will be embedded in the header file.
#   VARIABLE_NAME   - The name of the variable for the byte array. The string "_SIZE" will be append
#                     to this name and will be used a variable name for size variable.
#   HEADER_FILE     - The path of header file.
#   APPEND          - If specified appends to the header file instead of overwriting it
#   NULL_TERMINATE  - If specified a null byte(zero) will be append to the byte array. This will be
#                     useful if the source file is a text file and we want to use the file contents
#                     as string. But the size variable holds size of the byte array without this
#                     null byte.
# Usage:
#   bin2h(SOURCE_FILE "Logo.png" HEADER_FILE "Logo.h" VARIABLE_NAME "LOGO_PNG")
function(BIN2H)
    set(options APPEND NULL_TERMINATE)
    set(oneValueArgs SOURCE_FILE VARIABLE_NAME HEADER_FILE)
    cmake_parse_arguments(BIN2H "${options}" "${oneValueArgs}" "" ${ARGN})
    set(VARIABLE_NAME ${BIN2H_VARIABLE_NAME})

    # reads source file contents as hex string
    file(READ ${BIN2H_SOURCE_FILE} hexString HEX)
    string(LENGTH ${hexString} hexStringLength)

    # appends null byte if asked
    if(BIN2H_NULL_TERMINATE)
        set(hexString "${hexString}00")
    endif()

    # wraps the hex string into multiplwe lines at column 32(i.e. 16 bytes per line)
    wrap_string(VARIABLE hexString AT_COLUMN 32)
    math(EXPR arraySize "${hexStringLength} / 2")

    # adds '0x' prefix and comma suffix before and after every byte respectively
    string(REGEX REPLACE "([0-9a-f][0-9a-f])" "0x\\1, " arrayValues ${hexString})
    # removes trailing comma
    string(REGEX REPLACE ", $" "" arrayValues ${arrayValues})

    # converts the variable name into proper C identifier
    string(MAKE_C_IDENTIFIER "${BIN2H_VARIABLE_NAME}" BIN2H_VARIABLE_NAME)
    string(TOUPPER "${BIN2H_VARIABLE_NAME}" BIN2H_VARIABLE_NAME)

    set(header_define_start "#ifndef __${BIN2H_VARIABLE_NAME}_H__\n#define __${BIN2H_VARIABLE_NAME}_H__\n")
    set(header_define_end "#endif \//__${BIN2H_VARIABLE_NAME}_H__\n")
    set(arrayDefinition "const unsigned char ${BIN2H_VARIABLE_NAME}[] = { ${arrayValues} };")
    set(arraySizeDefinition "const size_t ${BIN2H_VARIABLE_NAME}_SIZE = ${arraySize};")
    set(declarations "${header_define_start}${arrayDefinition}\n\n${arraySizeDefinition}\n\n${header_define_end}")
    
    if(BIN2H_APPEND)
        file(APPEND ${BIN2H_HEADER_FILE} "${declarations}")
    else()
        file(WRITE ${BIN2H_HEADER_FILE} "${declarations}")
    endif()
    list(APPEND CONVERTED_ASSETS "{\"${VARIABLE_NAME}\", ustring(${BIN2H_VARIABLE_NAME}, ${arraySize})}")
    message(${CONVERTED_ASSETS})
    set(NEWASSET ${CONVERTED_ASSETS} PARENT_SCOPE)
    #if(BIN2H_APPEND)
    #    file(APPEND ${CMAKE_CURRENT_BINARY_DIR}/Assets/${BIN2H_HEADER_FILE} "${declarations}")
    #else()
    #    file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/Assets/${BIN2H_HEADER_FILE} "${declarations}")
    #endif()
endfunction()

# Function to create a smart content list that contains references to all binary converted data.
# This will make it possible to pick all converted assets from a list during runtime
# Parameters
#   NAME_LIST       - The list of 'unconverted' filenames, this will be mapped back to the internal
#                     variable name + extention type for smart retrieval.
#   HEADER_FILE     - The path of header file, the actual "Assets.h" that is to be included in the
#                   - project
#   APPEND          - If specified appends to the header file instead of overwriting it
#   NULL_TERMINATE  - If specified a null byte(zero) will be append to the byte array. This will be
#                     useful if the source file is a text file and we want to use the file contents
#                     as string. But the size variable holds size of the byte array without this
#                     null byte.
# Usage examples:
#   binsmartlist(NAME_LIST "${ASSET_LIST}" HEADER_FILE "Assets.h")
#
#   binsmartlist(NAME_LIST "${ASSET_LIST}" HEADER_FILE "Assets.h" APPEND NULL_TERMINATE)
function(BINSMARTLIST)
    set(options APPEND NULL_TERMINATE)
    set(oneValueArgs NAME_LIST HEADER_FILE)
    cmake_parse_arguments(BINSMARTLIST "${options}" "${oneValueArgs}" "" ${ARGN})

    # converts the variable name into proper C identifier
    string(MAKE_C_IDENTIFIER "${BIN2H_VARIABLE_NAME}" BIN2H_VARIABLE_NAME)
    string(TOUPPER "${BIN2H_VARIABLE_NAME}" BIN2H_VARIABLE_NAME)

    set(header_define_start "#ifndef __${BIN2H_VARIABLE_NAME}_H__\n#define __${BIN2H_VARIABLE_NAME}_H__\n")
    set(header_define_end "#endif \//__${BIN2H_VARIABLE_NAME}_H__\n")
    set(arrayDefinition "const unsigned char ${BIN2H_VARIABLE_NAME}[] = { ${arrayValues} };")
    set(arraySizeDefinition "const size_t ${BIN2H_VARIABLE_NAME}_SIZE = ${arraySize};")
    set(declarations "${header_define_start}${arrayDefinition}\n\n${arraySizeDefinition}\n\n${header_define_end}")
    
    if(BIN2H_APPEND)
        file(APPEND ${BIN2H_HEADER_FILE} "${declarations}")
    else()
        file(WRITE ${BIN2H_HEADER_FILE} "${declarations}")
    endif()
endfunction()