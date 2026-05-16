# syntax=docker/dockerfile:1.7
ARG DOME_BASE_IMAGE=dome-docker-base:kilted
FROM ${DOME_BASE_IMAGE}

SHELL ["/bin/bash", "-c"]

ENV DEBIAN_FRONTEND=noninteractive
ARG ROS_DISTRO=kilted
ENV ROS_DISTRO=${ROS_DISTRO}
ARG DOME_USER=robot
ARG DOME_PASSWORD=""
ENV DOME_HOME=/home/${DOME_USER}

COPY manifest/ /manifest/

RUN useradd -m -s /bin/bash "${DOME_USER}" && \
    if [[ -n "${DOME_PASSWORD}" ]]; then echo "${DOME_USER}:${DOME_PASSWORD}" | chpasswd; fi && \
    usermod -aG sudo "${DOME_USER}" && \
    echo "${DOME_USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${DOME_USER} && \
    chmod 0440 /etc/sudoers.d/${DOME_USER} && \
    mkdir -p \
      "${DOME_HOME}/.local/bin" \
      "${DOME_HOME}/.ros/camera_info" \
      "${DOME_HOME}/.control/maps" \
      "${DOME_HOME}/.control/logs" \
      "${DOME_HOME}/ros2_ws/src" \
      "${DOME_HOME}/uros_ws/src" && \
    touch "${DOME_HOME}/.bash_history" && \
    chmod 600 "${DOME_HOME}/.bash_history" && \
    chown -R "${DOME_USER}:${DOME_USER}" "${DOME_HOME}"
WORKDIR ${DOME_HOME}

RUN mkdir -p -m 0700 /root/.ssh && ssh-keyscan github.com >> /root/.ssh/known_hosts

RUN --mount=type=ssh \
    clone_section() { \
      local section="$1"; \
      local base_dir="$2"; \
      mkdir -p "${base_dir}"; \
      while read -r repo dest branch; do \
        [[ -z "${repo}" ]] && continue; \
        if [[ -n "${branch}" ]]; then \
          git clone --branch "${branch}" "${repo}" "${base_dir}/${dest}"; \
        else \
          git clone "${repo}" "${base_dir}/${dest}"; \
        fi; \
      done < <(awk -v s="${section}" '$0=="["s"]"{f=1;next} /^\[/{f=0} f && /^[^#[:space:]]/ && NF' /manifest/repos.txt); \
    }; \
    clone_section root "${DOME_HOME}"; \
    clone_section ros_ws "${DOME_HOME}/ros2_ws/src"; \
    clone_section uros_ws "${DOME_HOME}/uros_ws/src"; \
    chown -R "${DOME_USER}:${DOME_USER}" "${DOME_HOME}"

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
    chown -R "${DOME_USER}:${DOME_USER}" "${DOME_HOME}"
USER ${DOME_USER}

RUN source /opt/ros/${ROS_DISTRO}/setup.bash && \
    cd "${DOME_HOME}/ros2_ws" && \
    colcon build --symlink-install --packages-skip depthai_rospi

RUN if [[ -f "${DOME_HOME}/rosutils/ros2_robot_bashrc.bash" ]]; then \
      cp "${DOME_HOME}/rosutils/ros2_robot_bashrc.bash" "${DOME_HOME}/.bashrc"; \
    else \
      echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> "${DOME_HOME}/.bashrc" && \
      echo "source ${DOME_HOME}/ros2_ws/install/setup.bash" >> "${DOME_HOME}/.bashrc" && \
      echo 'if command -v mcfly >/dev/null 2>&1; then eval "$(mcfly init bash)"; fi' >> "${DOME_HOME}/.bashrc"; \
    fi && \
    if [[ -f "${DOME_HOME}/rosutils/bru.py" ]]; then ln -s "${DOME_HOME}/rosutils/bru.py" "${DOME_HOME}/.local/bin/bru" && chmod +x "${DOME_HOME}/rosutils/bru.py"; fi

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
USER root
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
USER ${DOME_USER}
WORKDIR ${DOME_HOME}/ros2_ws

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["bash"]
