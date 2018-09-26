#!/bin/bash

# NOTE: Keep in mind that this script does not verify the shasum of the downloads.

# NOTE: Don't forget to make this file executable or the build won't run

set -e

export ERLANG_VERSION="21.0"
export ELIXIR_VERSION="v1.6.0"

export ERLANG_PATH="$INSTALL_PATH/otp_src_$ERLANG_VERSION"
export ELIXIR_PATH="$INSTALL_PATH/elixir_$ELIXIR_VERSION"

mkdir -p $INSTALL_PATH
cd $INSTALL_PATH

# Install erlang
if [ ! -e $INSTALL_PATH/bin/erl ]; then
  curl -L -O http://www.erlang.org/download/otp_src_$ERLANG_VERSION.tar.gz
  tar xzf otp_src_$ERLANG_VERSION.tar.gz
  cd $ERLANG_PATH
  ./configure --enable-smp-support \
              --enable-m64-build \
              --disable-native-libs \
              --disable-sctp \
              --enable-threads \
              --enable-kernel-poll \
              --disable-hipe \
              --without-javac \
              --prefix=$INSTALL_PATH
  make install
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