defmodule DgraphEx.Util do
  @moduledoc false

  alias DgraphEx.Core.Expr.Uid

  def as_rendered(value) do
    case value do
      x when is_list(x) -> x |> Poison.encode!()
      %Date{} = x -> x |> Date.to_iso8601() |> Kernel.<>("T00:00:00.0+00:00")
      %DateTime{} = x -> x |> DateTime.to_iso8601() |> String.replace("Z", "+00:00")
      x -> x |> to_string
    end
  end

  def infer_type(type) do
    case type do
      x when is_boolean(x) -> :bool
      x when is_binary(x) -> :string
      x when is_integer(x) -> :int
      x when is_float(x) -> :float
      x when is_list(x) -> :geo
      %DateTime{} -> :datetime
      %Date{} -> :date
      %Uid{} -> :uid
    end
  end

  def as_literal(value, :int) when is_integer(value), do: {:ok, to_string(value)}
  def as_literal(value, :float) when is_float(value), do: {:ok, as_rendered(value)}
  def as_literal(value, :bool) when is_boolean(value), do: {:ok, as_rendered(value)}

  def as_literal(value, :string) when is_binary(value),
    do: {:ok, value |> strip_quotes |> wrap_quotes}

  def as_literal(%Date{} = value, :date), do: {:ok, as_rendered(value)}
  def as_literal(%DateTime{} = value, :datetime), do: {:ok, as_rendered(value)}
  def as_literal(value, :geo) when is_list(value), do: check_and_render_geo_numbers(value)
  def as_literal(value, :uid) when is_binary(value), do: {:ok, "<" <> value <> ">"}
  def as_literal(value, type), do: {:error, {:invalidly_typed_value, value, type}}

  def as_string(value) do
    value
    |> as_rendered
    |> strip_quotes
    |> wrap_quotes
  end

  defp check_and_render_geo_numbers(nums) do
    if nums |> List.flatten() |> Enum.all?(&is_float/1) do
      {:ok, nums |> as_rendered}
    else
      {:error, :invalid_geo_json}
    end
  end

  defp wrap_quotes(value) when is_binary(value) do
    "\"" <> value <> "\""
  end

  defp strip_quotes(value) when is_binary(value) do
    value
    |> String.replace(~r/^"/, "")
    |> String.replace(~r/"&/, "")
  end

  def has_function?(module, func, arity) do
    :erlang.function_exported(module, func, arity)
  end

  def has_struct?(module) when is_atom(module) do
    Code.ensure_loaded?(module)
    has_function?(module, :__struct__, 0)
  end

  def get_value(params, key, default \\ nil) when is_atom(key) do
    str_key = to_string(key)

    cond do
      Map.has_key?(params, key) -> Map.get(params, key)
      Map.has_key?(params, str_key) -> Map.get(params, str_key)
      true -> default
    end
  end

  @spec merge_keyword_lists(target :: list, source :: list) :: list
  def merge_keyword_lists(target, source)
      when is_list(target) and is_list(source) do
    Enum.map(target, fn {k, v} ->
      case Keyword.fetch(source, k) do
        {:ok, val} -> {k, val}
        :error -> {k, v}
      end
    end)
  end
end
