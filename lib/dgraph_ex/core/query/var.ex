defmodule DgraphEx.Core.Query.Var do
  @moduledoc false

  alias DgraphEx.Core.Query

  defstruct []

  defmacro __using__(_) do
    quote do
      def var(%Query{} = q), do: Query.put_sequence(q, __MODULE__)
    end
  end
end
