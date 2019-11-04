# Your version: 0.6.0 Latest version: 0.6.0
# Generated by Neurodocker version 0.6.0
# Timestamp: 2019-11-04 17:26:31 UTC
#
# Thank you for using Neurodocker. If you discover any issues
# or ways to improve this software, please submit an issue or
# pull request on our GitHub repository:
#
#     https://github.com/kaczmarj/neurodocker

FROM debian:latest

ARG DEBIAN_FRONTEND="noninteractive"

ENV LANG="en_US.UTF-8" \
    LC_ALL="en_US.UTF-8" \
    ND_ENTRYPOINT="/neurodocker/startup.sh"
RUN export ND_ENTRYPOINT="/neurodocker/startup.sh" \
    && apt-get update -qq \
    && apt-get install -y -q --no-install-recommends \
           apt-utils \
           bzip2 \
           ca-certificates \
           curl \
           locales \
           unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && dpkg-reconfigure --frontend=noninteractive locales \
    && update-locale LANG="en_US.UTF-8" \
    && chmod 777 /opt && chmod a+s /opt \
    && mkdir -p /neurodocker \
    && if [ ! -f "$ND_ENTRYPOINT" ]; then \
         echo '#!/usr/bin/env bash' >> "$ND_ENTRYPOINT" \
    &&   echo 'set -e' >> "$ND_ENTRYPOINT" \
    &&   echo 'export USER="${USER:=`whoami`}"' >> "$ND_ENTRYPOINT" \
    &&   echo 'if [ -n "$1" ]; then "$@"; else /usr/bin/env bash; fi' >> "$ND_ENTRYPOINT"; \
    fi \
    && chmod -R 777 /neurodocker && chmod a+s /neurodocker

ENTRYPOINT ["/neurodocker/startup.sh"]

ENV LANG="C.UTF-8" \
    LC_ALL="C.UTF-8"

RUN apt-get update -qq \
    && apt-get install -y -q --no-install-recommends \
           curl \
           git \
           wget \
           bzip2 \
           ca-certificates \
           sed \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN \
            mkdir -p /tmp/src \
            && git clone https://github.com/me-ica/tedana.git /tmp/src/tedana

WORKDIR /tmp/src/tedana

COPY ["./envs/venv.yml", "/tmp/src/venv.yml"]

COPY ["./envs/py35_env.yml", "/tmp/src/py35_env.yml"]

COPY ["./envs/py37_env.yml", "/tmp/src/py37_env.yml"]

ENV CONDA_DIR="/opt/conda" \
    PATH="/opt/conda/bin:$PATH"
