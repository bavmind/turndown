# Contributing

Thanks for taking the time to contribute.

## Getting started

```bash
git clone https://github.com/bavmind/turndown.git
cd turndown
bundle install
bundle exec rake test
```

## This gem is a port

Behavior here is meant to match [Turndown](https://github.com/mixmark-io/turndown).
That shapes what makes a good contribution:

- **Parity bugs are the most valuable reports.** If this gem and upstream
  Turndown produce different Markdown for the same HTML, that is a bug. Please
  include the HTML input, the Markdown this gem produced, and the Markdown
  upstream produced.
- **New conversion behavior generally belongs upstream first.** If you want
  Turndown to convert something differently, open an issue on the upstream
  project. Once it lands there, a port here is straightforward.
- **Ruby-side improvements are always welcome** — performance, error messages,
  documentation, and API ergonomics are ours to own.

## Tests

The parity fixtures under `test/fixtures/upstream/` are vendored copies of the
upstream corpus. Please don't edit them to make a test pass; if a fixture
disagrees with the implementation, the implementation is what changes.

Add Ruby-specific coverage to `test/converter_test.rb`.

## Pull requests

1. Fork and create a branch.
2. Make your change, with tests.
3. Make sure `bundle exec rake test` passes.
4. Add a `CHANGELOG.md` entry under `## [Unreleased]`.
5. Open the pull request and describe what changed and why.

## License

By contributing, you agree that your contributions are licensed under the MIT
License, the same as this project.
