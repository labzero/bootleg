#!/bin/bash

export MIX_ENV="test"
export PATH="$HOME/dependencies/bin:$PATH"
exec mix "$@"
