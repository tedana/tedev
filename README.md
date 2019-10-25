# `tedana`dev

This repository is primarily designed for building a Docker image that makes developing [`tedana`](https://github.com/me-ica/tedana) easier!

## Quick start

To get started developing `tedana`, you will need both [Docker](https://docs.docker.com/install/) and [Git](https://git-scm.com/downloads) installed on your system.
Once you have those, you can run the following command:

```bash
git clone https://github.com/me-ica/tedana.git
docker run --tty --rm -v ${PWD}/tedana:/tmp/src/tedana tedana/tedev:latest run_all_tests
```

The first command will clone `tedana` to your computer, and the second command will use the cloned repository to run the entire `tedana` test suite inside a Docker image :tada:
Running the tests will take quite a while, but you should get status updates about what's happening as it moves along.

If you already have a local version of `tedana` you can use that&mdash;no need to clone it again.
Simply replace `-v ${PWD}/tedana:/tmp/src/tedana` in the above `docker` command with `-v /PATH/TO/YOUR/LOCAL/TEDANA:/tmp/src/tedana` and you'll be good to go!

## Usage

You can modify the exact tests to run inside the Docker container by replacing `run_all_tests` in the above command.
Options include:

- `run_lint_tests`: Will run `flake8` on `tedana` to ensure that it is styled correctly (runtime: quick)
- `run_unit_tests`: Will run some basic unit tests for Python 3.5, 3.6, and 3.7 on `tedana` (runtime: medium)
- `run_integration_tests`: Will run two datasets (a three- and five-echo dataset) through the `tedana` pipeline (runtime: long)

By default, `run_all_tests` performs all three of these commands.

Alternatively, if you would like to debug `tedana` inside the Docker image, you can omit these tests commands from the `docker` call and instead run:

```bash
docker run --tty --rm -v ${PWD}/tedana:/tmp/src/tedana tedana/tedev:latest
```

which will drop you into a bash shell inside the Docker image!

From here, you can open a Python terminal with `python` and call `import tedana` to play around.
Editing the local copy of your code will automatically update the code inside the Docker container (though you may have to close + re-open Python to get things updated).
Once you're done fiddling, you can just call `run_all_tests` from inside the Docker container and it should get to work running the test suite!

## Development

If you need to update the Dockerfile in this repository you can modify `tedev.sh` and run:

```bash
bash -c "source ./tedev.sh && generate_tedana_dockerfile"
```

Pushing an updated Dockerfile to this repository will trigger DockerHub to re-generate the `tedana/tedev:latest` Docker image.

If you want to re-generate a local version of the Docker image (for testing purposes and whathaveyou) you can run:

```bash
bash -c "source ./tedev.sh && build_tedana_image"
```

N.B. For development purposes it is assumed you have access to a `bash` shell (i.e., you are using a POSIX-based operating system or are running the Linux subsystem of Windows).
