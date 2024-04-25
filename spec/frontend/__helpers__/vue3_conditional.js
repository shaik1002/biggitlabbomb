/* eslint-disable jest/valid-describe-callback, jest/no-disabled-tests */

export class SkipReason {
  constructor({ name, reason, issue } = {}) {
    if (!name || !reason || !issue) {
      throw new Error(`Provide a name, reason and issue: new SkipReason({name,reason,issue})`);
    }
    this.name = name;
    this.reason = reason;
  }
  toString() {
    return process.env.VUE_VERSION === '3'
      ? `  [SKIPPED with Vue@3]: ${this.name} (${this.reason})`
      : this.name;
  }
}
export function describeSkipVue3(reason, ...args) {
  if (!(reason instanceof SkipReason)) {
    throw new Error('Please provide a proper SkipReason');
  }

  return process.env.VUE_VERSION === '3'
    ? describe.skip(reason.toString(), ...args)
    : describe(reason.toString(), ...args);
}
