defmodule ConnectionTest do
  use ExUnit.Case
  import TestHelper
  alias Exqlite.Connection, as: DB

  setup do
    {:ok, pid} = DB.start_link(":memory:")

    create_table pid
    populate_people pid

    on_exit fn -> DB.close(pid) end

    {:ok, [pid: pid]}
  end

  test "query/2", c do
    sql = "SELECT age FROM test ORDER BY age DESC"
    expected = [{33}, {28}, {22}]

    assert expected == DB.query(c.pid, sql)
  end

  test "query/3", c do
    sql = "SELECT name FROM test WHERE name LIKE ?1"
    expected = [{"mary"}, {"alex"}]

    assert expected == DB.query(c.pid, sql, ["%a%"])
  end

  test "prepare/2 and next/2", c do
    prepared = DB.prepare(c.pid, "SELECT age FROM test")

    Enum.each [{22}, {28}, {33}, :done], fn expected ->
      assert expected == DB.next(c.pid, prepared)
    end
  end

  test "prepare/2 and bind/2", c do
    sql = "SELECT age FROM test WHERE age > ?1"
    prepared = DB.prepare(c.pid, sql)

    DB.bind(c.pid, prepared, [25])
    Enum.each [{28}, {33}, :done], fn expected ->
      assert expected == DB.next(c.pid, prepared)
    end
  end

  test "prepare/2 and column_names/2", c do
    prepared = DB.prepare(c.pid, "SELECT age FROM test")
    assert {:age} == DB.column_names(c.pid, prepared)

    prepared = DB.prepare(c.pid, "SELECT * FROM test")
    assert {:name, :age} == DB.column_names(c.pid, prepared)
  end

  test "prepare/2 and reset/2", c do
    prepared = DB.prepare(c.pid, "SELECT name FROM test WHERE name LIKE ?1")
    DB.bind(c.pid, prepared, ["%a%"])
    assert {"mary"} == DB.next(c.pid, prepared)
    assert {"alex"} == DB.next(c.pid, prepared)

    DB.reset(c.pid, prepared)

    assert {"mary"} == DB.next(c.pid, prepared)
  end

  test "close/1", c do
    DB.close(c.pid)

    catch_exit(DB.query c.pid, "SELECT * FROM test")
  end
end
