ExUnit.start

defmodule TestHelper do
  alias EsqliteWrapper.Connection, as: DB

  @create_table "CREATE TABLE test (name TEXT, age INTEGER)"
  @people [
    {"bob",  22},
    {"mary", 28},
    {"alex", 33}
  ]

  def create_table(pid) do
    DB.query pid, @create_table
  end

  def populate_people(pid) do
    Enum.each @people, fn {name, age} ->
      DB.query(pid, "INSERT INTO test VALUES (?1, ?2)", [name, age])
    end
  end
end
