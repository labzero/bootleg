# Contributing

You want to contribute? Awesome! We'd love the help. If you have an idea already, great. If not,
take a look at our [issue tracker][issues] and see if anything appeals. More tests and
documentation are always appreciated too.

## Getting Started

1. Fork the repository
2. Make sure the tests pass locally _before_ you start developing.
3. Write a test or two that cover your feature/bug/refactor (not needed for documentation-only changes)
4. Make your test pass by adding that slick new code.
5. Add documentation for your change (if appropriate)
6. Run `mix credo --strict` and `mix dialyzer` to ensure you haven't missed any coding standards.
7. Commit your changes and open a [pull request][pulls].
8. Wait for a speedy review of your change! Thank you!

## Development Dependencies

In order to run the functional tests, you need to have [Docker][docker] installed locally. The
community edition is fine, but you'll want to avoid the old versions that require a VM.

## Code Standards

Most of the code standards can be found in `.credo.exs`, and will be checked automatically by the
CI process. When in doubt, follow the standards in the file you are changing. Terse but descriptive
variable and function names make us happy. The standard Elixir guide on [writing documentation][writing-docs]
has some good tips on names. Documentation for new public functions is expected, as are tests for
any code change.

Good commit messages and PR descriptions are also important. See our guide on
[commit messages](https://github.com/labzero/guides/blob/master/process/commit_guide.md) for more details.

## Testing

Good tests are arguably more important than good code, so please take a moment to make sure
you have a few with your PR. Try to avoid mock-only tests, as they can get out of sync with reality
fairly easily. They are great for doing basic unit testing though! You'll see we use
[mock](https://github.com/jjh42/mock) as our mocking framework of choice.

Functional tests are much more reliable with a tool like Bootleg, and there are plenty of examples
in the project. `Bootleg.FunctionalCase` provides a simple interface for writing [Docker][docker]
based functional tests. By default each test case will get a single docker container provisioned,
and the details will be passed to `setup` under the key `hosts`. You can request more containers
using `@tag boot: 2` where `2` is the number of containers you'd like. During test development it's
often helpful to have the containers left running after the tests finish, and you can request that
by setting the `ENV` variable `TEST_LEAVE_CONTAINER` when running your tests. It's best to limit how
many tests are run in that case, or you may kill your machine with too many docker containers at once.

If you need a project to test against (this a deployment tool after all), take a look at
`Bootleg.Fixtures.inflate_project/1`. It will take any of the fixture projects and create a new
instance for use during testing. The `test/fixtures` directory contains all the currently available
fixture projects. Instances of projects created via `inflate_project/1` will be cleaned up when the
test suite exits, but you can suppress that by setting `TEST_LEAVE_TEMP` in the `ENV`. Fixtures are
always inflated to your OS temporary directory.

## Documentation

Bootleg's documentation is built using [mkdocs](https://www.mkdocs.org/), and uses [pymdown-extensions](https://facelessuser.github.io/pymdown-extensions/) for additional styling.

To build the documentation locally, see [scripts/docs/docs.sh](script/docs/docs.sh).

## Contact

You can reach the core Bootleg team in [#deployment](https://elixir-lang.slack.com/messages/C0LH49EPQ)
or [#bootleg](https://elixir-lang.slack.com/messages/C6D2BQY4R) on Elixir Slack. We are also reachable
via email at `bootleg@labzero.com`. Don't hesitate to get in touch, we'd love to hear from you.

Use the [issue tracker][issues] for bug reports or feature requests.

  [issues]: https://github.com/labzero/bootleg/issues
  [pulls]: https://github.com/labzero/bootleg/pulls
  [writing-docs]: http://elixir-lang.org/docs/stable/elixir/writing-documentation.html
  [docker]: https://www.docker.com/
