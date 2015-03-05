defmodule Exqlite.Mixfile do
  use Mix.Project

  def project do
    [app: :esqlite_wrapper,
     version: "0.1.0",
     elixir: "~> 1.0",
     deps: deps]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [
      {:esqlite, github: "mmzeeman/esqlite"},
      {:ecto, "~> 0.8"}
    ]
  end
end
