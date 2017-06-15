use Bootleg.Config

role :app, ["www1.example.com", "www2.example.com"]
role :db, "db.example.com", primary: true, user: "foo"
role :replace, "replaceme.example.com", user: "replaceme"
role :replace, "replacement.example.com", bar: :car

config :build_at, "some path"
config :replace_me, "not this"
config :replace_me, "this"
