defmodule ConnectionTest do
  use ExUnit.Case
  alias EsqliteWrapper.Connection, as: DB

  setup do
    {:ok, pid} = DB.start_link(":memory:")

    TestHelper.create_table pid
    TestHelper.populate_people pid

    on_exit fn -> DB.close(pid) end

    {:ok, [pid: pid]}
  end

  test "query/2", context do
    sql = "SELECT age FROM test ORDER BY age DESC"
    expected = [{33}, {28}, {22}]

    assert expected == DB.query(context.pid, sql)
  end

  test "query/3", context do
    sql = "SELECT name FROM test WHERE name LIKE ?1"
    expected = [{"mary"}, {"alex"}]

    assert expected == DB.query(context.pid, sql, ["%a%"])
  end

  test "prepare/2 and step/2", context do
    prepared = DB.prepare(context.pid, "SELECT age FROM test")

    assert {:row, {22}} == DB.step(context.pid, prepared)
    assert {:row, {28}} == DB.step(context.pid, prepared)
    assert {:row, {33}} == DB.step(context.pid, prepared)
    assert :done        == DB.step(context.pid, prepared)
  end

  test "prepare/2 and bind/2", context do
    sql = "SELECT age FROM test WHERE age > ?1"
    prepared = DB.prepare(context.pid, sql)

    DB.bind(context.pid, prepared, [25])
    assert {:row, {28}} == DB.step(context.pid, prepared)
    assert {:row, {33}} == DB.step(context.pid, prepared)
    assert :done        == DB.step(context.pid, prepared)
  end

  test "prepare/2 and column_names/2", context do
    prepared = DB.prepare(context.pid, "SELECT age FROM test")
    assert {:age} == DB.column_names(context.pid, prepared)

    prepared = DB.prepare(context.pid, "SELECT * FROM test")
    assert {:name, :age} == DB.column_names(context.pid, prepared)
  end

  test "prepare/2 and reset/2", context do
    prepared = DB.prepare(context.pid, "SELECT name FROM test WHERE name LIKE ?1")
    DB.bind(context.pid, prepared, ["%a%"])
    assert {:row, {"mary"}} == DB.step(context.pid, prepared)
    assert {:row, {"alex"}} == DB.step(context.pid, prepared)

    DB.reset(context.pid, prepared)

    assert {:row, {"mary"}} == DB.step(context.pid, prepared)
  end

  test "close/1", context do
    DB.close(context.pid)

    catch_exit(DB.query context.pid, "SELECT * FROM test")
  end
end
