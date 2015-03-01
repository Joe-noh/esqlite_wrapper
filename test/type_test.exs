defmodule TypeTest do
  use ExUnit.Case
  import TestHelper
  alias Exqlite.Server, as: DB

  setup_all do
    {:ok, pid} = DB.start_link(":memory:")

    create_table pid
    populate_people pid

    row = DB.query(pid, "SELECT * FROM test LIMIT 1") |> List.first

    on_exit fn -> DB.close(pid) end

    {:ok, [row: row]}
  end

  test "integer", c do
    assert is_integer(c.row.age)
  end

  test "text", c do
    assert is_binary(c.row.name)
  end

  test "float", c do
    assert is_float(c.row.height)
  end

  test "blob", c do
    assert is_binary(c.row.face_image)
  end
end
