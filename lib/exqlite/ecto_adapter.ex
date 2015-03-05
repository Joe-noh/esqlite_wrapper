defmodule Exqlite.EctoAdapter do
  @behaviour Ecto.Adapter

  defmacro __using__(_) do
  end

  @spec start_link(repo :: Ecto.Repo.t, opts :: Keyword.t) ::
                   {:ok, pid} | :ok | {:error, {:already_started, pid}} | {:error, term}
  def start_link(repo, opts) do
  end

  @spec stop(repo :: Ecto.Repo.t) :: :ok
  def stop(repo) do
  end

  @spec all(repo :: Ecto.Repo.t, query :: Ecto.Query.t,
            params :: list(), opts :: Keyword.t) :: [[term]] | no_return
  def all(repo, query, params, opts) do
  end

  @spec update_all(repo :: Ecto.Repo.t, query :: Ecto.Query.t, updates :: Keyword.t,
                   params :: list(), opts :: Keyword.t) :: integer | no_return
  def update_all(repo, query, updates, params, opts) do
  end

  @spec delete_all(repo :: Ecto.Repo.t, query :: Ecto.Query.t, params :: list(),
                   opts :: Keyword.t) :: integer | no_return
  def delete_all(repo, query, params, opts) do
  end

  @spec insert(repo :: Ecto.Repo.t, source :: binary, fields :: Keyword.t,
               returning :: [atom], opts :: Keyword.t) :: {:ok, Keyword.t} | no_return
  def insert(repo, source, fields, returning, opts) do
  end

  @spec update(repo :: Ecto.Repo.t, source :: binary, fields :: Keyword.t,
               filter :: Keyword.t, returning :: [atom], opts :: Keyword.t) ::
               {:ok, Keyword.t} | {:error, :stale} | no_return
  def update(repo, source, fields, filter, returning, opts) do
  end

  @spec delete(repo :: Ecto.Repo.t, source :: binary, filter :: Keyword.t,
               opts :: Keyword.t) :: {:ok, Keyword.t} | {:error, :stale} | no_return
  def delete(repo, source, filter, opts) do
  end
end
