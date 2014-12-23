ExUnit.start

defmodule TestHelper do
  alias EsqliteWrapper.Connection, as: DB

  @people [
    {"bob",  22},
    {"mary", 28},
    {"alex", 33}
  ]

  defmacro __using__([]) do
    quote do
      import TestHelper
      alias EsqliteWrapper.Connection, as: DB
    end
  end

  defmacro pid do
    quote do: var!(context).pid
  end

  def create_table(pid) do
    DB.query pid, "CREATE TABLE test (name TEXT, age INTEGER)"
  end

  def populate_people(pid) do
    Enum.each @people, fn {name, age} ->
      DB.query(pid, "INSERT INTO test VALUES (?1, ?2)", [name, age])
    end
  end

  def count_all(pid) do
    [{count}] = DB.query(pid, "SELECT COUNT(*) FROM test")
    count
  end

  def saved?(pid, params) when is_list(params) do
    sql = "SELECT COUNT(*) FROM test WHERE name = ?1 AND age = ?2"
    [{1}] == DB.query(pid, sql, params)
  end
end
