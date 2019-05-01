defmodule DgraphEx.Core.Expr.Contains do
  @moduledoc false

  defstruct label: nil,
            geo_json: nil

  defmacro __using__(_) do
    quote do
      def contains(label, geo_json) when is_atom(label) and is_list(geo_json) do
        unquote(__MODULE__).new(label, geo_json)
      end
    end
  end

  def new(label, geo_json) when is_atom(label) and is_list(geo_json) do
    %__MODULE__{
      label: label,
      geo_json: geo_json
    }
  end

  def render(%__MODULE__{label: label, geo_json: geo_json})
      when is_atom(label) and is_list(geo_json) do
    "contains(#{label}, #{Poison.encode!(geo_json)})"
  end
end
