defmodule DgraphEx.Expr.Neq do

  defmacro define_funcs(module, name) do
    quote do
      def unquote(name)(label, value) do
        unquote(name)(label, value, DgraphEx.Util.infer_type(value))
      end
      def unquote(name)(label, value, type) when is_atom(label) or is_map(label) do
        %unquote(module){
          label:  label,
          value:  value,
          type:   type,
        }
      end
    end
  end

  defmacro __using__(name) do
    quote do
      alias DgraphEx.Expr.{Val, Count}
      alias DgraphEx.Util

      defstruct [
        label: nil,
        value: nil,
        type: nil,
      ]

      @doc """
      Syntax Examples: for inequality IE

        IE(predicate, value)
        IE(val(varName), value)
        IE(count(predicate), value)

      """

      def render(%__MODULE__{label: %{__struct__: module} = model, value: value, type: type}) when module in [Val, Count] do
        {:ok, literal_value} = Util.as_literal(value, type)
        model
        |> module.render
        |> do_render(literal_value)
      end
      def render(%__MODULE__{label: label, value: value, type: type}) when is_atom(label) do
        {:ok, literal_value} = Util.as_literal(value, type)
        label
        |> Util.as_rendered
        |> do_render(literal_value)
      end

      defp do_render(label, value), do: "#{unquote(name)}(#{label}, #{value})"
    end
  end
end
