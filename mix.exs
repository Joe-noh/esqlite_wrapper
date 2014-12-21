defmodule EsqliteWrapper.Mixfile do
  use Mix.Project

  def project do
    [app: :esqlite_wrapper,
     version: "0.0.1",
     elixir: "~> 1.0",
     deps: deps]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [{:esqlite, github: "mmzeeman/esqlite", ref: "9967ced039246f75f66a3891f584b1f150e56463"}]
  end
end
