defmodule DgraphEx.Expr.Eq do
  @moduledoc false

  alias DgraphEx.Expr.{Count, Val}
  alias DgraphEx.Util

  defstruct label: nil,
            value: nil,
            type: nil

  defmacro __using__(_) do
    quote do
      def eq(label, value), do: eq(label, value, Util.infer_type(value))

      def eq(label, value, type) when is_atom(label) or is_map(label) do
        %unquote(__MODULE__){
          label: label,
          value: value,
          type: type
        }
      end
    end
  end

  @doc """
  Syntax Examples:

    eq(predicate, value)
    eq(val(varName), value)
    eq(count(predicate), value)
    eq(predicate, [val1, val2, ..., valN])
  """
  def render(%__MODULE__{label: label, value: items})
      when is_list(items) and is_atom(label) do
    literal_value = Poison.encode!(items)

    label
    |> Util.as_rendered()
    |> do_render(literal_value)
  end

  def render(%__MODULE__{label: %{__struct__: module} = model, value: value, type: type})
      when module in [Val, Count] do
    {:ok, literal_value} = Util.as_literal(value, type)

    model
    |> module.render
    |> do_render(literal_value)
  end

  def render(%__MODULE__{label: label, value: value, type: type})
      when is_atom(label) do
    {:ok, literal_value} = Util.as_literal(value, type)

    label
    |> Util.as_rendered()
    |> do_render(literal_value)
  end

  defp do_render(label, value), do: "eq(#{label}, #{value})"
end
