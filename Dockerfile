FROM debian:12

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-lc"]

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV ROS_DISTRO=jazzy
ARG BUILDER_UID=1000
ARG BUILDER_GID=1000
ARG ROS_APT_SOURCE_VERSION=1.1.0

# Packages available from Debian Bookworm base repos — installed before the
# ROS apt repository is configured.
RUN apt-get update && apt-get install -y --no-install-recommends \
    locales \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    sudo \
    bash-completion \
    git \
    wget \
    less \
    vim \
    build-essential \
    cmake \
    ninja-build \
    pkg-config \
    fakeroot \
    debhelper \
    devscripts \
    dpkg-dev \
    equivs \
    quilt \
    dh-python \
    dctrl-tools \
    python3 \
    python3-dev \
    python3-pip \
    python3-venv \
    python3-setuptools \
    python3-wheel \
    python3-empy \
    python3-lark \
    python3-pytest \
    python3-pytest-cov \
    python3-pytest-mock \
    python3-pytest-rerunfailures \
    python3-pytest-runner \
    python3-pytest-timeout \
    python3-flake8 \
    python3-mypy \
    python3-rosdep \
    libasio-dev \
    libtinyxml2-dev \
    libcunit1-dev \
    libssl-dev \
    libyaml-dev \
    libyaml-cpp-dev \
    libspdlog-dev \
    libfmt-dev \
    libcurl4-openssl-dev \
    rsync \
    unzip \
    zip \
    && rm -rf /var/lib/apt/lists/*

RUN sed -i 's/^# *en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen && \
    update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

# Install ROS apt source bootstrap package for Debian 12 (bookworm).
# This provides apt repository configuration for ROS 2 binaries and sources.
RUN apt-get update && \
    curl -L -o /tmp/ros2-apt-source.deb \
      "https://github.com/ros-infrastructure/ros-apt-source/releases/download/${ROS_APT_SOURCE_VERSION}/ros2-apt-source_${ROS_APT_SOURCE_VERSION}.bookworm_all.deb" && \
    dpkg -i /tmp/ros2-apt-source.deb && \
    rm -f /tmp/ros2-apt-source.deb && \
    apt-get update && \
    # The following packages are only available from the ROS apt repo.
    apt-get install -y --no-install-recommends \
      python3-vcstool \
      python3-colcon-common-extensions \
      python3-bloom \
      python3-pytest-repeat \
      libfoonathan-memory-dev

# Ensure deb-src is enabled for the ROS 2 repository.
# ros2-apt-source writes a DEB822 .sources file; handle that format as well as
# the legacy .list format so apt-get source works in both cases.
RUN \
    # DEB822 .sources format: append deb-src to the Types: field if absent.
    for f in /etc/apt/sources.list.d/*.sources; do \
      [ -f "$f" ] || continue; \
      grep -qiE 'packages\.ros\.org|ros2' "$f" || continue; \
      if grep -q '^Types:' "$f" && ! grep -q 'deb-src' "$f"; then \
        sed -i 's/^\(Types:[[:space:]]*\)\(.*\)/\1\2 deb-src/' "$f"; \
      fi; \
    done; \
    # Legacy .list format: append a deb-src line if absent.
    for f in /etc/apt/sources.list.d/*.list /etc/apt/sources.list; do \
      [ -f "$f" ] || continue; \
      grep -qE '^deb[[:space:]].*packages\.ros\.org' "$f" || continue; \
      if ! grep -qE '^deb-src[[:space:]].*packages\.ros\.org' "$f"; then \
        grep -E '^deb[[:space:]].*packages\.ros\.org' "$f" \
          | sed 's/^deb /deb-src /' >> "$f"; \
      fi; \
    done && \
    apt-get update

# Add local rosdep overrides for Debian Bookworm gaps.
COPY overrides/rosdep-bookworm-overrides.yaml /etc/ros/rosdep/bookworm-overrides.yaml

# Initialize rosdep and create the non-root builder user.
RUN rosdep init && \
    printf 'yaml file:///etc/ros/rosdep/bookworm-overrides.yaml\n' > /etc/ros/rosdep/sources.list.d/00-local.list && \
    groupadd --gid "${BUILDER_GID}" builder && \
    useradd --uid "${BUILDER_UID}" --gid "${BUILDER_GID}" --create-home --shell /bin/bash builder && \
    echo "builder ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/builder && \
    chmod 0440 /etc/sudoers.d/builder && \
    mkdir -p /workspace/src /workspace/out /workspace/tmp && \
    chown -R builder:builder /workspace /home/builder

COPY scripts/ /usr/local/bin/
RUN chmod +x /usr/local/bin/*.sh

ENV HOME=/home/builder
USER builder
WORKDIR /workspace

CMD ["/bin/bash"]
