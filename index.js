const core = require('@actions/core');
const github = require('@actions/github');
const exec = require('@actions/exec');
const path = require('path');
const fs = require('fs');

try {
  // get the directory name to be able to launch validate-tests.sh
  var dirName = path.dirname(__filename);

  // `run-tests` input defined in action metadata file
  const cmdline = core.getInput('run-tests') || '.github/run-tests';

  // launch the command through validate-tests.sh and exit 1 in case
  // of error
  exec.exec(`${dirName}/validate-tests.sh ${cmdline}`).catch(error => {process.exit(1)});
}
catch (error) {
  core.setFailed(error.message);
}
