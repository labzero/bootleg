defmodule Bootleg.Mocks do
  
  defmodule SSH do
    @mocks Bootleg.SSH

    def start do 
      send(self(), {@mocks, :start})
      :ok
    end  

    def connect(host, user, identity) do 
      send(self(), {@mocks, :connect, [host, user, identity]})
      :conn
    end    

    def run(conn, cmd, wd \\ ".") do 
      send(self(), {@mocks, :run, [conn, cmd, wd]})
      :conn
    end
    
    def run!(conn, cmd, wd \\ ".") do
      send(self(), {@mocks, :"run!", [conn, cmd, wd]})
      :conn
    end

    def upload(conn, local, remote, options \\ []) do
      send(self(), {@mocks, :upload, [conn, local, remote, options]})      
      :ok
    end

    def download(conn, local, remote, options \\ []) do
      send(self(), {@mocks, :download, [conn, local, remote, options]})      
      :ok            
    end
    
  end

  defmodule Git do
    @mocks Bootleg.Git

    def remote(args, options \\ []) do 
      send(self(), {@mocks, :remote, [args, options]})
      :ok    
    end

    def push(args, options \\ []) do
      send(self(), {@mocks, :push, [args, options]})      
      {"", 0}
    end    
  end

  defmodule Shell do
    @mocks Bootleg.Shell

    def run(cmd, args, opts \\ []) do
      send(self(), {@mocks, :run, [cmd, args, opts]})
      :ok
    end
  end

end