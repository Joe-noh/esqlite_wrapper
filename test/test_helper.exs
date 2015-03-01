ExUnit.start

defmodule TestHelper do
  alias Exqlite.Server, as: DB

  @people [
    {"bob",  22},
    {"mary", 28},
    {"alex", 33}
  ]

  def create_table(pid) do
    DB.execute(pid, "CREATE TABLE IF NOT EXISTS test (name TEXT, age INTEGER)")
  end

  def populate_people(pid) do
    Enum.each @people, fn {name, age} ->
      DB.execute(pid, "INSERT INTO test VALUES (?1, ?2)", [name, age])
    end
  end

  def count_all(pid) do
    [%{count: count}] = DB.query(pid, "SELECT COUNT(*) as count FROM test")
    count
  end

  def saved?(pid, params) when is_list(params) do
    sql = "SELECT COUNT(*) as count FROM test WHERE name = ?1 AND age = ?2"
    [%{count: 1}] == DB.query(pid, sql, params)
  end
end
