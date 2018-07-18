defmodule DgraphEx.Core.Query.Func do
  @moduledoc false

  alias DgraphEx.Core.{Expr, Query}
  alias Expr.Uid
  alias Query.{Block}

  defstruct name: nil,
            expr: nil,
            block: {}

  defmacro __using__(_) do
    quote do
      def func(one, two, three \\ nil, four \\ nil) do
        case {one, two, three, four} do
          {%Query{}, _, %{__struct__: _}, block}
          when is_nil(block) or is_tuple(block) ->
            __MODULE__.func_4(one, two, three, four)

          {_, _, _, nil} ->
            __MODULE__.func_3(one, two, three)
        end
      end
    end
  end

  def func_3(name, expr, nil), do: Block.new(name, func: expr)

  def func_3(name, %{__struct__: _} = expr, block) when is_tuple(block) do
    %__MODULE__{
      name: name,
      expr: prepare_expr(expr),
      block: block
    }
  end

  def func_4(q, name, expr, nil), do: func_4(q, name, expr, {})

  def func_4(%Query{} = q, name, %{__struct__: _} = expr, block)
      when is_tuple(block) do
    Query.put_sequence(q, %__MODULE__{
      name: name,
      expr: __MODULE__.prepare_expr(expr),
      block: block
    })
  end

  def render(%__MODULE__{} = f) do
    "#{f.name}(func: #{render_expr(f)}) " <> render_block(f)
  end

  defp render_block(%__MODULE__{block: {}}), do: ""
  defp render_block(%__MODULE__{block: block}), do: Block.render(block)

  defp render_expr(%__MODULE__{expr: %{__struct__: module} = model}) do
    module.render(model)
  end

  def prepare_expr(expr) do
    case expr do
      %Uid{} -> Uid.as_expression(expr)
      _ -> expr
    end
  end
end
