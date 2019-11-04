# `tedana`dev

This repository is primarily designed for building a Docker image that makes developing [`tedana`](https://github.com/me-ica/tedana) easier!

## Quick start

To get started developing `tedana`, you will need both [Docker](https://docs.docker.com/install/) and [Git](https://git-scm.com/downloads) installed on your system.
You should make a fork of the main [`tedana`](https://github.com/me-ica/tedana) repository by navigating to the GitHub repository and clicking "Fork" in the top right-hand corner.
Once you have done that, you can run the following commands:

```bash
git clone https://github.com/YOURUSENAME/tedana.git
docker run --tty --rm -v ${PWD}/tedana:/tmp/src/tedana tedana/tedev:latest run_all_tests
```

where `YOURUSERNAME` is your GitHub username.

The first command will clone the `tedana` repository to your computer, and the second command will use the cloned repository to run the entire `tedana` test suite inside a Docker image :tada:

If you already have a local version of `tedana` you can use that&mdash;no need to clone it again.
Simply replace `-v ${PWD}/tedana:/tmp/src/tedana` in the above `docker` command with `-v /PATH/TO/YOUR/LOCAL/TEDANA:/tmp/src/tedana` and you'll be good to go!
Note that the path before the `:` should be to the *`tedana` git repository*, not just the `tedana` code directory inside the git repository.

**N.B.** It is possible that, depending on your Docker setup, you may need to increase the amount of memory available to Docker in order to run the `tedana` test suite.
You can either do this permanently by editing your Docker settings or temporarily by adding `--memory=4g` to the above `docker run` command.

## Usage

The `docker run` command above may take quite a while, but you should get status updates about what's happening as it moves along.
The tests will issue some warnings (this is normal), but if you see a big green banner with `FINISHED RUNNING ALL TESTS! GREAT SUCCESS` then it means everything worked!

### Test options

You can modify the exact tests to run inside the Docker container by replacing `run_all_tests` in the above command.
Options include:

- `run_lint_tests`: Will run `flake8` on `tedana` to ensure that it is styled correctly (runtime: quick)
- `run_unit_tests`: Will run some basic unit tests for Python 3.5, 3.6, and 3.7 on `tedana` (runtime: medium)
- `run_integration_tests`: Will run two datasets (a three- and five-echo dataset) through the `tedana` pipeline (runtime: long)

You can string them together (e.g., `run_lint_tests run_unit_tests`) to run multiple in the same session.

Note that running the five-echo integration tests is **very** time-consuming; as such, this is not run by default when you call `run_all_tests`.
If you would like to run this integration test in addition to the other tests, replace `run_all_tests` with `run_all_tests five-echo`.

### Interactive debugging

If you would like to debug `tedana` inside the Docker image, you can omit these tests commands from the `docker` call and instead run:

```bash
docker run --tty --rm -it -v ${PWD}/tedana:/tmp/src/tedana tedana/tedev:latest
```

which will drop you into a bash shell inside the Docker image!

From here, you can open a Python terminal with `ipython` and call `import tedana` to play around.
Editing the local copy of your code will automatically update the code inside the Docker container (though you may have to close + re-open Python to update things; or, try [`%autoreload`](https://ipython.readthedocs.io/en/stable/config/extensions/autoreload.html#magic-autoreload)).
Once you're done fiddling, you can just call `run_all_tests` from inside the Docker container and it should get to work running the test suite!

## Development

If you need to update the Dockerfile in this repository you can modify `tedev.sh` and run:

```bash
bash -c "source ./tedev.sh && generate_tedana_dockerfile"
```

Pushing an updated Dockerfile to this repository will trigger DockerHub to re-generate the `tedana/tedev:latest` Docker image.

If you want to re-generate a local version of the Docker image (for testing purposes and whathaveyou) you can run:

```bash
bash -c "source ./tedev.sh && build_tedana_image dev"
```

Note that the `dev` will ensure that the newly created Docker image is NOT tagged `latest`, so you can have both copies locally.

N.B. For development purposes it is assumed you have access to a `bash` shell (i.e., you are using a POSIX-based operating system or are running the Linux subsystem of Windows).
