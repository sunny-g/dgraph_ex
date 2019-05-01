defmodule DgraphEx.Core.Query.As do
  @moduledoc false

  alias DgraphEx.Core.Query
  alias Query.As

  defstruct identifier: nil,
            block: nil

  defmacro __using__(_) do
    quote do
      def as(), do: %As{}
      def as(ident) when is_atom(ident), do: %As{identifier: ident}

      def as(%Query{} = q, identifier) do
        Query.put_sequence(q, %As{identifier: identifier})
      end

      def as(ident, %{__struct__: _} = block) when is_atom(ident) do
        %As{identifier: ident, block: block}
      end
    end
  end

  def render(%As{identifier: id, block: %{__struct__: module} = model}) do
    "#{id} as #{module.render(model)}"
  end

  def render(%As{identifier: id}), do: "#{id} as"
end
