# has-useful-tests-action

GitHub action to validate that tests are useful by running them without the code from the PR and expecting them to fail.

* [GitHub Action for Running tests](#github-action-for-running-tests)
  * [Overview](#overview)
  * [Enabling the action](#enabling-the-action)
  * [Sample Configuration](#sample-configuration)
  * [Advanced Configuration](#advanced-configuration)

## Overview

This action allows you to run a command when your workflow action is triggered.  If your command terminates with an exit-code different of 0 that is regarded as a pass, otherwise the action will be marked as a failure.

The action is detecting if a PR is doc only or tests only to avoid false negative results.

The expectation is that you'll use this action to launch your project-specific test-cases, ensuring that all pull-requests, commits, or both, are tested automatically.

# Enabling the action

There are two steps required to use this action:

* Enable the action inside your repository.
  * You'll probably want to enable it upon pull-requests, to ensure their quality.
* Add your project-specific test-steps to a command in your repository.
  * By default this action will execute `.github/run-tests`, but you can specify a different name if you prefer.
  * The exit-code of your command will determine the result.

## Sample Configuration

Defining Github Actions requires that you create a directory `.github/workflows` inside your repository.  Inside the workflow-directory you create files which are processed when various events occur.

For example:

* .`github/workflows/pull_request.yml`
  * This is used when a pull-request is created/updated upon your repository.
* `.github/workflows/push.yml`
  * This is used when a commit is pushed to your repository.

The simplest example of using this action would be to create the file `.github/workflows/pull_request.yml` with the following contents:

```yml
on: pull_request
name: Pull Request
jobs:
  validate-tests:
    name: Run tests
    runs-on: ubuntu-latest
    steps:
    - name: Checkout code
      uses: actions/checkout@master
    - name: Run your tests
      run: make tests
    - name: Validate Tests
      uses: quality-of-tests/has-useful-tests-action@master
      with:
        run-tests: make tests
```

This example will run the `make tests`, every time a pull-request is
created, edited, or updated. It will be run first to validate the
change and then run the tests without the code expecting them to
fail.

## Advanced configuration

If you want to debug the action, set verbose to true. In our example,
it would be like that:

```yml
    - name: Validate Tests
      uses: quality-of-tests/has-useful-tests-action@master
      with:
        run-tests: make tests
        verbose: true
```
