defmodule DgraphEx.Query.Block do
  @moduledoc false

  alias DgraphEx.{Expr, Query}
  alias Expr.Uid

  defstruct label: nil,
            keywords: [],
            aliased: nil

  # as per @srh on dgraph slack (there may be more than these) v0.8.0
  @keyword_keys ~w(func orderasc orderdesc first after offset)a

  defmacro __using__(_) do
    quote do
      def func(label, %{__struct__: _} = expr) do
        unquote(__MODULE__).new(label, func: expr)
      end

      def func(%Query{} = q, label, %{__struct__: _} = expr) do
        b = unquote(__MODULE__).new(label, func: expr)
        Query.put_sequence(q, b)
      end

      def block(args) when is_list(args), do: unquote(__MODULE__).new(args)

      def block(label, args) when is_atom(label) and is_list(args) do
        unquote(__MODULE__).new(label, args)
      end

      def block(%Query{} = q, args) when is_list(args) do
        Query.put_sequence(q, unquote(__MODULE__).new(args))
      end

      def block(%Query{} = q, label, args) do
        Query.put_sequence(q, unquote(__MODULE__).new(label, args))
      end

      def aliased(label, value) when is_atom(label) do
        unquote(__MODULE__).aliased(label, value)
      end
    end
  end

  def keyword_allowed_keys(), do: @keyword_keys

  def new(kwargs) when is_list(kwargs), do: %__MODULE__{keywords: kwargs}

  def new(label, kwargs) when is_atom(label) and is_list(kwargs) do
    %__MODULE__{label: label, keywords: kwargs}
  end

  def aliased(key, val), do: %__MODULE__{aliased: {key, val}}

  def put_kwarg(%__MODULE__{} = b, {k, v}), do: put_kwarg(b, k, v)

  def put_kwarg(%__MODULE__{keywords: kw} = b, key, value) do
    %{b | keywords: kw ++ [{key, value}]}
  end

  def render(%__MODULE__{aliased: {key, %{__struct__: module} = model}}) do
    "#{key}: #{module.render(model)}"
  end

  def render(%__MODULE__{aliased: {key, value}}), do: "#{key}: #{value}"

  def render(%__MODULE__{label: label} = b) do
    "#{label}(" <> render_keywords(b) <> ")"
  end

  def render(block) when is_tuple(block) do
    block
    |> Tuple.to_list()
    |> do_render([])
  end

  defp render_keywords(%__MODULE__{keywords: keywords}) do
    keywords
    |> Enum.map(fn
      {key, %{__struct__: module} = model} when is_atom(key) ->
        {key, model} = prepare_expr({key, model})
        {key, module.render(model)}

      {key, value} when is_atom(value) or is_number(value) ->
        {key, to_string(value)}
    end)
    |> Enum.map(fn {k, v} -> to_string(k) <> ": " <> v end)
    |> Enum.join(", ")
  end

  def prepare_expr(expr) do
    case expr do
      {:func, %Uid{} = uid} ->
        {:func, Uid.as_expression(uid)}

      %Uid{} ->
        Uid.as_naked(expr)

      _ ->
        expr
    end
  end

  defp do_render([], []), do: "{ }"

  defp do_render([], lines) do
    lines
    |> Enum.reverse()
    |> Enum.join(" ")
    |> wrap_curlies
  end

  defp do_render([[] | rest], lines) do
    # empty keywords (might still be something left?)
    do_render(rest, lines)
  end

  # [[genres: [%DgraphEx.Query.Block{keywords: [orderdesc: %DgraphEx.Expr.Val{label: :C}], label: :genre}, [genre_name: :name@en]]]]
  defp do_render([[%{__struct__: module} = model | rest_keywords] | rest], lines) do
    do_render([rest_keywords | rest], [module.render(model) | lines])
  end

  defp do_render([[{key, value} | rest_keywords] | rest], lines)
       when is_atom(key) and is_list(value) do
    do_render([rest_keywords | rest], ["#{key}: #{do_render(value, [])}" | lines])
  end

  defp do_render([[{key, value} | rest_keywords] | rest], lines)
       when is_atom(key) and (is_atom(value) or is_binary(value)) do
    # for keywords with stringy values
    do_render([rest_keywords | rest], ["#{key}: #{value}" | lines])
  end

  defp do_render([[{key, %{__struct__: module} = model} | rest_keywords] | rest], lines)
       when is_atom(key) do
    # for keywords with expr values
    do_render([rest_keywords | rest], ["#{key}: #{module.render(model)}" | lines])
  end

  defp do_render([%{__struct__: module} = model | rest], lines) do
    # for exprs
    do_render(rest, [module.render(model) | lines])
  end

  defp do_render([variable, :as, %{__struct__: module} = model | rest], lines)
       when is_atom(variable) do
    # for aliases
    do_render(rest, ["#{variable} as #{module.render(model)}" | lines])
  end

  defp do_render([new_block | rest], lines)
       when is_tuple(new_block) do
    # for new blocks or sub-blocks
    do_render(rest, [render(new_block) | lines])
  end

  defp do_render([variable | rest], lines)
       when is_atom(variable) do
    # for normal fields
    do_render(rest, [to_string(variable) | lines])
  end

  defp wrap_curlies(block), do: "{ " <> block <> " }"
end
