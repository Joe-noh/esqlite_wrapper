ExUnit.start

defmodule TestHelper do
  alias Exqlite.Server, as: DB

  @people [
    {"bob",  22, 180.5, <<1, 2, 3, 4, 5>>},
    {"mary", 28, 169.1, <<6, 7, 8, 9, 0>>},
    {"alex", 33, 172.3, <<5, 4, 3, 2, 1>>}
  ]

  def create_table(pid) do
    DB.execute(pid, """
    CREATE TABLE IF NOT EXISTS
      test (name TEXT, age INTEGER, height REAL, face_image BLOB)
    """)
  end

  def populate_people(pid) do
    Enum.each @people, fn {name, age, height, face} ->
      DB.execute(pid, "INSERT INTO test VALUES (?1, ?2, ?3, ?4)", [name, age, height, face])
    end
  end

  def count_all(pid) do
    [%{count: count}] = DB.query!(pid, "SELECT COUNT(*) as count FROM test")
    count
  end

  def saved?(pid, params) when is_list(params) do
    sql = "SELECT COUNT(*) as count FROM test WHERE name = ?1 AND age = ?2"
    [%{count: 1}] == DB.query!(pid, sql, params)
  end
end