RUN export PATH="/opt/conda/bin:$PATH" \
    && echo "Downloading Miniconda installer ..." \
    && conda_installer="/tmp/miniconda.sh" \
    && curl -fsSL --retry 5 -o "$conda_installer" https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh \
    && bash "$conda_installer" -b -p /opt/conda \
    && rm -f "$conda_installer" \
    && conda update -yq -nbase conda \
    && conda config --system --prepend channels conda-forge \
    && conda config --system --set auto_update_conda false \
    && conda config --system --set show_channel_urls true \
    && sync && conda clean --all && sync \
    && conda env create -q --name venv --file /tmp/src/venv.yml \
    && rm -rf ~/.cache/pip/*

RUN conda env create -q --name py35_env --file /tmp/src/py35_env.yml \
    && rm -rf ~/.cache/pip/*

RUN conda env create -q --name py37_env --file /tmp/src/py37_env.yml \
    && rm -rf ~/.cache/pip/*

RUN \
            mkdir -p /tmp/data/three-echo \
            && curl -L -o /tmp/data/three-echo/three_echo_Cornell_zcat.nii.gz https://osf.io/8fzse/download

RUN \
            mkdir /tmp/data/five-echo \
            && curl -L -o five_echo_NIH.tar.xz https://osf.io/ea5v3/download \
            && tar xf five_echo_NIH.tar.xz -C /tmp/data/five-echo \
            && rm -f five_echo_NIH.tar.xz

RUN \
            mkdir -p /tmp/test/three-echo \
            && curl -L -o TED.Cornell_processed_three_echo_dataset.tar.xz https://osf.io/u65sq/download \
            && tar xf TED.Cornell_processed_three_echo_dataset.tar.xz --no-same-owner -C /tmp/test/three-echo/ \
            && rm -f TED.Cornell_processed_three_echo_dataset.tar.xz

RUN \
            mkdir -p /tmp/test/five-echo \
            && curl -L -o TED.p06.tar.xz https://osf.io/fr6mx/download \
            && tar xf TED.p06.tar.xz --no-same-owner -C /tmp/test/five-echo/ \
            && rm -f TED.p06.tar.xz

RUN \
            /opt/conda/envs/venv/bin/ipython profile create \
            && sed -i 's/#c.InteractiveShellApp.extensions = \[\]/c.InteractiveShellApp.extensions = \['\''autoreload'\''\]/g' /root/.ipython/profile_default/ipython_config.py

RUN sed -i '$isource activate venv' $ND_ENTRYPOINT

COPY ["./tedev.sh", "/tmp/src/tedev.sh"]

RUN sed -i '$isource /tmp/src/tedev.sh' $ND_ENTRYPOINT

RUN echo '{ \
    \n  "pkg_manager": "apt", \
    \n  "instructions": [ \
    \n    [ \
    \n      "base", \
    \n      "debian:latest" \
    \n    ], \
    \n    [ \
    \n      "env", \
    \n      { \
    \n        "LANG": "C.UTF-8", \
    \n        "LC_ALL": "C.UTF-8" \
    \n      } \
    \n    ], \
    \n    [ \
    \n      "install", \
    \n      [ \
    \n        "curl", \
    \n        "git", \
    \n        "wget", \
    \n        "bzip2", \
    \n        "ca-certificates", \
    \n        "sed" \
    \n      ] \
    \n    ], \
    \n    [ \
    \n      "run", \
    \n      "\\n        mkdir -p /tmp/src\\n        && git clone https://github.com/me-ica/tedana.git /tmp/src/tedana" \
    \n    ], \
    \n    [ \
    \n      "workdir", \
    \n      "/tmp/src/tedana" \
    \n    ], \
    \n    [ \
    \n      "copy", \
    \n      [ \
    \n        "./envs/venv.yml", \
    \n        "/tmp/src/venv.yml" \
    \n      ] \
    \n    ], \
    \n    [ \
    \n      "copy", \
    \n      [ \
    \n        "./envs/py35_env.yml", \
    \n        "/tmp/src/py35_env.yml" \
    \n      ] \
    \n    ], \
    \n    [ \
    \n      "copy", \
    \n      [ \
    \n        "./envs/py37_env.yml", \
    \n        "/tmp/src/py37_env.yml" \
    \n      ] \
    \n    ], \
    \n    [ \
    \n      "miniconda", \
    \n      { \
    \n        "create_env": "venv", \
    \n        "install_path": "/opt/conda", \
    \n        "yaml_file": "/tmp/src/venv.yml", \
    \n        "activate_env": "true" \
    \n      } \
    \n    ], \
    \n    [ \
    \n      "miniconda", \
    \n      { \
    \n        "create_env": "py35_env", \
    \n        "install_path": "/opt/conda", \
    \n        "yaml_file": "/tmp/src/py35_env.yml", \
    \n        "activate_env": "false" \
    \n      } \
    \n    ], \
    \n    [ \
    \n      "miniconda", \
    \n      { \
    \n        "create_env": "py37_env", \
    \n        "install_path": "/opt/conda", \
    \n        "yaml_file": "/tmp/src/py37_env.yml", \
    \n        "activate_env": "false" \
    \n      } \
    \n    ], \
    \n    [ \
    \n      "run", \
    \n      "\\n        mkdir -p /tmp/data/three-echo\\n        && curl -L -o /tmp/data/three-echo/three_echo_Cornell_zcat.nii.gz https://osf.io/8fzse/download" \
    \n    ], \
    \n    [ \
    \n      "run", \
    \n      "\\n        mkdir /tmp/data/five-echo\\n        && curl -L -o five_echo_NIH.tar.xz https://osf.io/ea5v3/download\\n        && tar xf five_echo_NIH.tar.xz -C /tmp/data/five-echo\\n        && rm -f five_echo_NIH.tar.xz" \
    \n    ], \
    \n    [ \
    \n      "run", \
    \n      "\\n        mkdir -p /tmp/test/three-echo\\n        && curl -L -o TED.Cornell_processed_three_echo_dataset.tar.xz https://osf.io/u65sq/download\\n        && tar xf TED.Cornell_processed_three_echo_dataset.tar.xz --no-same-owner -C /tmp/test/three-echo/\\n        && rm -f TED.Cornell_processed_three_echo_dataset.tar.xz" \
    \n    ], \
    \n    [ \
    \n      "run", \
    \n      "\\n        mkdir -p /tmp/test/five-echo\\n        && curl -L -o TED.p06.tar.xz https://osf.io/fr6mx/download\\n        && tar xf TED.p06.tar.xz --no-same-owner -C /tmp/test/five-echo/\\n        && rm -f TED.p06.tar.xz" \
    \n    ], \
    \n    [ \
    \n      "run", \
    \n      "\\n        /opt/conda/envs/venv/bin/ipython profile create\\n        && sed -i '"'"'s/#c.InteractiveShellApp.extensions = \\[\\]/c.InteractiveShellApp.extensions = \\['"'"'\\'"'"''"'"'autoreload'"'"'\\'"'"''"'"'\\]/g'"'"' /root/.ipython/profile_default/ipython_config.py" \
    \n    ], \
    \n    [ \
    \n      "add_to_entrypoint", \
    \n      "source activate venv" \
    \n    ], \
    \n    [ \
    \n      "copy", \
    \n      [ \
    \n        "./tedev.sh", \
    \n        "/tmp/src/tedev.sh" \
    \n      ] \
    \n    ], \
    \n    [ \
    \n      "add_to_entrypoint", \
    \n      "source /tmp/src/tedev.sh" \
    \n    ] \
    \n  ] \
    \n}' > /neurodocker/neurodocker_specs.json
