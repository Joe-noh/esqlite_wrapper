defmodule Exqlite.Esqlite do
  def open(path) do
    to_chars(path) |> :esqlite3.open
  end

  def close(db) do
    :esqlite3.close(db)
  end

  def exec(db, sql) do
    to_chars(sql) |> :esqlite3.exec(db)
  end

  def exec(db, sql, params) do
    to_chars(sql) |> :esqlite3.exec(params, db)
  end

  def query(db, sql) do
    query(db, sql, [])
  end

  def query(db, sql, params) do
    case prepare(db, sql) do
      {:ok, prepared} ->
        :ok = :esqlite3.bind(prepared, params)
        fetch_all(prepared)
      error -> error
    end
  end

  def prepare(db, sql) do
    to_chars(sql) |> :esqlite3.prepare(db)
  end

  def step(prepared) do
    case :esqlite3.step(prepared) do
      :'$busy' -> :busy
      :'$done' -> :done
      {:row, row} -> row
    end
  end

  def bind(prepared, params) do
    :esqlite3.bind(prepared, params)
  end

  def reset(prepared) do
    :esqlite3.reset(prepared)
  end

  def column_names(prepared) do
    :esqlite3.column_names(prepared)
  end

  defp fetch_all(prepared) do
    fetch_all(prepared, [])
  end

  defp fetch_all(prepared, acc) do
    case try_step(prepared, 0) do
      :'$done' -> Enum.reverse acc
      {:row, row} -> fetch_all(prepared, [row | acc])
      error -> error
    end
  end

  defp try_step(_prepared, tries) when tries > 5 do
    throw :too_many_tries
  end

  defp try_step(prepared, tries) do
    case :esqlite3.step(prepared) do
      :'$busy' ->
        :timer.sleep(100 * tries)
        try_step(prepared, tries+1)
      other -> other
    end
  end

  defp to_chars(obj) when is_list(obj),   do: obj
  defp to_chars(obj) when is_binary(obj), do: String.to_char_list(obj)
end
