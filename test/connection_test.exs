defmodule ConnectionTest do
  use ExUnit.Case
  use TestHelper

  setup do
    {:ok, p} = DB.start_link(":memory:")

    TestHelper.create_table p
    TestHelper.populate_people p

    on_exit fn -> DB.close(p) end

    {:ok, [pid: p]}
  end

  test "query/2", context do
    sql = "SELECT age FROM test ORDER BY age DESC"
    expected = [{33}, {28}, {22}]

    assert expected == DB.query(pid, sql)
  end

  test "query/3", context do
    sql = "SELECT name FROM test WHERE name LIKE ?1"
    expected = [{"mary"}, {"alex"}]

    assert expected == DB.query(pid, sql, ["%a%"])
  end

  test "prepare/2 and next/2", context do
    prepared = DB.prepare(pid, "SELECT age FROM test")

    assert {22} == DB.next(pid, prepared)
    assert {28} == DB.next(pid, prepared)
    assert {33} == DB.next(pid, prepared)
    assert :done == DB.next(pid, prepared)
  end

  test "prepare/2 and bind/2", context do
    sql = "SELECT age FROM test WHERE age > ?1"
    prepared = DB.prepare(pid, sql)

    DB.bind(pid, prepared, [25])
    assert {28} == DB.next(pid, prepared)
    assert {33} == DB.next(pid, prepared)
    assert :done == DB.next(pid, prepared)
  end

  test "prepare/2 and column_names/2", context do
    prepared = DB.prepare(pid, "SELECT age FROM test")
    assert {:age} == DB.column_names(pid, prepared)

    prepared = DB.prepare(pid, "SELECT * FROM test")
    assert {:name, :age} == DB.column_names(pid, prepared)
  end

  test "prepare/2 and reset/2", context do
    prepared = DB.prepare(pid, "SELECT name FROM test WHERE name LIKE ?1")
    DB.bind(pid, prepared, ["%a%"])
    assert {"mary"} == DB.next(pid, prepared)
    assert {"alex"} == DB.next(pid, prepared)

    DB.reset(pid, prepared)

    assert {"mary"} == DB.next(pid, prepared)
  end

  test "close/1", context do
    DB.close(pid)

    catch_exit(DB.query pid, "SELECT * FROM test")
  end
end
