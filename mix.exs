defmodule Mix.Tasks.Compile.Nif do
  use Mix.Task

  @shortdoc "compile c_src/*.c"

  @compiler "clang"
  @erl_flag "-I#{:code.root_dir}/erts-#{:erlang.system_info :version}/include"
  @c_files  Path.wildcard("c_src/*.c")
  @out_opt  "-o priv/exqlite.so"

  def run(_) do
    File.mkdir_p!("priv")

    [@compiler, @erl_flag, @c_files, shared_opts, @out_opt]
    |> List.flatten
    |> Enum.join(" ")
    |> Mix.shell.cmd
  end

  defp shared_opts, do: ["-shared" | os_shared_opts]

  defp os_shared_opts do
    case :os.type do
      {:unix, :darwin} -> ~w(-dynamiclib -undefined dynamic_lookup)
      _other -> []
    end
  end

end

defmodule Exqlite.Mixfile do
  use Mix.Project

  def project do
    [app: :exqlite,
     version: "0.2.0",
     elixir: "~> 1.0",
     compilers: [:nif | Mix.compilers],
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
