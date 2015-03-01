defmodule Exqlite.Server do
  use GenServer
  alias Exqlite.Esqlite

  @spec start_link(String.t) :: {:ok, pid} | {:error, any}
  def start_link(path) do
    GenServer.start_link(__MODULE__, [path])
  end

  @spec query(pid, String.t) :: [map]
  def query(pid, sql) do
    do_query pid, sql, GenServer.call(pid, {:query, sql})
  end

  @spec query(pid, String.t, [any]) :: [map]
  def query(pid, sql, args) do
    do_query pid, sql, GenServer.call(pid, {:query, sql, args})
  end

  defp do_query(pid, sql, result) do
    prepared = GenServer.call(pid, {:prepare, sql})
    columns  = GenServer.call(pid, {:column_names, prepared})

    case {columns, result} do
      {{:error, _}, _} -> result
      _other -> build_map(columns, result)
    end
  end

  defp build_map(columns, rows) when is_tuple(columns) and is_list(rows) do
    build_map Tuple.to_list(columns), Enum.map(rows, &Tuple.to_list/1)
  end

  defp build_map(columns, rows) when is_tuple(columns) and is_tuple(rows) do
    build_map Tuple.to_list(columns), [Tuple.to_list(rows)]
  end

  defp build_map(columns, rows) when is_list(columns) and is_list(rows) do
    for row <- rows do
      for k_v <- Enum.zip(columns, row), into: %{}, do: k_v
    end
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

  @spec next(pid, String.t) :: :done | tuple | {:error, any}
  def next(pid, prepared) do
    columns = GenServer.call(pid, {:column_names, prepared})
    result = GenServer.call(pid, {:next, prepared})

    case result do
      :done  -> :done
      result -> build_map(columns, result) |> List.first
    end
  end

  @spec reset(pid, String.t) :: :ok | {:error, any}
  def reset(pid, prepared) do
    GenServer.call(pid, {:reset, prepared})
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
    GenServer.call(pid, :begin)
  end

  @spec commit(pid) :: :ok | {:error, any}
  def commit(pid) do
    GenServer.call(pid, :commit)
  end

  @spec rollback(pid) :: :ok | {:error, any}
  def rollback(pid) do
    GenServer.call(pid, :rollback)
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
    {:ok, db} = Esqlite.open(path)
    {:ok, %{db: db, level: 0}}
  end

  def handle_call({:query, sql}, _from, %{db: db} = state) do
    {:reply, Esqlite.query(db, sql), state}
  end

  def handle_call({:query, sql, args}, _from, %{db: db} = state) do
    {:reply, Esqlite.query(db, sql, args), state}
  end

  def handle_call({:execute, sql}, _from, %{db: db} = state) do
    {:reply, Esqlite.exec(db, sql), state}
  end

  def handle_call({:execute, sql, args}, _from, %{db: db} = state) do
    {:reply, Esqlite.exec(db, sql, args), state}
  end

  def handle_call({:prepare, sql}, _from, %{db: db} = state) do
    {:ok, prepared} = Esqlite.prepare(db, sql)
    {:reply, prepared, state}
  end

  def handle_call({:next, prepared}, _from, state) do
    {:reply, Esqlite.step(prepared), state}
  end

  def handle_call({:reset, prepared}, _from, state) do
    {:reply, Esqlite.reset(prepared), state}
  end

  def handle_call({:bind, prepared, params}, _from, state) do
    {:reply, Esqlite.bind(prepared, params), state}
  end

  def handle_call(:begin, _from, %{db: db, level: 0} = state) do
    {:reply, Esqlite.exec(db, 'BEGIN;'), %{state | level: 1}}
  end

  def handle_call(:begin, _from, %{db: db, level: n} = state) do
    {:reply, Esqlite.exec(db, 'SAVEPOINT S#{n};'), %{state | level: n+1}}
  end

  def handle_call(:commit, _from, %{db: db, level: 1} = state) do
    {:reply, Esqlite.exec(db, 'COMMIT;'), %{state | level: 0}}
  end

  def handle_call(:commit, _from, %{db: db, level: n} = state) do
    {:reply, Esqlite.exec(db, 'RELEASE S#{n}'), %{state | level: n-1}}
  end

  def handle_call(:rollback, _from, %{db: db, level: 1} = state) do
    {:reply, Esqlite.exec(db, 'ROLLBACK;'), %{state | level: 0}}
  end

  def handle_call(:rollback, _from, %{db: db, level: n} = state) do
    {:reply, Esqlite.exec(db, 'ROLLBACK TO SAVEPOINT S#{n-1};'), %{state | level: n-1}}
  end

  def handle_call({:column_names, prepared}, _from, state) do
    {:reply, Esqlite.column_names(prepared), state}
  end

  def handle_cast(:close, state) do
    {:stop, :normal, state}
  end

  def terminate(_reason, %{db: db}) do
    Esqlite.close(db)
  end
end
