defmodule DgraphEx.Expr.Count do
  @moduledoc false

  defstruct value: nil,
            extras: []

  defmacro __using__(_) do
    quote do
      def count(value), do: unquote(__MODULE__).new(value)
      def count(value, extras), do: unquote(__MODULE__).new(value, extras)
    end
  end

  def new(value) when is_atom(value), do: %__MODULE__{value: value}
  def new(value, %{__struct__: _} = model), do: new(value, [model])

  def new(value, extras) when is_list(extras) when is_atom(value) do
    %__MODULE__{value: value, extras: extras}
  end

  def render(%__MODULE__{value: v, extras: []}), do: "count(#{v})"

  def render(%__MODULE__{value: v, extras: extras}) when is_list(extras) do
    "count(#{v} " <> render_extras(extras) <> ")"
  end

  defp render_extras(extras) do
    extras
    |> Enum.map(fn %{__struct__: module} = model -> module.render(model) end)
    |> Enum.join(" ")
  end
end
