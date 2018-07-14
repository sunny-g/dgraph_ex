defmodule DgraphEx.Query.Var do
  alias DgraphEx.Query

  defstruct []

  defmacro __using__(_) do
    quote do
      def var(%Query{} = q), do: Query.put_sequence(q, __MODULE__)
    end
  end
end
