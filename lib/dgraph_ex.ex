defmodule DgraphEx do
  alias DgraphEx.{Alter, Delete, Expr, Field, Set, Query, Util, Vertex}

  require Vertex
  require Expr.Math

  Vertex.query_model()
  use Expr
  use Field
  # use Schema

  # use Mutation
  use Alter
  use Delete
  use Set

  use Query

  defmacro math(block) do
    quote do: Expr.Math.math(unquote(block))
  end

  def into({:error, _} = err, _, _), do: err
  def into({:ok, resp}, module, key)
      when is_atom(key) and is_map(resp), do: into(resp, module, key)
  def into(resp, module, key) when is_map(resp) do
    resp
    |> Util.get_value(key, {:error, {:invalid_key, key}})
    |> do_into(module, key)
  end

  defp do_into(%{} = item, %{} = model), do: Vertex.populate_model(model, item)
  defp do_into({:error, _} = err, _, _), do: err
  defp do_into(items, module, key) when is_atom(module) do
    do_into(items, module.__struct__, key)
  end
  defp do_into(items, %{} = model, key) when is_list(items) do
    %{key => Enum.map(items, fn item -> do_into(item, model) end)}
  end
  defp do_into(%{} = item, %{} = model, key), do: %{key => do_into(item, model)}
end
