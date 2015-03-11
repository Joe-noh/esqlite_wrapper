defmodule NifTest do
  use ExUnit.Case
  alias Exqlite.Nif

  setup do
    {:ok, db} = Nif.open(':memory:')
    Nif.exec(db, 'create table test (name text)')

    on_exit fn -> Nif.close(db) end

    {:ok, %{db: db}}
  end

  test "exec/2 returns {:ok, result}", c do
    assert {:ok, []} == Nif.exec(c.db, 'insert into test values("bob")')
  end

  test "exec/2 returns {:error, message}", c do
    {:error, message} = Nif.exec(c.db, 'oh this is not SQL!!')
    assert is_list(message)
  end

  test "prepare/2 returns a resource `stmt`", c do
    prepared = Nif.prepare(c.db, 'insert into test values (?1)')
    assert is_binary(prepared)  # nif resource looks like ""
  end

  test "prepare/2 returns {:error, message}", c do
    {:error, message} = Nif.exec(c.db, 'hey you whats up')
    assert is_list(message)
  end

  test "bind/2 returns statement", c do
    prepared = Nif.prepare(c.db, 'insert into test values (?1)')
    assert prepared == Nif.bind(prepared, ['bob'])
  end

  test "step/1 returns {:ok, header_list, value_list}", c do
    Nif.exec(c.db, 'insert into test values("bob")')

    stmt = Nif.prepare(c.db, 'select * from test where name like ?1') |> Nif.bind(['b%'])
    {:ok, headers, values} = Nif.step(stmt)

    assert headers == [:name]
    assert values  == ['bob']
  end
end
