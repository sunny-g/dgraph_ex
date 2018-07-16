defmodule DgraphEx.Query.Filter do
  @moduledoc false

  alias DgraphEx.{Expr, Query}
  alias Expr.Uid

  defstruct expr: nil

  @connectors [
    :and,
    :or,
    :not
  ]

  defmacro __using__(_) do
    quote do
      def filter(%{__struct__: _} = expr), do: unquote(__MODULE__).new(expr)
      def filter(expr) when is_list(expr), do: unquote(__MODULE__).new(expr)

      def filter(%Query{} = q, expr) do
        Query.put_sequence(q, unquote(__MODULE__).new(expr))
      end
    end
  end

  def new(%{__struct__: _} = expr), do: %__MODULE__{expr: prepare_expr(expr)}
  def new(expr) when is_list(expr), do: %__MODULE__{expr: prepare_expr(expr)}

  def put_sequence(%Query{} = q, %__MODULE__{} = f) do
    Query.put_sequence(q, f)
  end

  def put_sequence(%Query{} = q, expr), do: put_sequence(q, new(expr))

  def render(%__MODULE__{expr: expr}), do: "@filter#{render_expr(expr)}"

  defp render_single(%{__struct__: module} = model), do: module.render(model)

  defp render_single(connector) when connector in @connectors do
    render_connector(connector)
  end

  defp render_single(list) when is_list(list), do: render_expr(list)

  defp render_expr(exprs) when is_list(exprs) do
    exprs
    |> Enum.map(&render_single/1)
    |> Enum.join(" ")
    |> wrap_parens
  end

  defp render_expr(item), do: render_expr([item])

  defp wrap_parens(item), do: "(" <> item <> ")"

  defp render_connector(:and), do: "AND"
  defp render_connector(:or), do: "OR"
  defp render_connector(:not), do: "NOT"

  defp prepare_expr(expr) do
    case expr do
      %Uid{} -> Uid.as_expression(expr)
      _ -> expr
    end
  end
end
