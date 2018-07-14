defmodule DgraphEx.Query do
  alias DgraphEx.{Kwargs, Query}
  alias Query.{
    As,
    Block,
    Directive,
    Filter,
    Groupby,
    Select,
    Var,
  }

  @bracketed [
    As,
    Var,
    Groupby,
  ]

  defstruct [
    sequence: [],
  ]

  defmacro __using__(_) do
    quote do
      use As
      use Block
      use Directive
      use Filter
      use Groupby
      use Select
      use Var

      def query, do: %Query{}
      def query(kwargs) when is_list(kwargs), do: Kwargs.parse(kwargs)

      def render(x), do: Query.render(x)
    end
  end

  def merge(%__MODULE__{sequence: seq1}, %__MODULE__{sequence: seq2}) do
    %__MODULE__{sequence: seq2 ++ seq1}
  end

  def put_sequence(%__MODULE__{sequence: prev_sequence} = d, prefix)
      when is_list(prefix) do
    %{d | sequence: prefix ++ prev_sequence}
  end
  def put_sequence(%__MODULE__{sequence: sequence} = d, item) do
    %{d | sequence: [item | sequence]}
  end

  def render(block) when is_tuple(block), do: Block.render(block)
  def render(%__MODULE__{sequence: backwards_sequence}) do
    case backwards_sequence |> Enum.reverse do
      [%Block{keywords: [{:func, _} | _]} | _] = sequence ->
        sequence
        |> render_sequence
        |> with_brackets
      [%module{} | _] = sequence when module in @bracketed ->
        sequence
        |> render_sequence
        |> with_brackets
      sequence when is_list(sequence) ->
        sequence
        |> render_sequence
    end
  end
  def render(%module{} = model), do: module.render(model)

  defp render_sequence(sequence) do
    sequence
    |> Enum.map(fn (%module{} = model) -> module.render(model) end)
    |> Enum.join(" ")
  end

  defp with_brackets(rendered), do: "{ " <> rendered <> " }"
end
