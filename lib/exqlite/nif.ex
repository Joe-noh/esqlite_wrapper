defmodule Exqlite.Nif do
  @moduledoc ~S"""
  This module provides the interface between Elixir and C.

  * Loading NIF.
  * Checking type of arguments.
  * Transforming data type, such as `String.t <-> char_list`.
  """

  @on_load {:init, 0}

  @type statement :: String.t
  @type database :: String.t

  def init do
    :erlang.load_nif('priv/exqlite', 0)
  end

  defmacrop bye do
    quote do: exit(:nif_not_loaded)
  end

  # NIFs

  def open(_path),        do: bye
  def close(_db),         do: bye
  def prepare(_db, _sql), do: bye
  def step(_stmt),        do: bye

  def bind_text(_stmt, _index, _value), do: bye
  def bind_blob(_stmt, _index, _value), do: bye
  def bind_int(_stmt, _index, _value), do: bye
  def bind_float(_stmt, _index, _value), do: bye

  @spec exec(statement) :: {:ok, [map]} | {:error, term}
  def exec(stmt),    do: do_exec(stmt, [])

  @spec exec(database, char_list) :: {:ok, [map]} | {:error, term}
  def exec(db, sql), do: prepare(db, sql) |> do_exec([])

  defp do_exec(stmt, acc) do
    case step(stmt) do
      :ok -> {:ok, []}
      {:ok, header, row} -> do_exec(stmt, [build_row(header, row) | acc])
      :done -> {:ok, Enum.reverse(acc)}
      :busy ->
        :timer.sleep(100)
        do_exec(stmt, acc)
      e = {:error, _} -> e
    end
  end

  defp build_row(header, row), do: Enum.zip(header, row) |> Enum.into %{}

  @spec bind(statement, [char_list | bitstring | number]) :: statement | no_return
  def bind(stmt, values) do
    bind(stmt, values, 1)
  end

  defp bind(stmt, [], _index), do: stmt

  defp bind(stmt, [head | rest], index) do
    do_bind(stmt, head, index)
    bind(stmt, rest, index+1)
  end

  defp do_bind(stmt, value, index) when is_list(value) do
    bind_text(stmt, value, index)
  end

  defp do_bind(stmt, value, index) when is_binary(value) do
    bind_blob(stmt, value, index)
  end

  defp do_bind(stmt, value, index) when is_integer(value) do
    bind_int(stmt, value, index)
  end

  defp do_bind(stmt, value, index) when is_float(value) do
    bind_float(stmt, value, index)
  end
end
