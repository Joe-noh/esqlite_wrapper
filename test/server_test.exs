defmodule ServerTest do
  use ExUnit.Case
  import TestHelper
  alias Exqlite.Server, as: DB

  setup_all do
    {:ok, pid} = DB.start_link(":memory:")

    create_table pid
    populate_people pid

    on_exit fn -> DB.close(pid) end

    {:ok, [pid: pid]}
  end

  test "query/2 returns {:ok, list_of_maps}", c do
    sql = "SELECT age FROM test ORDER BY age DESC"
    expected = [%{age: 33}, %{age: 28}, %{age: 22}]

    assert {:ok, expected} == DB.query(c.pid, sql)
  end

  test "query/2 returns {:error, message}", c do
    assert {:error, _message} = DB.query(c.pid, "SELECT * FROM aaaa")
  end

  test "error messages from query/2", c do
    {:error, message} = DB.query(c.pid, "SELECT age FROM aaaa")
    assert message =~ ~r/no such table/

    {:error, message} = DB.query(c.pid, "SELECT aaa FROM test")
    assert message =~ ~r/no such column/
  end

  test "query!/2 returns list_of_maps", c do
    sql = "SELECT age FROM test ORDER BY age DESC"
    expected = [%{age: 33}, %{age: 28}, %{age: 22}]

    assert expected == DB.query!(c.pid, sql)
  end

  test "query!/2 raises Exqlite.Error", c do
    assert_raise Exqlite.Error, fn ->
      DB.query!(c.pid, "SELECT * FROM aaaa")
    end
  end

  test "error messages from query!/2", c do
    assert_raise Exqlite.Error, ~r/no such table/, fn ->
      DB.query!(c.pid, "SELECT age FROM aaaa")
    end

    assert_raise Exqlite.Error, ~r/no such column/, fn ->
      DB.query!(c.pid, "SELECT aaa FROM test")
    end
  end

  test "query/3 returns {:ok, results}", c do
    sql = "SELECT name FROM test WHERE name LIKE ?1"
    expected = [%{name: "mary"}, %{name: "alex"}]

    assert {:ok, expected} == DB.query(c.pid, sql, ["%a%"])
  end

  test "query/3 returns {:error, message}", c do
    assert {:error, _message} = DB.query(c.pid, "SELECT * FROM aaaa", [])
  end

  test "next/2 returns {:ok, list_of_maps} and :done at last", c do
    {:ok, prepared} = DB.prepare(c.pid, "SELECT age FROM test")

    Enum.each [%{age: 22}, %{age: 28}, %{age: 33}], fn expected ->
      assert {:ok, expected} == DB.next(c.pid, prepared)
    end
    assert :done == DB.next(c.pid, prepared)
  end

  test "prepare/2 returns {:ok, prepared}", c do
    assert {:ok, _prepared} = DB.prepare(c.pid, "SELECT age FROM test")
  end

  test "prepare/2 returns {:error, message}", c do
    assert {:error, _message} = DB.prepare(c.pid, "SELECT aaa FROM test")
  end

  test "error messages from prepare/2", c do
    {:error, message} = DB.prepare(c.pid, "SELECT age FROM aaaa")
    assert message =~ ~r/no such table/

    {:error, message} = DB.prepare(c.pid, "SELECT aaa FROM test")
    assert message =~ ~r/no such column/
  end

  test "bind/2 returns :ok", c do
    sql = "SELECT COUNT(*) AS count FROM test WHERE age > ?1"
    {:ok, prepared} = DB.prepare(c.pid, sql)

    assert :ok == DB.bind(c.pid, prepared, [25])
    assert {:ok, %{count: 2}} == DB.next(c.pid, prepared)
  end

  test "bind/2 returns {:error, reason}", c do
    sql = "SELECT COUNT(*) AS count FROM test WHERE age > ?1"
    {:ok, prepared} = DB.prepare(c.pid, sql)

    assert {:error, _reason} = DB.bind(c.pid, prepared, [])
    assert {:error, _reason} = DB.bind(c.pid, prepared, [10, 20])
  end

  test "column_names/2 returns {:ok, columns}", c do
    {:ok, prepared} = DB.prepare(c.pid, "SELECT age FROM test")
    assert {:ok, {:age}} == DB.column_names(c.pid, prepared)

    {:ok, prepared} = DB.prepare(c.pid, "SELECT * FROM test")
    assert {:ok, {:name, :age, :height, :face_image}} == DB.column_names(c.pid, prepared)
  end

  test "columns_names/2 returns {:error, message}", c do
    {:ok, prepared} = DB.prepare(c.pid, "DROP TABLE test")
    assert {:error, _message} = DB.column_names(c.pid, prepared)
  end

  test "next/2 returns the first row after reset/2", c do
    {:ok, prepared} = DB.prepare(c.pid, "SELECT name FROM test WHERE name LIKE ?1")
    DB.bind(c.pid, prepared, ["%a%"])
    assert {:ok, %{name: "mary"}} == DB.next(c.pid, prepared)
    assert {:ok, %{name: "alex"}} == DB.next(c.pid, prepared)

    :ok = DB.reset(c.pid, prepared)

    assert {:ok, %{name: "mary"}} == DB.next(c.pid, prepared)
  end

  test "close/1" do
    {:ok, pid} = DB.start_link(":memory:")
    :ok = DB.close(pid)

    catch_exit(DB.query pid, "SELECT * FROM test")
  end
end
