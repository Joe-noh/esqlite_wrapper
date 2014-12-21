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

  def prepare(pid, sql) do
    GenServer.call(pid, {:prepare, sql})
  end

  def step(pid, prepared) do
    GenServer.call(pid, {:step, prepared})
  end

  def bind(pid, prepared, params) do
    GenServer.call(pid, {:bind, prepared, params})
  end

  def column_names(pid, prepared) do
    GenServer.call(pid, {:column_names, prepared})
  end

  def close(pid) do
    GenServer.cast(pid, :close)
  end


  ## GenServer callbacks

  def init([path]) do
    String.to_char_list(path) |> :esqlite3.open
  end

  def handle_call({:query, sql}, _from, db) do
    result = String.to_char_list(sql) |> :esqlite3.q(db)

    {:reply, result, db}
  end

  def handle_call({:query, sql, args}, _from, db) do
    result = String.to_char_list(sql) |> :esqlite3.q(args, db)

    {:reply, result, db}
  end

  def handle_call({:prepare, sql}, _from, db) do
    {:ok, prepared} = String.to_char_list(sql) |> :esqlite3.prepare(db)

    {:reply, prepared, db}
  end

  def handle_call({:step, prepared}, _from, db) do
    {:reply, :esqlite3.step(prepared), db}
  end

  def handle_call({:bind, prepared, params}, _from, db) do
    {:reply, :esqlite3.bind(prepared, params), db}
  end

  def handle_call({:column_names, prepared}, _from, db) do
    {:reply, :esqlite3.column_names(prepared), db}
  end

  def handle_cast(:close, db) do
    {:stop, :normal, db}
  end

  def terminate(_reason, db) do
    :esqlite3.close(db)
  end
end
