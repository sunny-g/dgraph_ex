defmodule DgraphEx.Query.Directive do
  alias DgraphEx.Query

  defstruct [
    label: nil
  ]

  @labels [
    :ignorereflex,
    :cascade,
    :normalize,
  ]

  defmacro __using__(_) do
    quote do
      def directive(label),           do: unquote(__MODULE__).new(label)
      def ignorereflex,               do: unquote(__MODULE__).new(:ignorereflex)
      def ignorereflex(%Query{} = q), do: Query.put_sequence(q, ignorereflex())

      def cascade,                    do: unquote(__MODULE__).new(:cascade)
      def cascade(%Query{} = q),      do: Query.put_sequence(q, cascade())

      def normalize,                  do: unquote(__MODULE__).new(:normalize)
      def normalize(%Query{} = q),    do: Query.put_sequence(q, normalize())
    end
  end

  def new(label) when label in @labels, do: %__MODULE__{label: label}

  def render(%__MODULE__{label: label}) when label in @labels, do: "@#{label}"
end
