defmodule DgraphEx.Expr.Regexp do
  alias DgraphEx.Util

  defstruct [
    label: nil,
    regex: nil,
  ]

  defmacro __using__(_) do
    quote do
      def regexp(label, regex), do: unquote(__MODULE__).new(label, regex)
    end
  end

  def new(label, regex) when is_atom(label) and is_binary(regex) do
    new(label, Regex.compile!(regex))
  end

  def new(label, regex) when is_atom(label) do
    if Regex.regex?(regex) do
      %__MODULE__{label: label, regex: regex}
    else
      raise %RuntimeError{message: "Invalid Regex. Got: #{inspect regex}"}
    end
  end

  def render(%__MODULE__{label: label, regex: regex}) do
    "regexp(" <> Util.as_rendered(label) <> ", " <> render_regex(regex) <> ")"
  end

  defp render_regex(regex) do
    regex
    |> Regex.source
    |> wrap_slashes
    |> append_options(regex)
  end

  defp wrap_slashes(str), do: "/" <> str <> "/"

  defp append_options(str, regex), do: str <> Regex.opts(regex)
end
