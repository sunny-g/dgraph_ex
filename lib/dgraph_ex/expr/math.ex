defmodule DgraphEx.Expr.Math do
  alias DgraphEx.Expr.Math

  defstruct [
    expr: nil
  ]

  defmacro math(block) do
    expr =
      block
      |> Macro.to_string
      |> String.replace(":", "")
    quote do
      %DgraphEx.Expr.Math{
        expr: unquote(expr)
      }
    end
  end

  def new(expr) when is_binary(expr), do: %Math{expr: expr}

  def render(%Math{expr: expr}), do: "math(#{expr})"
end
