defmodule TransactionTest do
  use ExUnit.Case
  import TestHelper
  alias Exqlite.Server, as: DB

  setup do
    {:ok, pid} = DB.start_link(":memory:")

    create_table pid
    populate_people pid

    on_exit fn -> DB.close(pid) end

    {:ok, [pid: pid]}
  end

  @insert_sql "INSERT INTO test (name, age) VALUES (?1, ?2)"

  @beth ["beth", 19]
  @jack ["jack", 25]
  @nick ["nick", 29]
  @anne ["anne", 30]

  test "transaction and commit manually", c do
    DB.begin(c.pid)
    DB.execute(c.pid, @insert_sql, @beth)
    DB.execute(c.pid, @insert_sql, @jack)
    DB.commit(c.pid)

    assert 5 == count_all(c.pid)
  end

  test "transaction and rollback manually", c do
    DB.begin(c.pid)
    DB.execute(c.pid, @insert_sql, @beth)
    DB.execute(c.pid, @insert_sql, @jack)
    DB.rollback(c.pid)

    assert 3 == count_all(c.pid)
  end

  test "transaction returns {:ok, fun.()}", c do
    result = DB.transaction c.pid, fn -> :return_value end
    assert result == {:ok, :return_value}
  end

  test "success transaction/2", c do
    DB.transaction c.pid, fn ->
      DB.execute(c.pid, @insert_sql, @beth)
      DB.execute(c.pid, @insert_sql, @jack)
    end

    assert 5 == count_all(c.pid)
  end

  test "failed transaction/2", c do
    result = DB.transaction c.pid, fn ->
      DB.execute(c.pid, @insert_sql, @beth)
      DB.execute(c.pid, @insert_sql, @jack)
      raise RuntimeError, message: "Oops"
    end

    assert {:error, %RuntimeError{}} = result
    assert 3 == count_all(c.pid)
  end

  test "nested transaction", c do
    DB.transaction c.pid, fn ->
      DB.execute(c.pid, @insert_sql, @beth)
      DB.transaction c.pid, fn ->
        DB.execute(c.pid, @insert_sql, @jack)
        raise "Oops"
      end
    end

    assert saved?(c.pid, @beth)
    refute saved?(c.pid, @jack)
  end

  test "deeply nested transaction", c do
    DB.transaction c.pid, fn ->
      DB.execute(c.pid, @insert_sql, @beth)
      DB.transaction c.pid, fn ->
        DB.transaction c.pid, fn -> DB.execute(c.pid, @insert_sql, @jack) end
        DB.execute(c.pid, @insert_sql, @nick)
        raise "Oops"
      end
      DB.execute(c.pid, @insert_sql, @anne)
    end

    assert saved?(c.pid, @beth)
    refute saved?(c.pid, @jack)
    refute saved?(c.pid, @nick)
    assert saved?(c.pid, @anne)
  end

  test "create table can be rolled-back", c do
    DB.transaction c.pid, fn ->
      DB.execute(c.pid, "CREATE TABLE test2 (name TEXT)")
      raise "Oops"
    end

    assert_raise Exqlite.Error, ~r/no such table: test2/, fn ->
      DB.query!(c.pid, "SELECT * FROM test2")
    end
  end

  test "drop table can be rolled-back", c do
    DB.transaction c.pid, fn ->
      DB.transaction c.pid, fn ->
        DB.execute("DROP TABLE test")
        raise "Oops"
      end
    end

    assert 3 == count_all(c.pid)  # confirm that the table 'test' still alive
  end

  test "alter table can be rolled-back", c do
    DB.transaction c.pid, fn ->
      DB.transaction c.pid, fn ->
        DB.execute("ALTER TABLE test RENAME TO aaaa")
        raise "Oops"
      end
    end

    assert_raise Exqlite.Error, ~r/no such table: aaaa/, fn ->
      DB.query!(c.pid, "SELECT * FROM aaaa")
    end
  end
end
