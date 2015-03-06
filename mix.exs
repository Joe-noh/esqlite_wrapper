defmodule Exqlite.Mixfile do
  use Mix.Project

  def project do
    [app: :exqlite,
     version: "0.2.0",
     elixir: "~> 1.0",
     deps: deps]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [
      {:esqlite, github: "mmzeeman/esqlite"},
      {:ecto, "~> 0.9"}
    ]
  end
end
