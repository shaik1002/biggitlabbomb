---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
---

# Flaky tests

## What's a flaky test?

It's a test that sometimes fails, but if you retry it enough times, it passes,
eventually.

## What are the potential cause for a test to be flaky?

### State leak

**Label:** `flaky-test::state leak`

**Description:** Data state has leaked from a previous test. The actual cause is probably not the flaky test here.

**Difficulty to reproduce:** Moderate. Usually, running the same spec files until the one that's failing reproduces the problem.

**Resolution:** Fix the previous tests and/or places where the test data or environment is modified, so that
it's reset to a pristine test after each test.

**Examples:**

- [Example 1](https://gitlab.com/gitlab-org/gitlab/-/issues/402915): State leakage can result from
  data records created with `let_it_be` shared between test examples, while some test modifies the model
  either deliberately or unwillingly causing out-of-sync data in test examples. This can result in `PG::QueryCanceled: ERROR` in the subsequent test examples or retries.
  For more information about state leakages and resolution options, see [GitLab testing best practices](best_practices.md#lets-talk-about-let).
- [Example 2](https://gitlab.com/gitlab-org/gitlab/-/issues/378414#note_1142026988): A migration
  test might roll-back the database, perform its testing, and then roll-up the database in an
  inconsistent state, so that following tests might not know about certain columns.
- [Example 3](https://gitlab.com/gitlab-org/gitlab/-/issues/368500): A test modifies data that is
  used by a following test.
- [Example 4](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/103434#note_1172316521): A test for a database query passes in a fresh database, but in a
  CI/CD pipeline where the database is used to process previous test sequences, the test fails. This likely
  means that the query itself needs to be updated to work in a non-clean database.
- [Example 5](https://gitlab.com/gitlab-org/gitlab/-/issues/416663#note_1457867234): Unrelated database connections
  in asynchronous requests checked back in, causing the tests to accidentally
  use these unrelated database connections. The failure was resolved in this
  [merge request](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/125742).
- [Example 6](https://gitlab.com/gitlab-org/gitlab/-/issues/418757#note_1502138269): The maximum time to live
  for a database connection causes these connections to be disconnected, which
  in turn causes tests that rely on the transactions on these connections to
  in turn causes tests that rely on the transactions on these connections to
  fail. The issue was fixed in this [merge request](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/128567).
- [Example 7](https://gitlab.com/gitlab-org/quality/engineering-productivity/master-broken-incidents/-/issues/3389#note_1534827164):
  A TCP socket used in a test was not closed before the next test, which also used
  the same port with another TCP socket.

### Dataset-specific

**Label:** `flaky-test::dataset-specific`

**Description:** The test assumes the dataset is in a particular (usually limited) state or order, which
might not be true depending on when the test run during the test suite.

**Difficulty to reproduce:** Moderate, as the amount of data needed to reproduce the issue might be
difficult to achieve locally. Ordering issues are easier to reproduce by repeatedly running the tests several times.

**Resolution:**

- Fix the test to not assume that the dataset is in a particular state, don't hardcode IDs.
- Loosen the assertion if the test shouldn't care about ordering but only on the elements.
- Fix the test by specifying a deterministic ordering.
- Fix the app code by specifying a deterministic ordering.

**Examples:**

- [Example 1](https://gitlab.com/gitlab-org/gitlab/-/issues/378381): The database is recreated when
  any table has more than 500 columns. It could pass in the merge request, but fail later in
  `master` if the order of tests changes.
- [Example 2](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/91016/diffs): A test asserts
  that trying to find a record with an nonexistent ID returns an error message. The test uses an
  hardcoded ID that's supposed to not exist (for example, `42`). If the test is run early in the test
  suite, it might pass as not enough records were created before it, but as soon as it would run
  later in the suite, there could be a record that actually has the ID `42`, hence the test would
  start to fail.
- [Example 3](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/10148/diffs): Without
  specifying `ORDER BY`, database is not given deterministic ordering, or data race can happen
  in the tests.
- [Example 4](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/106936/diffs).

### Random input

**Label:** `flaky-test::random input`

**Description:** The test use random values, that sometimes match the expectations, and sometimes not.

**Difficulty to reproduce:** Easy, as the test can be modified locally to use the "random value"
used at the time the test failed

**Resolution:** Once the problem is reproduced, it should be easy to debug and fix either the test
or the app.

**Examples:**

- [Example 1](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/20121): The test isn't robust enough to handle a specific data, that only appears sporadically since the data input is random.

### Unreliable DOM Selector

**Label:** `flaky-test::unreliable dom selector`

**Description:** The DOM selector used in the test is unreliable.

**Difficulty to reproduce:** Moderate to difficult. Depending on whether the DOM selector is duplicated, or appears after a delay etc.
Adding a delay in API or controller could help reproducing the issue.

**Resolution:** It really depends on the problem here. It could be to wait for requests to finish, to scroll down the page etc.

**Examples:**

- [Example 1](https://gitlab.com/gitlab-org/gitlab/-/issues/338341): A non-unique CSS selector
  matching more than one element, or a non-waiting selector method that does not allow rendering
  time before throwing an `element not found` error.
- [Example 2](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/101728/diffs): A CSS selector
  only appears after a GraphQL requests has finished, and the UI has updated.
- [Example 3](https://gitlab.com/gitlab-org/gitlab/-/issues/408215): A false-positive test, Capybara immediately returns true after
  page visit and page is not fully loaded, or if the element is not detectable by webdriver (such as being rendered outside the viewport or behind other elements).

### Datetime-sensitive

**Label:** `flaky-test::datetime-sensitive`

**Description:** The test is assuming a specific date or time.

**Difficulty to reproduce:** Easy to moderate, depending on whether the test consistently fails after a certain date, or only fails at a given time or date.

**Resolution:** Freezing the time is usually a good solution.

**Examples:**

- [Example 1](https://gitlab.com/gitlab-org/gitlab/-/issues/118612): A test that breaks after some time passed.
- [Example 2](https://gitlab.com/gitlab-org/gitlab/-/issues/403332): A test that breaks in the last day of the month.

### Unstable infrastructure

**Label:** `flaky-test::unstable infrastructure`

**Description:** The test fails from time to time due to infrastructure issues.

**Difficulty to reproduce:** Hard. It's really hard to reproduce CI infrastructure issues. It might
be possible by using containers locally.

**Resolution:** Starting a conversation with the Infrastructure department in a dedicated issue is
usually a good idea.

**Examples:**

- [Example 1](https://gitlab.com/gitlab-org/gitlab/-/issues/363214): The runner is under heavy load at this time.
- [Example 2](https://gitlab.com/gitlab-org/gitlab/-/issues/360559): The runner is having networking issues, making a job failing early

## How to reproduce a flaky test locally?

1. Reproduce the failure locally
   - Find RSpec `seed` from the CI job log
   - OR Run `while :; do bin/rspec <spec> || break; done` in a loop to find a `seed`
1. Reduce the examples by bisecting the spec failure with `bin/rspec --seed <previously found> --bisect <spec>`
1. Look at the remaining examples and watch for state leakage
    - e.g. Updating records created with `let_it_be` is a common source of problems
1. Once fixed, rerun the specs with `seed`
1. Run `scripts/rspec_check_order_dependence` to ensure the spec can be run in [random order](best_practices.md#test-order)
1. Run `while :; do bin/rspec <spec> || break; done` in a loop again (and grab lunch) to verify it's no longer flaky

## Quarantined tests

When we have a flaky test in `master`:

1. Create [a ~"failure::flaky-test" issue](https://handbook.gitlab.com/handbook/engineering/workflow/#broken-master) with the relevant group label.
1. Quarantine the test after the first failure.
   If the test cannot be fixed in a timely fashion, there is an impact on the
   productivity of all the developers, so it should be quarantined.

### RSpec

#### Fast quarantine

Unless you really need to have a test disabled very fast (`< 10min`), consider [using the `~pipeline::expedited` label instead](../pipelines/index.md#the-pipelineexpedited-label).

To quickly quarantine a test without having to open a merge request and wait for pipelines,
you can follow [the fast quarantining process](https://gitlab.com/gitlab-org/quality/engineering-productivity/fast-quarantine/-/tree/main/#fast-quarantine-a-test).

**Please always proceed** to [open a long-term quarantine merge request](#long-term-quarantine) after fast-quarantining a test! This is to ensure the fast-quarantined test was correctly fixed by running tests from the CI/CD pipelines (which are not run in the context of the fast-quarantine project).

#### Long-term quarantine

Once a test is fast-quarantined, you can proceed with the long-term quarantining process. This can be done by opening a merge request.

First, ensure the test file has a [`feature_category` metadata](../feature_categorization/index.md#rspec-examples), to ensure correct attribution of the test file.

Then, you can use the `quarantine: '<issue url>'` metadata with the URL of the
~"failure::flaky-test" issue you created previously.

```ruby
it 'succeeds', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/12345' do
  expect(response).to have_gitlab_http_status(:ok)
end
```

This means it is skipped in CI. By default, the quarantined tests will run locally.

We can skip them in local development as well by running with `--tag ~quarantine`:

```shell
bin/rspec --tag ~quarantine
```

After the long-term quarantining MR has reached production, you should revert the fast-quarantine MR you created earlier.

#### Find quarantined tests by feature category

To find all quarantined tests for a feature category, use `ripgrep`:

```shell
rg -l --multiline -w "(?s)feature_category:\s+:global_search.+quarantine:"
```

### Jest

For Jest specs, you can use the `.skip` method along with the `eslint-disable-next-line` comment to disable the `jest/no-disabled-tests` ESLint rule and include the issue URL. Here's an example:

```javascript
// quarantine: https://gitlab.com/gitlab-org/gitlab/-/issues/56789
// eslint-disable-next-line jest/no-disabled-tests
it.skip('should throw an error', () => {
  expect(response).toThrowError(expected_error)
});
```

This means it is skipped unless the test suit is run with `--runInBand` Jest command line option:

```shell
jest --runInBand
```

A list of files with quarantined specs in them can be found with the command:

```shell
yarn jest:quarantine
```

For both test frameworks, make sure to add the `~"quarantined test"` label to the issue.

Once a test is in quarantine, there are 3 choices:

- Fix the test (that is, get rid of its flakiness).
- Move the test to a lower level of testing.
- Remove the test entirely (for example, because there's already a
  lower-level test, or it's duplicating another same-level test, or it's testing
  too much etc.).

## Automatic retries and flaky tests detection

On our CI, we use [`RSpec::Retry`](https://github.com/NoRedInk/rspec-retry) to automatically retry a failing example a few
times (see [`spec/spec_helper.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/spec/spec_helper.rb) for the precise retries count).

We also use a custom [`Gitlab::RspecFlaky::Listener`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/gems/gitlab-rspec_flaky/lib/gitlab/rspec_flaky/listener.rb).
This listener runs in the `update-tests-metadata` job in `maintenance` scheduled pipelines
on the `master` branch, and saves flaky examples to `rspec/flaky/report-suite.json`.
The report file is then retrieved by the `retrieve-tests-metadata` job in all pipelines.

This was originally implemented in: <https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/13021>.

If you want to enable retries locally, you can use the `RETRIES` environment variable.
For instance `RETRIES=1 bin/rspec ...` would retry the failing examples once.

To generate the reports locally, use the `FLAKY_RSPEC_GENERATE_REPORT` environment variable.
For example, `FLAKY_RSPEC_GENERATE_REPORT=1 bin/rspec ...`.

### Usage of the `rspec/flaky/report-suite.json` report

The `rspec/flaky/report-suite.json` report is
[imported into Snowflake](https://gitlab.com/gitlab-data/analytics/-/blob/7085bea51bb2f8f823e073393934ba5f97259459/extract/gitlab_flaky_tests/upload.py#L19)
once per day, for monitoring with the
[internal dashboard](https://app.periscopedata.com/app/gitlab/888968/EP---Flaky-tests).

## Problems we had in the past at GitLab

- [`rspec-retry` is biting us when some API specs fail](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/29242): <https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/9825>
- [Sporadic RSpec failures due to `PG::UniqueViolation`](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/28307#note_24958837): <https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/9846>
  - Follow-up: <https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/10688>
  - [Capybara.reset_session! should be called before requests are blocked](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/33779): <https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/12224>
- ffaker generates funky data that tests are not ready to handle (and tests should be predictable so that's bad!):
  - [Make `spec/mailers/notify_spec.rb` more robust](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/20121): <https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/10015>
  - [Transient failure in `spec/requests/api/commits_spec.rb`](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/27988#note_25342521): <https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/9944>
  - [Replace ffaker factory data with sequences](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/29643): <https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/10184>
  - [Transient failure in spec/finders/issues_finder_spec.rb](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/30211#note_26707685): <https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/10404>

### Order-dependent flaky tests

These flaky tests can fail depending on the order they run with other tests. For example:

- <https://gitlab.com/gitlab-org/gitlab/-/issues/327668>

To identify the tests that lead to such failure, we can use `scripts/rspec_bisect_flaky`,
which would give us the minimal test combination to reproduce the failure:

1. First obtain the list of specs that ran before the flaky test. You can search
   for the list under `Knapsack node specs:` in the CI job output log.
1. Save the list of specs as a file, and run:

   ```shell
   cat knapsack_specs.txt | xargs scripts/rspec_bisect_flaky
   ```

If there is an order-dependency issue, the script above will print the minimal
reproduction.

### Time-sensitive flaky tests

- <https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/10046>
- <https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/10306>

### Array order expectation

- <https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/10148>

### Feature tests

- [Be sure to create all the data the test need before starting exercise](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/32622#note_31128195): <https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/12059>
- [Bis](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/34609#note_34048715): <https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/12604>
- [Bis](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/34698#note_34276286): <https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/12664>
- [Assert against the underlying database state instead of against a page's content](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/31437): <https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/10934>
- In JS tests, shifting elements can cause Capybara to mis-click when the element moves at the exact time Capybara sends the click
  - [Dropdowns rendering upward or downward due to window size and scroll position](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/17660)
  - [Lazy loaded images can cause Capybara to mis-click](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/18713)
- [Triggering JS events before the event handlers are set up](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/18742)
- [Wait for the image to be lazy-loaded when asserting on a Markdown image's `src` attribute](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/25408)
- [Avoid asserting against flash notice banners](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/79432)

#### Capybara viewport size related issues

- [Transient failure of spec/features/issues/filtered_search/filter_issues_spec.rb](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/29241#note_26743936): <https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/10411>

#### Capybara JS driver related issues

- [Don't wait for AJAX when no AJAX request is fired](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/30461): <https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/10454>
- [Bis](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/34647): <https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/12626>

#### Capybara expectation times out

- [Test imports a project (via Sidekiq) that is growing over time, leading to timeouts when the import takes longer than 60 seconds](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/22599)

### Hanging specs

If a spec hangs, it might be caused by a [bug in Rails](https://github.com/rails/rails/issues/45994):

- <https://gitlab.com/gitlab-org/gitlab/-/merge_requests/81112>
- <https://gitlab.com/gitlab-org/gitlab/-/issues/337039>

## Suggestions

### Split the test file

It could help to split the large RSpec files in multiple files in order to narrow down the context and identify the problematic tests.

### Recreate job failure in CI by forcing the job to run the same set of test files

Reproducing a job failure in CI always helps with troubleshooting why and how a test fails. This require us running the same test files with the same spec order. Since we use Knapsack to distribute tests across parallelized jobs, and files can be distributed differently between two pipelines, we can hardcode this job distribution through the following steps:

1. Find a job that you want to reproduce, identify the commit that it ran against, set your local `gitlab-org/gitlab` branch to the same commit to ensure we are running with the same copy of the project.
1. In the job log, locate the list of spec files that were distributed by Knapsack - you can search for `Running command: bundle exec rspec`, the last argument of this command should contain a list of filenames. Copy this list.
1. Go to `tooling/lib/tooling/parallel_rspec_runner.rb` where the test file distribution happens. Have a look at [this merge request](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137924/diffs) as an example, store the file list you copied from step 2 into a `TEST_FILES` constant and have RSpec run this list by updating the `rspec_command` method as done in the example MR.
1. Skip the tests in `spec/tooling/lib/tooling/parallel_rspec_runner_spec.rb` so it doesn't cause your pipeline to fail early.
1. Since we want to force the pipeline to run against a specific version, we do not want to run a merged results pipeline. We can introduce a merge conflict into the MR to achieve this.
1. To preserve spec ordering, update the `spec/support/rspec_order.rb` file by hard coding `Kernel.srand` with the value shown in the originally failing job, as done [here](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/128428/diffs#32f6fa4961481518204e227252552dba7483c3b0_62_62). You can fine the srand value in the job log by searching `Randomized with seed` which is followed by this value.

## Resources

- [Flaky Tests: Are You Sure You Want to Rerun Them?](https://semaphoreci.com/blog/2017/04/20/flaky-tests.html)
- [How to Deal With and Eliminate Flaky Tests](https://semaphoreci.com/community/tutorials/how-to-deal-with-and-eliminate-flaky-tests)
- [Tips on Treating Flakiness in your Rails Test Suite](https://semaphoreci.com/blog/2017/08/03/tips-on-treating-flakiness-in-your-test-suite.html)
- ['Flaky' tests: a short story](https://www.ombulabs.com/blog/rspec/continuous-integration/how-to-track-down-a-flaky-test.html)
- [Test Insights](https://circleci.com/docs/insights-tests/)

---

[Return to Testing documentation](index.md)
