defmodule Mix.Tasks.Bootleg.Upgrade do
  use Bootleg.MixTask, :upgrade

  @shortdoc "Build, deploy, and hot upgrade a release all in one command."

  @moduledoc """
  Build, deploy, and hot upgrade a new release all in one command.

  Note that this comand will _not_ do an Ecto migration.

  ## Usage:

    * mix bootleg.upgrade

  ## Caution

  Please never try to hot upgrade a running application without 
  having first a good understand of how a hot upgrade is performed, 
  its limitations and steps required.

  See next sections for an overview of the hot upgrade process.

  ## Hot upgrading a running application

  Hot upgrade is the process that allows to seamlessly change 
  the code of a running application without the need to 
  stopping and restarting it, i.e. mantaining active the 
  service in production.

  This is one of the most interesting capabilities of Erlang/OTP,
  but it is a very complex process that *cannot* be fully 
  automated, i.e. require a good knowledge of the tecnologies 
  involved and the configurations files needed and their locations
  at every stage of the process. You have also to know how to
  recognize when a hot upgrade isn't an advisable action,
  because it could have some severe limitations 
  and unwanted consequences in some circumstances.

  Therefore it is strongly advised you read the official 
  documentation about the hot upgrade stuff on the Erlang/OTP
  website, and how Distillery, the technolgy underlying
  the Bootleg task, accomplished that.

  Here it is a selected - but not exaustive - list of important 
  pieces of documentation to read:

  # OTP Design Principles - Releases
    http://erlang.org/doc/design_principles/release_structure.html

  # OTP Design Principles - Release Handling
    http://erlang.org/doc/design_principles/release_handling.html

  # System Architecture Support Libraries - appup
    http://erlang.org/doc/man/appup.html

  # Distillery - Hot upgrades and downgrades
    https://hexdocs.pm/distillery/guides/upgrades_and_downgrades.html

  # Distillery - Appups
    https://hexdocs.pm/distillery/guides/appups.html

  ### Bootleg hot upgrade task

  In the following description we assume that the development 
  enviroinment is organized in this way (the build and 
  the production places can be the same machine):

    * the development machine - where you edit and 
      test locally your app source files;

    * the build machine - the computer where you will transfer to
      and compile the committed source code;

    * the production server - the server where you will deploy 
      (transfer to and run) the code previously compiled on 
      the build machine.

  Bootleg helps you in the hot upgrade process providing 
  some specific tasks:

    * mix bootleg.build_upgrade
      will tranfer the last committed source code of your application
      from the development machine to the build directory of 
      your build machine (for example `~/build/myapp/`), then
      it will clean the directory from the previous code deleting
      every file but the `_build` directory, it will generate the
      `appup` file and compile the newest app release.

      Please note that before you can use this task for the first time, 
      you have to deploy your _first version_ of your app using 
      `bootleg.build`, `bootleg.deploy` and `bootleg.start` 
      (or `bootleg.update`);

    * mix bootleg.deploy_upgrade
      will transfer the tarball of the compiled app from the 
      build machine to the production directory of the production
      machine (e.g. `~/production/myapp/`), then it will extract 
      and setting up the needed files;

    * mix bootleg.hot_upgrade
      will call `mix distillery <myapp> upgrade <version>` that
      will upgrade the running app to the last version. Notice that
      you *cannot* use this task if the app is not running, or 
      if it there is a mismatch in the version numbers of the
      deployed versions.

    * mix bootleg.upgrade
      Call in sequences the above tasks in just one command.

  ### A step-by-step example

  Given you have configured the first version of your app with all
  the needed and appropriately customized Bootleg configuration files, 
  you can go through the following steps to release and run the 
  first version, and subsequentely hot upgrade it to the newest
  versions:

  First version of your app

    # Step 1 - deploy the first version of your app
      edit the version number of your in the mix.exs file 
      (or in the file if you use an external reference),
      to the first version (e.g. 0.1.0);

    # Step 2 - Commit
      commit the changes you've made in step 1;

    # Step 3 - Build the first version
      use `mix bootleg.build` (not bootleg.build_upgrade!) to build 
      your first version;

    # Step 4 - Deploy the first version
      use `mix bootleg.deploy` (not bootleg.build_upgrade!) to deploy 
      your first version;

    # Step 5 - Run the first version
      use `mix bootleg.start` to run the app

    now your first version is up and running. To upgrade it 
    to the future version, you have to follow these steps instead:

  Following versions

    # Step 1 - update the version number
      e.g. 0.2.0

    # Step 2 - Commit

    # Step 3 - Build the new version
      use `mix bootleg.build_upgrade`

    # Step 4 - Deploy the new version
      use `mix bootleg.deploy_upgrade`

    # Step 5 - Hot upgrade the new version
      use `mix bootleg.hot_upgrade`

    (or you can execute just the `bootleg.upgrade` 
    that packs the previous tasks together if you don't need to
    manually adjust the created `appup` file)

    Now you have an upgraded version running. But if you stop
    and restart it, the previous version will be launched instead
    of the most recent. This is useful because if your new version 
    has some blocking bug, you can easily restart the service to the last 
    working release.
    
    If you are shure that you want to having the last version restarted,
    just delete the folder `~/production/myapp/var`. This folder contains
    the file `start_erl.data` that lists the version number to start with.
    Deleting the `var` folder will automatically create it next time the app
    is started, with the last version number.

  """
end
