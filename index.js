const core = require('@actions/core');
const github = require('@actions/github');
const exec = require('@actions/exec');
const path = require('path');
const fs = require('fs');

try {
  // display the current sha1
  var dirName = path.dirname(__filename);
  exec.exec(`bash -c "set -x; cd ${dirName}; git rev-parse HEAD"`);

  // `run-tests` input defined in action metadata file
  const cmdline = core.getInput('run-tests') || '.github/run-tests';
  console.log(`run-tests=${cmdline}`);
  
  // check that the command is executable and if ok launch it
  const cmd = cmdline.split(' ')[0];

  try {
    exec.exec(`${dirName}/validate-tests.sh ${cmdline}`);
  } catch(error) {
    process.exit(1);
  }
}
catch (error) {
  core.setFailed(error.message);
}
