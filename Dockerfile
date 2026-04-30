# syntax=docker/dockerfile:1.7
FROM ros:kilted-ros-base-noble

SHELL ["/bin/bash", "-c"]

ENV DEBIAN_FRONTEND=noninteractive
ENV ROS_DISTRO=kilted

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    cmake \
    curl \
    git \
    iproute2 \
    iptables \
    iputils-ping \
    jq \
    make \
    meson \
    micro \
    nano \
    netcat-openbsd \
    ninja-build \
    openssh-client \
    python3-colcon-common-extensions \
    python3-opencv \
    python3-pip \
    python3-rosdep \
    python3-venv \
    python3-yaml \
    ripgrep \
    software-properties-common \
    tar \
    wget \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y --no-install-recommends \
    ros-kilted-camera-info-manager \
    ros-kilted-camera-ros \
    ros-kilted-compressed-image-transport \
    ros-kilted-depthai \
    ros-kilted-depthai-bridge \
    ros-kilted-depthai-examples \
    ros-kilted-depthai-ros \
    ros-kilted-depthai-ros-driver \
    ros-kilted-depthimage-to-laserscan \
    ros-kilted-diagnostic-updater \
    ros-kilted-diagnostics \
    ros-kilted-foxglove-bridge \
    ros-kilted-image-tools \
    ros-kilted-imu-filter-madgwick \
    ros-kilted-imu-tools \
    ros-kilted-joint-state-publisher \
    ros-kilted-joy-linux \
    ros-kilted-joy-teleop \
    ros-kilted-laser-filters \
    ros-kilted-libcamera \
    ros-kilted-nav2-bringup \
    ros-kilted-nav2-rviz-plugins \
    ros-kilted-navigation2 \
    ros-kilted-robot-calibration \
    ros-kilted-robot-localization \
    ros-kilted-robot-state-publisher \
    ros-kilted-rqt-graph \
    ros-kilted-rqt-image-view \
    ros-kilted-rviz-imu-plugin \
    ros-kilted-rviz2 \
    ros-kilted-slam-toolbox \
    ros-kilted-teleop-twist-joy \
    ros-kilted-teleop-twist-keyboard \
    ros-kilted-tf-transformations \
    ros-kilted-tf2 \
    ros-kilted-tf2-ros \
    ros-kilted-xacro \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash pitosalas
USER pitosalas
WORKDIR /home/pitosalas

RUN mkdir -p /home/pitosalas/.local/bin
RUN mkdir -p -m 0700 ~/.ssh && ssh-keyscan github.com >> ~/.ssh/known_hosts

RUN --mount=type=ssh \
    git clone git@github.com:campusrover/rosutils.git /home/pitosalas/rosutils && \
    mkdir -p /home/pitosalas/ros2_ws/src && \
    cd /home/pitosalas/ros2_ws/src && \
    git clone git@github.com:campusrover/dome.git && \
    git clone git@github.com:pitosalas/linorobot2.git && \
    git clone git@github.com:pitosalas/control.git && \
    git clone git@github.com:Boston-Robot-Hackers/ros2diag.git && \
    git clone git@github.com:Boston-Robot-Hackers/explore.git && \
    git clone git@github.com:Boston-Robot-Hackers/oak-roboflow.git oak_roboflow && \
    git clone git@github.com:pitosalas/status_panel.git && \
    git clone https://github.com/dfki-ric/better_launch.git && \
    git clone https://github.com/hippo5329/ldlidar_stl_ros2.git && \
    git clone https://github.com/micro-ROS/micro-ROS-Agent.git && \
    git clone https://github.com/micro-ROS/micro_ros_msgs.git && \
    git clone https://github.com/christianrauch/camera_ros.git && \
    git clone https://github.com/slgrobotics/depthai_rospi.git

USER root
RUN rosdep init || true
USER pitosalas

RUN source /opt/ros/kilted/setup.bash && \
    rosdep update && \
    cd /home/pitosalas/ros2_ws && \
    rosdep install --from-paths src --ignore-src -r -y && \
    colcon build --symlink-install

RUN echo 'source /opt/ros/kilted/setup.bash' >> /home/pitosalas/.bashrc && \
    echo 'source /home/pitosalas/ros2_ws/install/setup.bash' >> /home/pitosalas/.bashrc && \
    echo 'source /home/pitosalas/rosutils/common_alias.bash' >> /home/pitosalas/.bashrc && \
    ln -s /home/pitosalas/rosutils/bru.py /home/pitosalas/.local/bin/bru && \
    chmod +x /home/pitosalas/rosutils/bru.py

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
USER root
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
USER pitosalas
WORKDIR /home/pitosalas/ros2_ws

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["bash"]
