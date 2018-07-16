defmodule DgraphEx.Expr.Has do
  @moduledoc false

  defstruct value: nil

  defmacro __using__(_) do
    quote do
      def has(value), do: unquote(__MODULE__).new(value)
    end
  end

  def new(value) when is_atom(value), do: %__MODULE__{value: value}

  def render(%__MODULE__{value: value}), do: "has(" <> to_string(value) <> ")"
end
