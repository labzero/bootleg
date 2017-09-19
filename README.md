# Bootleg

Simple deployment and server automation for Elixir.

**Bootleg** is a simple set of commands that attempt to simplify building and deploying elixir applications. The goal of the project is to provide an extensible framework that can support many different deploy scenarios with one common set of commands.

Out of the box, Bootleg provides remote build and remote server automation for your existing [Distillery](https://github.com/bitwalker/distillery) releases. Bootleg assumes your project is committed into a `git` repository and some of the build steps use this assumption
to handle code in some steps of the build process. If you are using an scm other than git, please consider contributing to Bootleg to
add additional support.

This branch (`gh-pages`) is only for the Bootleg public site. There is no code related to Bootleg
itself. The instructions below are for developing the public site, which uses [Jekyll](http://jekyllrb.com/) and GitHub pages.

## Installation

```sh
$ bundle install
```

## Local Development

To run the site locally:

```sh
$ jekyll server
```

Then navigate to [localhost:4000/bootleg/](http://localhost:4000/bootleg/).


## Remote Deployment

Send a PR against `gh-pages` with your changes. Once they are merged in, GitHub will automatically deploy
them for you (eventually).

-----

## Contributing

We welcome everyone to contribute to Bootleg and help us tackle existing issues!

Use the [issue tracker][issues] for bug reports or feature requests.
Open a [pull request][pulls] when you are ready to contribute.


## LICENSE

Bootleg source code is released under the MIT License.
Check the [LICENSE](LICENSE) file for more information.

  [issues]: https://github.com/labzero/bootleg/issues
  [pulls]: https://github.com/labzero/bootleg/pulls



