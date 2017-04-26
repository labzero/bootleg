#!/bin/bash

export MIX_ENV="test"
export PATH="$HOME/dependencies/erlang/bin:$HOME/dependencies/elixir/bin:$PATH"
mix dialyzer
DIALYZER=$?
mix credo
CREDO=$?
mix test
TEST=$?

if [ $DIALYZER -ne 0 ] || [ $CREDO -ne 0 ] || [ $TEST -ne 0 ]
then
  exit 1
fi