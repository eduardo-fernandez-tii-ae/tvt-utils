# README #

This README indicates the necessary steps to run the tags diffs script.

### Command to build the Docker image ###

`docker build -t <image-name>:<image-tag> .`

### E. g.: ###

`docker build -t revisions-diffs:v1.0.0 .`

### Command to run the revisions diffs script ###

`docker run -t --rm --name <container-name> -v $PWD:/opt --network host -e PROJECT_ID=<project-id>
  -e GITLAB_URL=<gitlab-url> -e GITLAB_TOKEN=<gitlab-token> -w /opt <image-name>:<image-tag>
  python3 check-revisions-diffs.py -lht <first-tag> -rht <second-tag>`

The output will be found at ./revisions-diffs-report.html.

### E. g.: ###

`docker run -t --rm --name revisions-diffs -v $PWD:/opt --network host -e PROJECT_ID=40
  -e GITLAB_URL=http://gitlab.example.com -e GITLAB_TOKEN=<gitlab-personal-access-token> -w /opt
  python-gitlab:v1.0.0 python3 check-revisions-diffs.py -lht v5.1.0-develop -rht v5.0.0-develop`
