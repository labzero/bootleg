use Bootleg.Config

role :app, ["www1.example.com", "www2.example.com"]
role :app, ["www3.example.com"], port: 2222, user: "deploy"
role :db, "db.example.com", primary: true, user: "foo"
role :db, ["db2.example.com"], user: "foo"

config :build_at, "some path"
config :replace_me, "not this"
config :replace_me, "this"
