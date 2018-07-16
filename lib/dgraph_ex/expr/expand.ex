defmodule DgraphEx.Expr.Expand do
  @moduledoc false

  defstruct label: nil

  defmacro __using__(_) do
    quote do
      def expand(label) when is_atom(label), do: unquote(__MODULE__).new(label)
    end
  end

  def new(label) when is_atom(label), do: %__MODULE__{label: label}

  def render(%__MODULE__{label: label}) when is_atom(label) do
    "expand(#{label})"
  end
end
