defmodule DgraphEx.Core.Expr.Intersects do
  @moduledoc false

  alias Poison

  defstruct label: nil,
            geo_json: nil

  defmacro __using__(_) do
    quote do
      def intersects(label, [[[x, y] | _] | _] = geo_json)
          when is_atom(label) and is_float(x) and is_float(y) do
        unquote(__MODULE__).new(label, geo_json)
      end
    end
  end

  def new(label, [[[x, y] | _] | _] = geo_json)
      when is_atom(label) and is_float(x) and is_float(y) do
    %__MODULE__{
      label: label,
      geo_json: geo_json
    }
  end

  def render(%__MODULE__{label: label, geo_json: [[[x, y] | _] | _] = geo_json})
      when is_atom(label) and is_float(x) and is_float(y) do
    "intersects(#{label}, #{Poison.encode!(geo_json)})"
  end
end
