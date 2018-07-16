defmodule DgraphEx.Expr.UidIn do
  @moduledoc """
  An example from https://docs.dgraph.io/query-language/#uid-in :

  ```
    {
      caro(func: eq(name, "Marc Caro")) {
        name@en
        director.film @filter(uid_in(~director.film, 597046)){
          name@en
        }
      }
    }
  ```
  """

  defstruct predicate: nil,
            uid: nil

  defmacro __using__(_) do
    quote do
      def uid_in(predicate, uid) when is_atom(predicate) and is_binary(uid) do
        unquote(__MODULE__).new(predicate, uid)
      end
    end
  end

  def new(predicate, uid) when is_atom(predicate) and is_binary(uid) do
    %__MODULE__{
      predicate: predicate,
      uid: uid
    }
  end

  def render(%__MODULE__{predicate: predicate, uid: uid})
      when is_atom(predicate) and is_binary(uid) do
    "uid_in(#{predicate}, #{uid})"
  end
end
