defmodule DgraphEx.Core.Expr.Anyofterms do
  @moduledoc false

  alias DgraphEx.Util

  defstruct label: nil,
            value: nil

  defmacro __using__(_) do
    quote do
      def anyofterms(label, value) when is_atom(label) and is_binary(value) do
        unquote(__MODULE__).new(label, value)
      end
    end
  end

  def new(label, value) when is_atom(label) and is_binary(value) do
    %__MODULE__{
      label: label,
      value: value
    }
  end

  def render(%__MODULE__{label: label, value: value})
      when is_atom(label) and is_binary(value) do
    {:ok, literal_value} = Util.as_literal(value, :string)
    "anyofterms(" <> Util.as_rendered(label) <> ", " <> literal_value <> ")"
  end
end
