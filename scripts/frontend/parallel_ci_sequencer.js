const fs = require('node:fs');
const { join } = require('node:path');

const Sequencer = require('@jest/test-sequencer').default;

const tmpPath = join(__dirname, '../../tmp/tests/frontend/');
const targetFile = join(tmpPath, 'ci_jest_spec_sequence.txt');

const sortByPath = (test1, test2) => {
  if (test1.path < test2.path) {
    return -1;
  }
  if (test1.path > test2.path) {
    return 1;
  }
  return 0;
};

class ParallelCISequencer extends Sequencer {
  constructor() {
    super();
    this.ciNodeIndex = Number(process.env.CI_NODE_INDEX || '1');
    this.ciNodeTotal = Number(process.env.CI_NODE_TOTAL || '1');
  }

  sort(tests) {
    const sortedTests = [...tests].sort(sortByPath);
    const testsForThisRunner = this.distributeAcrossCINodes(sortedTests);

    console.log(`CI_NODE_INDEX: ${this.ciNodeIndex}`);
    console.log(`CI_NODE_TOTAL: ${this.ciNodeTotal}`);
    console.log(`Total number of tests: ${tests.length}`);
    console.log(`Total number of tests for this runner: ${testsForThisRunner.length}`);

    fs.mkdirSync(tmpPath, { recursive: true });
    fs.writeFileSync(targetFile, `${testsForThisRunner.map((x) => x.path).join('\n')}\n`, 'utf-8');
    console.log(`Wrote out sequence of specs to ${targetFile}`);

    return testsForThisRunner;
  }

  distributeAcrossCINodes(tests) {
    return tests.filter((test, index) => {
      return index % this.ciNodeTotal === this.ciNodeIndex - 1;
    });
  }
}

module.exports = ParallelCISequencer;
