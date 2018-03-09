use Bootleg.DSL

before_task(:foo, :bar)
after_task(:bar, do: invoke(:hello))

before_task :foo do
  send(self(), {:before, :foo})
end

before_task(:hello, do: send(self(), {:before, :hello}))

after_task :hello do
  send(self(), {:after, :hello})
end

after_task(:foo, :another_task)
after_task(:another_task, do: send(self(), {:after, :another_task}))

task :bar do
  send(self(), {:task, :bar})
end

task(:another_task, do: send(self(), {:task, :another_task}))

task :foo do
  send(self(), {:task, :foo})
end
