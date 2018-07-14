defmodule DgraphEx.Expr.Val do
  alias DgraphEx.Util

  defstruct [
    label: nil
  ]

  defmacro __using__(_) do
    quote do
      def val(label), do: unquote(__MODULE__).new(label)
    end
  end

  def new(label) when is_atom(label), do: %__MODULE__{label: label}

  def render(%__MODULE__{label: label}) do
    "val(" <> Util.as_rendered(label) <> ")"
  end
end
