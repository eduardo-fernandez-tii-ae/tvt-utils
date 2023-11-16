#!/bin/bash

is_found()
{
  local TO_SEARCH=$1
  shift
  local ARRAY=("$@")

  local FOUND=1

  for item in "${ARRAY[@]}"
  do
    if [[ $TO_SEARCH == $item ]]
    then
      FOUND=0
      break
    fi
  done

  return $FOUND
}

check_undocumented_parameters()
{
  local FUNCTION_NAME=$1
  local LINE_NUMBER=$2

  for param in "${LIST_OF_PARAMETERS[@]}"
  do
    is_found $param "${LIST_OF_DOC_PARAMS[@]}"

    if [[ $? -ne 0 ]]
    then
      ERROR="<tr><td>$file</td><td>$LINE_NUMBER</td><td>$FUNCTION_NAME</td><td>Param <b>$param</b> is not documented.</td></tr>"

      ERRORS+=($ERROR)
    fi
  done
}

check_unused_parameters()
{
  local FUNCTION_NAME=$1
  local LINE_NUMBER=$2

  for doc_param in "${LIST_OF_DOC_PARAMS[@]}"
  do
    is_found $doc_param "${LIST_OF_PARAMETERS[@]}"

    if [[ $? -ne 0 ]]
    then
      ERROR="<tr><td>$file</td><td>$LINE_NUMBER</td><td>$FUNCTION_NAME</td><td>Documented parameter <b>$doc_param</b> is never used.</td></tr>"

      ERRORS+=($ERROR)
    fi
  done
}

set_parameters_list()
{
  local DECLARATION="$1"
  local NUMBER_OF_PARAMETERS=$(( $(echo "$DECLARATION" | grep -o ',' | wc -l) + 1))

  for ((i = 1; i <= $NUMBER_OF_PARAMETERS; i++))
  do
    PARAMETER_NAME=$(echo "$DECLARATION" | cut -d ',' -f $i | awk '{print $NF}' | cut -d '[' -f 1 | sed 's/*//g; s/);//g')

    LIST_OF_PARAMETERS+=($PARAMETER_NAME)
  done
}

set_doc_params_list()
{
  local DECLARATION="$1"
  local FILE="$2"

  local HAS_DOC=$(function_has_doc $DECLARATION $FILE)

  if [[ $HAS_DOC -eq 1 ]]
  then
    DECLARATION=$(echo "$DECLARATION" | sed 's/\*/\\*/g')
    local DOC_LINES=($(tac $FILE | sed -n "/$DECLARATION/,/\/\*\*/p" | grep '@param'))

    for doc_line in "${DOC_LINES[@]}"
    do
      local DOC_PARAM=$(echo "$doc_line" | grep '@param' | cut -d ':' -f 1 | awk '{print $NF}')
      LIST_OF_DOC_PARAMS+=($DOC_PARAM)
    done
  fi
}

process_declaration()
{
  local DECLARATION="$1"

  local result=$DECLARATION

  if [[ ! $DECLARATION == *");"* ]]
  then
    while [[ ! $DECLARATION == *");"* ]]
    do
      DECLARATION=$(echo "$DECLARATION" | sed 's/\*/\\*/g; s/\[/\\[/g; s/\]/\\]/g')

      local last_line=$(grep "$DECLARATION" -A 1 $file | tail -1 | sed 's/\\//g')

      DECLARATION=$last_line
      result+=$last_line
    done
  fi

  echo $result
}

function_has_doc()
{
  local DECLARATION_FIRST_LINE="$1"
  local FILE="$2"

  DECLARATION_FIRST_LINE=$(echo "$DECLARATION_FIRST_LINE" | sed 's/\*/\\*/g')

  local LAST_DOC_LINE=$(grep "$DECLARATION_FIRST_LINE" -B 1 $FILE | head -1)
  local HAS_DOC=$(echo "$LAST_DOC_LINE" | grep "^ \*/" | wc -l)
  
  echo $HAS_DOC
}

create_html_report()
{
  local ERRORS=("$@")

  HTML_REPORT="<!doctype html><html><head><title>Functions parameters documentation report</title>"
  HTML_REPORT+="<style>table {border: 1px solid #cccccc;} td {padding: 10px; text-align: center; vertical-align: middle;}</style>"
  HTML_REPORT+="</head><body><table align='center'><tr><td><b>File name</b></td><td><b>Line number</b></td><td><b>Function name</b></td><td><b>Description</b></td></tr>"
  
  for error in "${ERRORS[@]}"
  do
    HTML_REPORT+=$error
  done
  
  HTML_REPORT+="</table></body></html>"
  
  echo $HTML_REPORT > params-consistency-check-report.html
}


HEADERS_DIRECTORY=$1
HEADER_FILES=$(find $HEADERS_DIRECTORY -name "*.h")

ERRORS=()

for file in $HEADER_FILES
do
  IFS_BAK=${IFS}
  IFS=$'\n'

  DECLARATIONS=($(grep '^[a-zA-Z0-9]' "$file"))

  for declaration in ${DECLARATIONS[@]}
  do
    NOT_FUNCTION_DECLARATION=$(echo "$declaration" | grep " typedef \| struct \| union " | wc -l)

    if [[ $NOT_FUNCTION_DECLARATION -ne 0 ]]
    then
      continue
    fi

    declaration_first_line=$declaration
    declaration=$(process_declaration "$declaration")

    FUNCTION_NAME=$(echo "$declaration_first_line" | cut -d '(' -f 1 | awk '{print $NF}')
    LINE_NUMBER=$(grep -n $(echo "$declaration_first_line" | sed 's/\*/\\*/g') $file | cut -d ':' -f 1)

    LIST_OF_PARAMETERS=()
    LIST_OF_DOC_PARAMS=()

    set_parameters_list $declaration
    set_doc_params_list $declaration_first_line $file

    check_undocumented_parameters $FUNCTION_NAME $LINE_NUMBER
    check_unused_parameters $FUNCTION_NAME $LINE_NUMBER
  done

  IFS=${IFS_BAK}
done

create_html_report "${ERRORS[@]}"
