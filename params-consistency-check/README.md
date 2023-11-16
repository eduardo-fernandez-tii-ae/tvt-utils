# README #

This README indicates the necessary steps to run the params consistency check script.

### Command to run the params consistency check script ###

`docker run -t --rm --name <container-name> -v $PWD:/opt -w /opt ubuntu:22.04
  ./check-params-consistency.sh <path-to-include-directory>`

The output will be found at ./params-consistency-check-report.html.

### E. g.: ###

`docker run -t --rm --name params-consistency-check -v $PWD:/opt -w /opt ubuntu:22.04
  ./check-params-consistency.sh include`
