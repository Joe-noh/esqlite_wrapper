defmodule NifTypeTest do
  use ExUnit.Case
  alias Exqlite.Nif

  setup do
    {:ok, db} = Nif.open(':memory:')

    on_exit fn -> Nif.close(db) end

    {:ok, %{db: db}}
  end

  test "store and fetch text", c do
    Nif.exec(c.db, 'create table for_text (col text)')

    Nif.prepare(c.db, 'insert into for_text values (?1)')
    |> Nif.bind(['text'])
    |> Nif.exec

    {:ok, [row]} = Nif.exec(c.db, 'select * from for_text')
    assert row == %{col: 'text'}
  end

  test "store and fetch blob", c do
    Nif.exec(c.db, 'create table for_blob (col blob)')

    Nif.prepare(c.db, 'insert into for_blob values (?1)')
    |> Nif.bind([<<?b, ?l, ?o, ?b>>])
    |> Nif.exec

    {:ok, [row]} = Nif.exec(c.db, 'select * from for_blob')
    assert row == %{col: <<?b, ?l, ?o, ?b>>}
  end

  test "store and fetch integer", c do
    Nif.exec(c.db, 'create table for_integer (col integer)')

    Nif.prepare(c.db, 'insert into for_integer values (?1)')
    |> Nif.bind([256])
    |> Nif.exec

    {:ok, [row]} = Nif.exec(c.db, 'select * from for_integer')
    assert row == %{col: 256}
  end

  test "store and fetch float", c do
    Nif.exec(c.db, 'create table for_float (col float)')

    Nif.prepare(c.db, 'insert into for_float values (?1)')
    |> Nif.bind([3.14])
    |> Nif.exec

    {:ok, [row]} = Nif.exec(c.db, 'select * from for_float')
    assert row == %{col: 3.14}
  end
end
