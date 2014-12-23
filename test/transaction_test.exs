defmodule TransactionTest do
  use ExUnit.Case
  alias EsqliteWrapper.Connection, as: DB

  setup do
    {:ok, pid} = DB.start_link(":memory:")

    TestHelper.create_table pid
    TestHelper.populate_people pid

    on_exit fn -> DB.close(pid) end

    {:ok, [pid: pid]}
  end

  test "transaction and commit manually", context do
    DB.begin(context.pid)
    DB.query(context.pid, "INSERT INTO test VALUES (?1, ?2)", ["beth", 19])
    DB.query(context.pid, "INSERT INTO test VALUES (?1, ?2)", ["jack", 25])
    DB.commit(context.pid)

    assert [{5}] == DB.query(context.pid, "SELECT COUNT(*) FROM test")
  end

  test "transaction and rollback manually", context do
    DB.begin(context.pid)
    DB.query(context.pid, "INSERT INTO test VALUES (?1, ?2)", ["beth", 19])
    DB.query(context.pid, "INSERT INTO test VALUES (?1, ?2)", ["jack", 25])
    DB.rollback(context.pid)

    assert [{3}] == DB.query(context.pid, "SELECT COUNT(*) FROM test")
  end

  test "transaction returns {:ok, fun.()}", context do
    result = DB.transaction context.pid, fn -> :return_value end
    assert result == {:ok, :return_value}
  end

  test "success transaction/2", context do
    DB.transaction context.pid, fn ->
      DB.query(context.pid, "INSERT INTO test VALUES (?1, ?2)", ["beth", 19])
      DB.query(context.pid, "INSERT INTO test VALUES (?1, ?2)", ["jack", 25])
    end

    assert [{5}] == DB.query(context.pid, "SELECT COUNT(*) FROM test")
  end

  test "failed transaction/2", context do
    result = DB.transaction context.pid, fn ->
      DB.query(context.pid, "INSERT INTO test VALUES (?1, ?2)", ["beth", 19])
      DB.query(context.pid, "INSERT INTO test VALUES (?1, ?2)", ["jack", 25])
      raise RuntimeError, message: "oops"
    end

    assert {:error, %RuntimeError{}} = result
    assert [{3}] == DB.query(context.pid, "SELECT COUNT(*) FROM test")
  end

  test "nested transaction", context do
    pid = context.pid

    DB.transaction pid, fn ->
      DB.query(pid, "INSERT INTO test VALUES (?1, ?2)", ["beth", 19])
      DB.transaction pid, fn ->
        DB.query(pid, "INSERT INTO test VALUES (?1, ?2)", ["jack", 25])
        raise "Oops"
      end
    end

    assert [{1}] == DB.query(pid, "SELECT COUNT(*) FROM test WHERE name = 'beth'")
    assert [{0}] == DB.query(pid, "SELECT COUNT(*) FROM test WHERE name = 'jack'")
  end

  test "deeply nested transaction", context do
    pid = context.pid

    DB.transaction pid, fn ->
      DB.query(pid, "INSERT INTO test VALUES ('beth', 19)")
      DB.transaction pid, fn ->
        DB.transaction pid, fn ->
          DB.query(pid, "INSERT INTO test VALUES ('jack', 25)")
        end
        DB.query(pid, "INSERT INTO test VALUES ('nick', 29)")
        raise "Oops"
      end
      DB.query(pid, "INSERT INTO test VALUES ('anne', 30)")
    end

    assert [{1}] == DB.query(pid, "SELECT COUNT(*) FROM test WHERE name = 'beth'")
    assert [{0}] == DB.query(pid, "SELECT COUNT(*) FROM test WHERE name = 'jack'")
    assert [{0}] == DB.query(pid, "SELECT COUNT(*) FROM test WHERE name = 'nick'")
    assert [{1}] == DB.query(pid, "SELECT COUNT(*) FROM test WHERE name = 'anne'")
  end
end
