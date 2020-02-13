const Sequencer = require('@jest/test-sequencer').default;

class ParallelCISequencer extends Sequencer {
  constructor() {
    super();
    this.ciNodeIndex = parseInt(process.env.CI_NODE_INDEX || '1');
    this.ciNodeTotal = parseInt(process.env.CI_NODE_TOTAL || '1');
  }

  sort(tests) {
    const testsForThisRunner = this.distributeAcrossCINodes(tests);

    console.log(`CI_NODE_INDEX: ${this.ciNodeIndex}`);
    console.log(`CI_NODE_TOTAL: ${this.ciNodeTotal}`);
    console.log(`Total number of tests: ${tests.length}`);
    console.log(`Total number of tests for this runner: ${testsForThisRunner.length}`);

    return super.sort(testsForThisRunner);
  }

  distributeAcrossCINodes(tests) {
    return tests.filter((test, index) => {
      return index % this.ciNodeTotal === this.ciNodeIndex - 1;
    });
  }
}

module.exports = ParallelCISequencer;
