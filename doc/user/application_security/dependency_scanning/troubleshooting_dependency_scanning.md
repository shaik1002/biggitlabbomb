---
stage: Secure
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Troubleshooting Dependency Scanning

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

When working with dependency scanning, you might encounter the following issues.

## Debug-level logging

Debug-level logging can help when troubleshooting. For details, see
[debug-level logging](../../application_security/troubleshooting_application_security.md#debug-level-logging).

### Working around missing support for certain languages or package managers

As noted in the ["Supported languages" section](index.md#supported-languages-and-package-managers)
some dependency definition files are not yet supported.
However, Dependency Scanning can be achieved if
the language, a package manager, or a third-party tool
can convert the definition file
into a supported format.

Generally, the approach is the following:

1. Define a dedicated converter job in your `.gitlab-ci.yml` file.
   Use a suitable Docker image, script, or both to facilitate the conversion.
1. Let that job upload the converted, supported file as an artifact.
1. Add [`dependencies: [<your-converter-job>]`](../../../ci/yaml/index.md#dependencies)
   to your `dependency_scanning` job to make use of the converted definitions files.

For example, Poetry projects that _only_ have a `pyproject.toml`
file can generate the `poetry.lock` file as follows.

```yaml
include:
  - template: Jobs/Dependency-Scanning.gitlab-ci.yml

stages:
  - test

gemnasium-python-dependency_scanning:
  # Work around https://gitlab.com/gitlab-org/gitlab/-/issues/32774
  before_script:
    - pip install "poetry>=1,<2"  # Or via another method: https://python-poetry.org/docs/#installation
    - poetry update --lock # Generates the lock file to be analyzed.
```

### `Error response from daemon: error processing tar file: docker-tar: relocation error`

This error occurs when the Docker version that runs the dependency scanning job is `19.03.0`.
Consider updating to Docker `19.03.1` or greater. Older versions are not
affected. Read more in
[this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/13830#note_211354992 "Current SAST container fails").

### Getting warning message `gl-dependency-scanning-report.json: no matching files`

For information on this, see the [general Application Security troubleshooting section](../../../ci/jobs/job_artifacts_troubleshooting.md#error-message-no-files-to-upload).

## `Error response from daemon: error processing tar file: docker-tar: relocation error`

This error occurs when the Docker version that runs the dependency scanning job is `19.03.0`.
Consider updating to Docker `19.03.1` or greater. Older versions are not
affected. Read more in
[this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/13830#note_211354992 "Current SAST container fails").

## Dependency scanning jobs are running unexpectedly

The [dependency scanning CI template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Dependency-Scanning.gitlab-ci.yml)
uses the [`rules:exists`](../../../ci/yaml/index.md#rulesexists)
syntax. This directive is limited to 10000 checks and always returns `true` after reaching this
number. Because of this, and depending on the number of files in your repository, a dependency
scanning job might be triggered even if the scanner doesn't support your project. For more details about this limitation, see [the `rules:exists` documentation](../../../ci/yaml/index.md#rulesexists).

## Error: `dependency_scanning is used for configuration only, and its script should not be executed`

For information, see the [GitLab Secure troubleshooting section](../../application_security/troubleshooting_application_security.md#error-job-is-used-for-configuration-only-and-its-script-should-not-be-executed).

## Import multiple certificates for Java-based projects

The `gemnasium-maven` analyzer reads the contents of the `ADDITIONAL_CA_CERT_BUNDLE` variable using `keytool`, which imports either a single certificate or a certificate chain. Multiple unrelated certificates are ignored and only the first one is imported by `keytool`.

To add multiple unrelated certificates to the analyzer, you can declare a `before_script` such as this in the definition of the `gemnasium-maven-dependency_scanning` job:

```yaml
gemnasium-maven-dependency_scanning:
  before_script:
    - . $HOME/.bashrc # make the java tools available to the script
    - OIFS="$IFS"; IFS=""; echo $ADDITIONAL_CA_CERT_BUNDLE > multi.pem; IFS="$OIFS" # write ADDITIONAL_CA_CERT_BUNDLE variable to a PEM file
    - csplit -z --digits=2 --prefix=cert multi.pem "/-----END CERTIFICATE-----/+1" "{*}" # split the file into individual certificates
    - for i in `ls cert*`; do keytool -v -importcert -alias "custom-cert-$i" -file $i -trustcacerts -noprompt -storepass changeit -keystore /opt/asdf/installs/java/adoptopenjdk-11.0.7+10.1/lib/security/cacerts 1>/dev/null 2>&1 || true; done # import each certificate using keytool (note the keystore location is related to the Java version being used and should be changed accordingly for other versions)
    - unset ADDITIONAL_CA_CERT_BUNDLE # unset the variable so that the analyzer doesn't duplicate the import
```

## Dependency Scanning job fails with message `strconv.ParseUint: parsing "0.0": invalid syntax`

Docker-in-Docker is unsupported, and attempting to invoke it is the likely cause of this error.

To fix this error, disable Docker-in-Docker for dependency scanning. Individual
`<analyzer-name>-dependency_scanning` jobs are created for each analyzer that runs in your CI/CD
pipeline.

```yaml
include:
  - template: Dependency-Scanning.gitlab-ci.yml

variables:
  DS_DISABLE_DIND: "true"
```

## Message `<file> does not exist in <commit SHA>`

When the `Location` of a dependency in a file is shown, the path in the link goes to a specific Git
SHA.

If the lock file that our dependency scanning tools reviewed was cached, however, selecting that
link redirects you to the repository root, with the message:
`<file> does not exist in <commit SHA>`.

The lock file is cached during the build phase and passed to the dependency scanning job before the
scan occurs. Because the cache is downloaded before the analyzer run occurs, the existence of a lock
file in the `CI_BUILDS_DIR` directory triggers the dependency scanning job.

To prevent this warning, lock files should be committed.

## You no longer get the latest Docker image after setting `DS_MAJOR_VERSION` or `DS_ANALYZER_IMAGE`

If you have manually set `DS_MAJOR_VERSION` or `DS_ANALYZER_IMAGE` for specific reasons,
and now must update your configuration to again get the latest patched versions of our
analyzers, edit your `.gitlab-ci.yml` file and either:

- Set your `DS_MAJOR_VERSION` to match the latest version as seen in
  [our current Dependency Scanning template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Dependency-Scanning.gitlab-ci.yml#L17).
- If you hardcoded the `DS_ANALYZER_IMAGE` variable directly, change it to match the latest
  line as found in our [current Dependency Scanning template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Dependency-Scanning.gitlab-ci.yml).
  The line number varies depending on which scanning job you edited.

  For example, the `gemnasium-maven-dependency_scanning` job pulls the latest
  `gemnasium-maven` Docker image because `DS_ANALYZER_IMAGE` is set to
  `"$SECURE_ANALYZERS_PREFIX/gemnasium-maven:$DS_MAJOR_VERSION"`.

## Dependency Scanning of setuptools project fails with `use_2to3 is invalid` error

Support for [2to3](https://docs.python.org/3/library/2to3.html)
was [removed](https://setuptools.pypa.io/en/latest/history.html#v58-0-0)
in `setuptools` version `v58.0.0`. Dependency Scanning (running `python 3.9`) uses `setuptools`
version `58.1.0+`, which doesn't support `2to3`. Therefore, a `setuptools` dependency relying on
`lib2to3` fails with this message:

```plaintext
error in <dependency name> setup command: use_2to3 is invalid
```

To work around this error, downgrade the analyzer's version of `setuptools` (for example, `v57.5.0`):

```yaml
gemnasium-python-dependency_scanning:
  before_script:
    - pip install setuptools==57.5.0
```

## Dependency Scanning of projects using psycopg2 fails with `pg_config executable not found` error

Scanning a Python project that depends on `psycopg2` can fail with this message:

```plaintext
Error: pg_config executable not found.
```

[psycopg2](https://pypi.org/project/psycopg2/) depends on the `libpq-dev` Debian package,
which is not installed in the `gemnasium-python` Docker image. To work around this error,
install the `libpq-dev` package in a `before_script`:

```yaml
gemnasium-python-dependency_scanning:
  before_script:
    - apt-get update && apt-get install -y libpq-dev
```

## `NoSuchOptionException` when using `poetry config http-basic` with `CI_JOB_TOKEN`

This error can occur when the automatically generated `CI_JOB_TOKEN` starts with a hyphen (`-`).
To avoid this error, follow [Poetry's configuration advice](https://python-poetry.org/docs/repositories/#configuring-credentials).

## Error: Project has `<number>` unresolved dependencies

The error message `Project has <number> unresolved dependencies` indicates a dependency resolution problem caused by your `gradle.build` or `gradle.build.kts` file. In the current release, `gemnasium-maven` cannot continue processing when an unresolved dependency is encountered. However, there is an [open epic](https://gitlab.com/groups/gitlab-org/-/epics/12361) to allow `gemnasium-maven` to recover from unresolved dependency errors and produce a dependency graph. Until this epic has been resolved, consult the [Gradle dependency resolution documentation](https://docs.gradle.org/current/userguide/dependency_resolution.html) for details on how to fix your `gradle.build` file.

## Setting build constraints when scanning Go projects

Dependency scanning runs within a `linux/amd64` container. As a result, the build list generated
for a Go project contains dependencies that are compatible with this environment. If your deployment environment is not
`linux/amd64`, the final list of dependencies might contain additional incompatible
modules. The dependency list might also omit modules that are only compatible with your deployment environment. To prevent
this issue, you can configure the build process to target the operating system and architecture of the deployment
environment by setting the `GOOS` and `GOARCH` [environment variables](https://go.dev/ref/mod#minimal-version-selection)
of your `.gitlab-ci.yml` file.

For example:

```yaml
variables:
  GOOS: "darwin"
  GOARCH: "arm64"
```

You can also supply build tag constraints by using the `GOFLAGS` variable:

```yaml
variables:
  GOFLAGS: "-tags=test_feature"
```

## Dependency Scanning of Go projects returns false positives

The `go.sum` file contains an entry of every module that was considered while generating the project's [build list](https://go.dev/ref/mod#glos-build-list).
Multiple versions of a module are included in the `go.sum` file, but the [MVS](https://go.dev/ref/mod#minimal-version-selection)
algorithm used by `go build` only selects one. As a result, when dependency scanning uses `go.sum`, it might report false positives.

To prevent false positives, Gemnasium only uses `go.sum` if it is unable to generate the build list for the Go project. If `go.sum` is selected, a warning occurs:

```shell
[WARN] [Gemnasium] [2022-09-14T20:59:38Z] ▶ Selecting "go.sum" parser for "/test-projects/gitlab-shell/go.sum". False positives may occur. See https://gitlab.com/gitlab-org/gitlab/-/issues/321081.
```

## `Host key verification failed` when trying to use `ssh`

After installing `openssh-client` on any `gemnasium` image, using `ssh` might lead to a `Host key verification failed` message. This can occur if you use `~` to represent the user directory during setup, due to setting `$HOME` to `/tmp` when building the image. This issue is described in [Cloning project over SSH fails when using `gemnasium-python` image](https://gitlab.com/gitlab-org/gitlab/-/issues/374571). `openssh-client` expects to find `/root/.ssh/known_hosts` but this path does not exist; `/tmp/.ssh/known_hosts` exists instead.

This has been resolved in `gemnasium-python` where `openssh-client` is pre-installed, but the issue could occur when installing `openssh-client` from scratch on other images. To resolve this, you may either:

1. Use absolute paths (`/root/.ssh/known_hosts` instead of `~/.ssh/known_hosts`) when setting up keys and hosts.
1. Add `UserKnownHostsFile` to your `ssh` config specifying the relevant `known_hosts` files, for example: `echo 'UserKnownHostsFile /tmp/.ssh/known_hosts' >> /etc/ssh/ssh_config`.

## `ERROR: THESE PACKAGES DO NOT MATCH THE HASHES FROM THE REQUIREMENTS FILE`

This error occurs when the hash for a package in a `requirements.txt` file does not match the hash of the downloaded package.
As a security measure, `pip` will assume that the package has been tampered with and will refuse to install it.
To remediate this, ensure that the hash contained in the requirements file is correct.
For requirement files generated by [`pip-compile`](https://pip-tools.readthedocs.io/en/stable/), run `pip-compile --generate-hashes` to ensure that the hash is up to date.
If using a `Pipfile.lock` generated by [`pipenv`](https://pipenv.pypa.io/), run `pipenv verify` to verify that the lock file contains the latest package hashes.

## `ERROR: In --require-hashes mode, all requirements must have their versions pinned with ==`

This error will occur if the requirements file was generated on a different platform than the one used by the GitLab Runner.
Support for targeting other platforms is tracked in [issue 416376](https://gitlab.com/gitlab-org/gitlab/-/issues/416376).
