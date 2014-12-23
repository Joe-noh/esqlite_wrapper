defmodule TransactionTest do
  use ExUnit.Case
  use TestHelper

  setup do
    {:ok, p} = DB.start_link(":memory:")

    create_table p
    populate_people p

    on_exit fn -> DB.close(p) end

    {:ok, [pid: p]}
  end

  @insert_sql "INSERT INTO test VALUES (?1, ?2)"

  @beth ["beth", 19]
  @jack ["jack", 25]
  @nick ["nick", 29]
  @anne ["anne", 30]

  test "transaction and commit manually", context do
    DB.begin(pid)
    DB.query(pid, @insert_sql, @beth)
    DB.query(pid, @insert_sql, @jack)
    DB.commit(pid)

    assert 5 == count_all(pid)
  end

  test "transaction and rollback manually", context do
    DB.begin(pid)
    DB.query(pid, @insert_sql, @beth)
    DB.query(pid, @insert_sql, @jack)
    DB.rollback(pid)

    assert 3 == count_all(pid)
  end

  test "transaction returns {:ok, fun.()}", context do
    result = DB.transaction pid, fn -> :return_value end
    assert result == {:ok, :return_value}
  end

  test "success transaction/2", context do
    DB.transaction pid, fn ->
      DB.query(pid, @insert_sql, @beth)
      DB.query(pid, @insert_sql, @jack)
    end

    assert 5 == count_all(pid)
  end

  test "failed transaction/2", context do
    result = DB.transaction pid, fn ->
      DB.query(pid, @insert_sql, @beth)
      DB.query(pid, @insert_sql, @jack)
      raise RuntimeError, message: "Oops"
    end

    assert {:error, %RuntimeError{}} = result
    assert 3 == count_all(pid)
  end

  test "nested transaction", context do
    DB.transaction pid, fn ->
      DB.query(pid, @insert_sql, @beth)
      DB.transaction pid, fn ->
        DB.query(pid, @insert_sql, @jack)
        raise "Oops"
      end
    end

    assert saved?(pid, @beth)
    refute saved?(pid, @jack)
  end

  test "deeply nested transaction", context do
    DB.transaction pid, fn ->
      DB.query(pid, @insert_sql, @beth)
      DB.transaction pid, fn ->
        DB.transaction pid, fn -> DB.query(pid, @insert_sql, @jack) end
        DB.query(pid, @insert_sql, @nick)
        raise "Oops"
      end
      DB.query(pid, @insert_sql, @anne)
    end

    assert saved?(pid, @beth)
    refute saved?(pid, @jack)
    refute saved?(pid, @nick)
    assert saved?(pid, @anne)
  end
end
