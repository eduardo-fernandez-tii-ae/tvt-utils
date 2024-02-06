FROM binsec/binsec


USER root

# Install common packages.
RUN apt-get update                                   && \
    apt-get install -y --no-install-recommends          \
        bzip2 libc6-dbg gcc g++ wget xz-utils python    \
        git make wget build-essential libssl-dev graphviz   \
        libffi-dev python3-pip cmake flex bison clang clang-format    && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install valgrind.
COPY valgrind /tmp/valgrind
RUN chmod u+x /tmp/valgrind/install.sh && \
    /tmp/valgrind/install.sh           && \
    rm -r /tmp/valgrind

# Install ctgrind.
COPY ctgrind /tmp/ctgrind
RUN chmod u+x /tmp/ctgrind/install.sh && \
    /tmp/ctgrind/install.sh           && \
    rm -r /tmp/ctgrind

# Install dudect.
COPY dudect /tmp/dudect
RUN chmod u+x /tmp/dudect/install.sh && \
    /tmp/dudect/install.sh           && \
    rm -r /tmp/dudect

## Install flowtracker.
#COPY flowtracker /tmp/flowtracker
#RUN chmod u+x /tmp/flowtracker/install.sh && \
#    /tmp/flowtracker/install.sh           && \
#    rm -r /tmp/flowtracker

# Add valgrind executable file to PATH.
ENV PATH="/usr/share/valgrind/bin:$PATH"

# Exiting root privilege
USER binsec
