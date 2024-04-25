/* eslint-disable import/no-commonjs */

const { DefaultReporter, utils } = require('@jest/reporters');
const chalk = require('chalk');

const SKIP_TEXT = 'SKIP';
const START_TEXT = 'RUN ';
const SKIP = chalk.supportsColor ? chalk.reset.inverse.bold.yellow(` ${SKIP_TEXT} `) : SKIP_TEXT;
const START = chalk.supportsColor ? chalk.reset.bold.yellow(` ${START_TEXT} `) : START_TEXT;

/**
 * This Jest Reporter extends jest default reporter.
 * Per default the jest reporter just reports
 *
 * FAIL pathA
 * PASS pathB
 *
 * in CI. This makes it hard to debug in case a spec fails due to
 * OOM or other errors and hard to reproduce.
 *
 * Our jest reporter in CI prefixes every test result with a RUN
 * RUN  pathA
 * FAIL pathA
 * RUN  pathB
 * PASS pathB
 */
class GitLabJestReporter extends DefaultReporter {
  constructor(globalConfig) {
    super(globalConfig);
    if (process.env.CI || process.env.VUE_VERSION === '3') {
      this.log('GitLab Jest Reporter: CI mode on');
      this.onTestStart = this.logTestStartCI;
      this.onTestResult = this.logTestResultCI;
    } else {
      this.log('GitLab Jest Reporter: CI mode off');
    }
  }

  logTestResultCI(test, testResult, aggregatedResults) {
    super.onTestResult(test, testResult, aggregatedResults);

    // console.warn(test, testResult, aggregatedResults);
    if (testResult.skipped) {
      this.log(
        utils
          .getResultHeader(
            testResult,
            // eslint-disable-next-line no-underscore-dangle
            this._globalConfig,
            test.context.config,
          )
          .replace(/^.+?PASS.+? +/, `${SKIP} `),
      );

      const message = testResult?.testResults?.[0]?.ancestorTitles?.[0];
      if (message) {
        this.log(message);
      }
    }
  }

  logTestStartCI(test, ...args) {
    this.log(
      utils
        .getResultHeader(
          {
            testFilePath: test.path,
            numFailingTests: 0,
            testExecError: false,
          },
          // eslint-disable-next-line no-underscore-dangle
          this._globalConfig,
          test.context.config,
        )
        .replace(/^.+?PASS.+? +/, `${START} `),
    );

    super.onTestStart(test, ...args);
  }
}

module.exports = GitLabJestReporter;
