defmodule EsqliteWrapper.Connection do
  use GenServer

  def start_link(path) do
    GenServer.start_link(__MODULE__, [path])
  end

  @spec query(pid, String.t) :: [tuple]
  def query(pid, sql) do
    GenServer.call(pid, {:query, sql})
  end

  @spec query(pid, String.t, [any]) :: [tuple]
  def query(pid, sql, args) do
    GenServer.call(pid, {:query, sql, args})
  end

  @spec execute(pid, String.t) :: :ok | {:error, any}
  def execute(pid, sql) do
    GenServer.call(pid, {:execute, sql})
  end

  @spec execute(pid, String.t, [any]) :: :ok | {:error, any}
  def execute(pid, sql, args) do
    GenServer.call(pid, {:execute, sql, args})
  end

  @spec prepare(pid, String.t) :: {:ok, String.t} | {:error, any}
  def prepare(pid, sql) do
    GenServer.call(pid, {:prepare, sql})
  end

  @spec step(pid, String.t) :: tuple
  def step(pid, prepared) do
    GenServer.call(pid, {:step, prepared})
  end

  @spec bind(pid, String.t, [any]) :: :ok | {:error, any}
  def bind(pid, prepared, params) do
    GenServer.call(pid, {:bind, prepared, params})
  end

  @spec transaction(pid, (() -> any)) :: {:ok, any} | {:error, any}
  def transaction(pid, fun) do
    case begin(pid) do
      :ok -> try_then_commit(pid, fun)
      {:error, {type, msg}} -> :erlang.raise(type, msg, System.stacktrace)
    end
  end

  @doc false
  @spec try_then_commit(pid, (() -> any)) :: {:ok, any} | {:error, any}
  defp try_then_commit(pid, fun) do
    try do
      result = fun.()
      case commit(pid) do
        :ok -> {:ok, result}
        {:error, {type, msg}} -> :erlang.raise(type, msg, System.stacktrace)
      end
    rescue
      e -> rollback(pid); {:error, e}
    end
  end

  @spec begin(pid) :: :ok | {:error, any}
  def begin(pid) do
    GenServer.call(pid, {:execute, "BEGIN"})
  end

  @spec commit(pid) :: :ok | {:error, any}
  def commit(pid) do
    GenServer.call(pid, {:execute, "COMMIT"})
  end

  @spec rollback(pid) :: :ok | {:error, any}
  def rollback(pid) do
    GenServer.call(pid, {:execute, "ROLLBACK"})
  end

  @spec column_names(pid, String.t) :: {:atom}
  def column_names(pid, prepared) do
    GenServer.call(pid, {:column_names, prepared})
  end

  @spec close(pid) :: :ok | {:error, any}
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

  def handle_call({:execute, sql}, _from, db) do
    result = String.to_char_list(sql) |> :esqlite3.exec(db)

    {:reply, result, db}
  end

  def handle_call({:execute, sql, args}, _from, db) do
    result = String.to_char_list(sql) |> :esqlite3.exec(args, db)

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
