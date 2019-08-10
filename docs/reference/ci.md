## CircleCI

### Running builds from CircleCI

#### Add SSH keys to CircleCI

To connect to remote build or app servers using SSH public keys, you must first
define those keys in your CircleCI project settings, under "Checkout SSH keys".
After adding a key its fingerprint will be displayed.

!!! example "Example SSH key fingerprint"
    27:a3:eb:bc:65:b1:99:de:3a:42:3f:9e:75:b6:1b:f9

#### Using SSH keys in CircleCI containers

In order for your container to receive that key, you must specify it in your
`.circleci/config.yml` using the CircleCI
[`add_ssh_keys`](https://circleci.com/docs/2.0/configuration-reference/#add_ssh_keys)
step.

!!! example "CircleCI SSH key configuration"
    ```yml
    - add_ssh_keys:
         fingerprints:
           - "27:a3:eb:bc:65:b1:99:de:3a:42:3f:9e:75:b6:1b:f9"
    ```

At this point your container will have SSH keys available when launched:

    :::plain
    .ssh/
    ├── id_rsa # an auto-generated key
    └── id_rsa_27a3ebbc65b199de3a423f9e75b61bf9 # your key

The private key file is named using the fingerprint above.

#### Using the CircleCI SSH key within Bootleg

To inform Bootleg of your key, you can specify this full filename, or you could symlink or copy it to another name.

!!! example "Option 1: Specify the full filename in Bootleg"
    ```elixir
    role :build, "example.com", identity: "~/.ssh/id_rsa_27a3ebbc65b199de3a423f9e75b61bf9"
    ```

!!! example "Option 2: Create a symbolic link in CircleCI"
    Within your CircleCI yml:
    ```yml
    steps:
      - run: ln -s ~/.ssh/id_rsa_27a3* ~/.ssh/id_foobar_rsa
    ```

    Within Bootleg config:
    ```elixir
    role :build, "example.com", identity: "~/.ssh/id_foobar_rsa"
    ```

!!! example "Option 3: Overwrite the default `id_rsa`"
    Within your CircleCI yml:
    ```yml
    steps:
      - run: cp ~/.ssh/id_rsa_* ~/.ssh/id_rsa
    ```

    Within Bootleg config:
    ```elixir
    role :build, "example.com", identity: "~/.ssh/id_rsa"
    ```
