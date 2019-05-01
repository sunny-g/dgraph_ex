defmodule DgraphEx.Core.Template do
  @moduledoc false

  alias DgraphEx.Core.Template

  defstruct [:query, :variables]

  def prepare(query, vars) when is_map(vars) do
    var_map =
      vars
      |> Enum.into([])
      |> Enum.map(fn {name, {value, type}} -> {name, value, type} end)

    prepare(query, var_map)
  end

  def prepare(query, vars) when is_list(vars) and is_binary(query) do
    vars =
      Enum.map(vars, fn {name, value, type} ->
        {dollarify(name), to_string(value), to_string(type)}
      end)

    args =
      vars
      |> Enum.map(fn {name, _, type} -> name <> ": " <> type end)
      |> Enum.join(", ")

    var_map =
      vars
      |> Enum.map(fn {name, value, _type} -> {name, value} end)
      |> Enum.into(%{})

    %Template{
      query: "query me(" <> args <> ")" <> query,
      variables: var_map
    }
  end

  defp dollarify("$" <> item), do: dollarify(item)
  defp dollarify("" <> item), do: "$" <> item

  defp dollarify(item) do
    item
    |> to_string
    |> dollarify
  end
end
