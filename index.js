const core = require('@actions/core');
const github = require('@actions/github');
const exec = require('@actions/exec');
const path = require('path');
const fs = require('fs');

try {
  // `run-tests` input defined in action metadata file
  const cmdline = core.getInput('run-tests') || '.github/run-tests';
  console.log(`run-tests=${cmdline}`);
  var dirName = path.dirname(__filename);

  // Get the JSON webhook payload for the event that triggered the workflow
  const payload = JSON.stringify(github.context.payload, undefined, 2)
  console.log(`The event payload: ${payload}`);
  
  // check that the command is executable and if ok launch it
  const cmd = cmdline.split(' ')[0];

  fs.access(cmd, fs.constants.X_OK, (err) => {
    if (!err) {
      exec.exec(`${dirName}/validate-tests.sh ${cmdline}`);
    } else {
      core.setFailed(`${cmd} is not executable`);
    }
  });
}
catch (error) {
  core.setFailed(error.message);
}
