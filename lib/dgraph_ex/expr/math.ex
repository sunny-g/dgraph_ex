defmodule DgraphEx.Expr.Math do
  @moduledoc false

  defstruct expr: nil

  defmacro math(block) do
    expr =
      block
      |> Macro.to_string()
      |> String.replace(":", "")

    quote do
      %unquote(__MODULE__){expr: unquote(expr)}
    end
  end

  def new(expr) when is_binary(expr), do: %__MODULE__{expr: expr}

  def render(%__MODULE__{expr: expr}), do: "math(#{expr})"
end
