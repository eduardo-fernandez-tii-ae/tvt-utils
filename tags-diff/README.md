# README #

This README indicates the necessary steps to run the tags diffs script.

### Command to build the Docker image ###

`docker build -t <image-name>:<image-tag> .`

### E. g.: ###

`docker build -t python-gitlab:v1.0.0 .`

### Command to run the tags diffs script ###

`docker run -t --name <container-name> -v $PWD:/home --network host -e PROJECT_ID=<project-id>
  -e GITLAB_URL=<gitlab-url> -e GITLAB_TOKEN=<gitlab-token> -w /home <image-name>:<image-tag>
  python3 check-release-diff.py -lht <first-tag> -rht <second-tag>`

The output will be found at ./tags-diffs.html.

### E. g.: ###

`docker run -t --name python-gitlab -v $PWD:/home --network host -e PROJECT_ID=40
  -e GITLAB_URL=http://gitlab.example.com -e GITLAB_TOKEN=<gitlab-personal-access-token> -w /home
  python-gitlab:v1.0.0 python3 check-release-diff.py -lht v5.1.0-develop -rht v5.0.0-develop`