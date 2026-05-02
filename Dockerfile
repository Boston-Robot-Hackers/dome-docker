# syntax=docker/dockerfile:1.7
ARG DOME_BASE_IMAGE=dome-docker-base:kilted
FROM ${DOME_BASE_IMAGE}

SHELL ["/bin/bash", "-c"]

ENV DEBIAN_FRONTEND=noninteractive
ENV ROS_DISTRO=kilted
ARG DOME_CONTAINER_USER=robot
ARG DOME_ROOT_REPOS="https://github.com/Seeed-Studio/seeed-linux-dtoverlays.git seeed-linux-dtoverlays;https://github.com/raspberrypi/libcamera-apps.git libcamera-apps"
ARG DOME_ROS_REPOS="https://github.com/dfki-ric/better_launch.git better_launch;https://github.com/hippo5329/ldlidar_stl_ros2.git ldlidar_stl_ros2;https://github.com/micro-ROS/micro-ROS-Agent.git micro-ROS-Agent;https://github.com/micro-ROS/micro_ros_msgs.git micro_ros_msgs;https://github.com/christianrauch/camera_ros.git camera_ros"
ARG DOME_UROS_REPOS="https://github.com/micro-ROS/micro-ROS-Agent.git micro-ROS-Agent;https://github.com/micro-ROS/micro_ros_msgs.git micro_ros_msgs"
ENV DOME_HOME=/home/${DOME_CONTAINER_USER}

RUN useradd -m -s /bin/bash "${DOME_CONTAINER_USER}" && \
    mkdir -p \
      "${DOME_HOME}/.local/bin" \
      "${DOME_HOME}/.ros/camera_info" \
      "${DOME_HOME}/.control/maps" \
      "${DOME_HOME}/.control/logs" \
      "${DOME_HOME}/ros2_ws/src" \
      "${DOME_HOME}/uros_ws/src" && \
    chown -R "${DOME_CONTAINER_USER}:${DOME_CONTAINER_USER}" "${DOME_HOME}"
WORKDIR ${DOME_HOME}

RUN mkdir -p -m 0700 /root/.ssh && ssh-keyscan github.com >> /root/.ssh/known_hosts

RUN --mount=type=ssh \
    clone_repos() { \
      local base_dir="$1"; \
      local entries="$2"; \
      mkdir -p "${base_dir}"; \
      if [[ -n "${entries}" ]]; then \
        while IFS= read -r entry; do \
          [[ -z "${entry}" ]] && continue; \
          local repo="${entry%% *}"; \
          local dest="${entry#* }"; \
          git clone "${repo}" "${base_dir}/${dest}"; \
        done < <(tr ';' '\n' <<<"${entries}"); \
      fi; \
    }; \
    clone_repos "${DOME_HOME}" "${DOME_ROOT_REPOS}"; \
    clone_repos "${DOME_HOME}/ros2_ws/src" "${DOME_ROS_REPOS}"; \
    clone_repos "${DOME_HOME}/uros_ws/src" "${DOME_UROS_REPOS}"; \
    chown -R "${DOME_CONTAINER_USER}:${DOME_CONTAINER_USER}" "${DOME_HOME}"

USER root
RUN if [[ -f "${DOME_HOME}/ros2_ws/src/oak_roboflow/setup.py" ]]; then \
      python3 -c 'import os; from pathlib import Path; p=Path(os.environ["DOME_HOME"]) / "ros2_ws/src/oak_roboflow/setup.py"; s=p.read_text(); s=s.replace("from setuptools import setup", "from setuptools import setup, find_packages"); s=s.replace("setup(\n    data_files=", "setup(\n    packages=find_packages(include=[\"oak_roboflow\", \"oak_roboflow.*\"]),\n    data_files="); p.write_text(s)'; \
    fi

RUN find "${DOME_HOME}/ros2_ws/src" -type d \
      \( -name build -o -name install -o -name log -o -name prefix_override -o -name __pycache__ -o -name .pytest_cache \) \
      -prune -exec rm -rf {} + && \
    find "${DOME_HOME}/ros2_ws/src" -type d -name "*.egg-info" -prune -exec rm -rf {} + && \
    rosdep update && \
    cd "${DOME_HOME}/ros2_ws" && \
    rosdep install --from-paths src --ignore-src -r -y --skip-keys="ament_python gazebo_ros_pkgs" && \
    chown -R "${DOME_CONTAINER_USER}:${DOME_CONTAINER_USER}" "${DOME_HOME}"
USER ${DOME_CONTAINER_USER}

RUN source /opt/ros/kilted/setup.bash && \
    cd "${DOME_HOME}/ros2_ws" && \
    colcon build --symlink-install

RUN echo 'source /opt/ros/kilted/setup.bash' >> "${DOME_HOME}/.bashrc" && \
    echo "source ${DOME_HOME}/ros2_ws/install/setup.bash" >> "${DOME_HOME}/.bashrc" && \
    if [[ -f "${DOME_HOME}/rosutils/common_alias.bash" ]]; then echo "source ${DOME_HOME}/rosutils/common_alias.bash" >> "${DOME_HOME}/.bashrc"; fi && \
    if [[ -f "${DOME_HOME}/rosutils/bru.py" ]]; then ln -s "${DOME_HOME}/rosutils/bru.py" "${DOME_HOME}/.local/bin/bru" && chmod +x "${DOME_HOME}/rosutils/bru.py"; fi

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
USER root
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
USER ${DOME_CONTAINER_USER}
WORKDIR ${DOME_HOME}/ros2_ws

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["bash"]
