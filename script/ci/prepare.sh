#!/bin/bash

# NOTE: Keep in mind that this script does not verify the shasum of the downloads.

# NOTE: Don't forget to make this file executable or the build won't run

set -e



export ERLANG_VERSION="20.3"
export ELIXIR_VERSION="v1.6.0"

export ERLANG_PATH="$INSTALL_PATH/OTP-$ERLANG_VERSION"
export ELIXIR_PATH="$INSTALL_PATH/elixir_$ELIXIR_VERSION"
export KERL_PATH="$INSTALL_PATH/bin/kerl"


mkdir -p $INSTALL_PATH
cd $INSTALL_PATH

# Install erlang
if [ ! -e $INSTALL_PATH/bin/erl ]; then
  mkdir bin
  curl https://raw.githubusercontent.com/kerl/kerl/master/kerl -o $KERL_PATH
  chmod a+x $KERL_PATH
  $KERL_PATH build $ERLANG_VERSION $ERLANG_VERSION
  $KERL_PATH install $ERLANG_VERSION $INSTALL_PATH/erl
  . $INSTALL_PATH/erl/activate
else
  echo "Erlang already installed."
fi

# Install elixir
if [ ! -e $INSTALL_PATH/bin/elixir ]; then
  git clone https://github.com/elixir-lang/elixir $ELIXIR_PATH
  cd $ELIXIR_PATH
  git checkout $ELIXIR_VERSION
  PREFIX=$INSTALL_PATH make install
else
  echo "Elixir already installed."
fi

if [ $VERSION_CIRCLECI -ne 2 ]; then
  # Install package tools
  mix help | grep [^.]hex > /dev/null
  if [ $? -ne 0 ]; then
    yes Y | LC_ALL=en_GB.UTF-8 mix local.hex
  fi

  if [ ! -e $HOME/.mix/rebar ]; then
    yes Y | LC_ALL=en_GB.UTF-8 mix local.rebar
  fi

  # Fetch and compile dependencies and application code (and include testing tools)
  export MIX_ENV="test"
  cd $HOME/$CIRCLE_PROJECT_REPONAME
  mix do deps.get, deps.compile, compile, dialyzer --plt
fi