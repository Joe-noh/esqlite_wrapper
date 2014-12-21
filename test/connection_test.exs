defmodule ConnectionTest do
  use ExUnit.Case
  alias EsqliteWrapper.Connection, as: DB

  setup do
    {:ok, pid} = DB.start_link(":memory:")

    TestHelper.create_table pid
    TestHelper.populate_people pid

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
end
