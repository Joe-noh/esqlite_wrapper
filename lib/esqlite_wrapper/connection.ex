defmodule EsqliteWrapper.Connection do
  use GenServer

  def start_link(path) do
    GenServer.start_link(__MODULE__, [path])
  end

  def query(pid, sql) do
    GenServer.call(pid, {:query, sql})
  end

  def query(pid, sql, args) do
    GenServer.call(pid, {:query, sql, args})
  end

  def init([path]) do
    path
    |> String.to_char_list
    |> :esqlite3.open
  end

  def handle_call({:query, sql}, _from, db) do
    result = sql
      |> String.to_char_list
      |> :esqlite3.q(db)

    {:reply, result, db}
  end

  def handle_call({:query, sql, args}, _from, db) do
    result = sql
      |> String.to_char_list
      |> :esqlite3.q(args, db)

    {:reply, result, db}
  end
end
