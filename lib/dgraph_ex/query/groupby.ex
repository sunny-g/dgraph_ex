defmodule DgraphEx.Query.Groupby do
  @moduledoc false

  alias DgraphEx.Query

  defstruct predicate: nil

  defmacro __using__(_) do
    quote do
      def groupby(pred) when is_atom(pred), do: unquote(__MODULE__).new(pred)

      def groupby(%Query{} = q, pred) when is_atom(pred) do
        Query.put_sequence(q, unquote(__MODULE__).new(pred))
      end
    end
  end

  def new(pred) when is_atom(pred), do: %__MODULE__{predicate: pred}

  def render(%__MODULE__{predicate: p}) when is_atom(p), do: "@groupby(#{p})"
end
