FROM ubuntu:22.04

LABEL maintainer="Eduardo Fernández <eduardo.fernandez@tii.ae>"

RUN apt update

RUN apt install -y --no-install-recommends \
      git python3 python3-pip

RUN pip3 install python-gitlab

COPY check-revisions-diffs.py /opt/check-revisions-diffs.py

CMD ["/bin/bash"]
