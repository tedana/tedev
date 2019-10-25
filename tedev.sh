#!/usr/bin/env bash

generate_tedana_dockerfile() {
    #
    # Generates Dockerfile to build Docker image for local tedana testing
    #

    clone_tedana='
        mkdir -p /tmp/src
        && git clone https://github.com/me-ica/tedana.git /tmp/src/tedana'
    get_three_echo_data='
        mkdir -p /tmp/data/three-echo
        && curl -L -o /tmp/data/three-echo/three_echo_Cornell_zcat.nii.gz https://osf.io/8fzse/download'
    get_five_echo_data='
        mkdir /tmp/data/five-echo
        && curl -L -o five_echo_NIH.tar.xz https://osf.io/ea5v3/download
        && tar xf five_echo_NIH.tar.xz -C /tmp/data/five-echo
        && rm -f five_echo_NIH.tar.xz'
    get_three_echo_reg='
        mkdir -p /tmp/test/three-echo
        && curl -L -o TED.Cornell_processed_three_echo_dataset.tar.xz https://osf.io/u65sq/download
        && tar xf TED.Cornell_processed_three_echo_dataset.tar.xz --no-same-owner -C /tmp/test/three-echo/
        && rm -f TED.Cornell_processed_three_echo_dataset.tar.xz'
    get_five_echo_reg='
        mkdir -p /tmp/test/five-echo
        && curl -L -o TED.p06.tar.xz https://osf.io/fr6mx/download
        && tar xf TED.p06.tar.xz --no-same-owner -C /tmp/test/five-echo/
        && rm -f TED.p06.tar.xz'

    docker run --rm kaczmarj/neurodocker:0.6.0 generate docker                 \
      --base debian:latest                                                     \
      --pkg-manager apt                                                        \
      --env LANG=C.UTF-8 LC_ALL=C.UTF-8                                        \
      --install curl git wget bzip2 ca-certificates                            \
      --run "${clone_tedana}"                                                  \
      --workdir /tmp/src/tedana                                                \
      --copy ./envs/venv.yml /tmp/src/venv.yml                                 \
      --copy ./envs/py35_env.yml /tmp/src/py35_env.yml                         \
      --copy ./envs/py37_env.yml /tmp/src/py37_env.yml                         \
      --miniconda create_env=venv                                              \
                  install_path=/opt/conda                                      \
                  yaml_file=/tmp/src/venv.yml                                  \
                  activate_env=true                                            \
      --miniconda create_env=py35_env                                          \
                  install_path=/opt/conda                                      \
                  yaml_file=/tmp/src/py35_env.yml                              \
                  activate_env=false                                           \
      --miniconda create_env=py37_env                                          \
                  install_path=/opt/conda                                      \
                  yaml_file=/tmp/src/py37_env.yml                              \
                  activate_env=false                                           \
      --run "${get_three_echo_data}"                                           \
      --run "${get_five_echo_data}"                                            \
      --run "${get_three_echo_reg}"                                            \
      --run "${get_five_echo_reg}"                                             \
      --add-to-entrypoint "source activate venv"                               \
      --copy "./tedev.sh" /tmp/src/tedev.sh                            \
      --add-to-entrypoint "source /tmp/src/tedev.sh"                       \
      > Dockerfile
}


build_tedana_image() {
    #
    # Recreates local Dockerfile and rebuilds tedev:latest Docker image
    #

    generate_tedana_dockerfile
    docker build --tag tedana/tedev:latest .
}


cprint() {
    #
    # Prints all supplied arguments as a green string
    #

    if [[ -t 0 ]]; then
        COLS=$( tput cols )
    else
        COLS=80
    fi

    msg=${*}
    eq=$( python -c "print('=' * ((${COLS} - len('${msg}') - 4) // 2))" )
    python -c "print('\033[1m\033[92m${eq}  ${msg}  ${eq}\033[0m')"
}


check_tedana_outputs() {
    #
    # Runs tedana unit tests for specified Python version / virtual environment
    #
    # Required argments:
    #   dataset         name of dataset to use for testing. should be one of
    #                   [three-echo, five-echo]
    #
    # confirm specification of three-echo or five-echo input
    # confirm specification of three-echo or five-echo input
    if [ -z "${1}" ] || { [ "${1}" != "three-echo" ] \
                          && [ "${1}" != "five-echo" ]; }; then
        printf 'Must supply dataset name for checking integration test ' >&2
        printf 'outputs; must be one of [three-echo, five-echo]\n' >&2
        return
    fi

    # find file
    find /tmp/data/"${1}"/TED."${1}"/* \
        -exec basename {} \; > /tmp/data/"${1}"/TED."${1}"/outputs.out

    # set filenames
    f1=/tmp/src/tedana/.circleci/tedana_outputs.txt
    f2=/tmp/data/"${1}"/TED."${1}"/outputs.out

    # sort both files, pipe into grep to check for tedana
    # logfile format; should only see one
    comm -13 <(sort -u $f1) <(sort -u $f2) | grep -E -e '^tedana_[12][0-9]{3}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}.txt$'
    numlogs=$(comm -13 <(sort -u $f1) <(sort -u $f2) | grep -E -e '^tedana_[12][0-9]{3}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}.txt$' | wc -l)
    if [[ ! $numlogs -eq 1 ]]; then
    printf "Incorrect number of logfiles: %s" $numlogs
    fi

    # verify non-log outputs match exactly
    f3=/tmp/data/"${1}"/TED."${1}"/outputs_nolog.txt
    find /tmp/data/"${1}"/TED."${1}"/* \
        -exec basename {} \; | grep -v outputs.out | sort > /tmp/data/"${1}"/TED."${1}"/outputs.out
    cat $f2 | grep -v -E -e '^tedana_[12][0-9]{3}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}.txt$' > $f3
    diff $f1 $f3
}


run_integration_tests() {
    for ds in three-echo five-echo; do
        cprint "RUNNING UNIT TESTS FOR ${ds} DATASET"
        source activate venv
        python setup.py -q install
        py.test tedana/tests/test_integration_${ds/-/_}.py
        check_tedana_outputs "${ds}"
    done
}


run_unit_tests() {
    for pyenv in venv py35_env py37_env; do
        cprint "RUNNING UNIT TESTS FOR PYTHON ENVIRONMENT: ${pyenv}"
        source activate ${pyenv}
        python setup.py -q install
        py.test --ignore-glob=tedana/tests/test_integration*.py tedana
    done

}


run_lint_tests() {
    cprint "LINTING TEDANA CODEBASE"
    source activate venv
    flake8 tedana
}


run_all_tests() {
    run_lint_tests
    run_unit_tests
    run_integration_tests
}
