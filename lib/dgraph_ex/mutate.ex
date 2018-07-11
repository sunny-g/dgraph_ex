defmodule DgraphEx.Mutate do
  alias DgraphEx.{Field, Mutate, Vertex}

  defstruct [
    fields: [],
  ]

  def new(fields \\ [])
  def new(fields) when is_list(fields), do: %Mutate{fields: fields}
  def new(%module{} = model) do
    if !Vertex.is_model?(model) do
      raise %ArgumentError{message: "#{inspect module} is not a Dgraph.Vertex model" }
    end
    fields = Vertex.populate_fields(nil, model)
    new(fields)
  end

  def render(%Mutate{} = mut), do: render([mut])
  def render(mutations) when is_list(mutations) do
    mutations
    |> Enum.map(fn item -> do_render(item) end)
    |> Enum.filter(fn
        "" -> nil
        item -> item
      end)
    |> case do
        [] ->
          ""
        lines ->
          "{ " <> Enum.join(lines, "\n") <> " }"
      end
  end

  defp do_render(%Mutate{fields: fields}) do
    fields
    |> Enum.map(fn
        %{subject: nil} ->
          nil
        field ->
          Field.as_setter(field)
      end)
    |> Enum.filter(fn item -> item end)
    |> case do
        [] ->
          ""
        lines ->
          IO.inspect(lines, label: :lines_was)
          "set { " <> Enum.join(lines, "\n") <> " }"
      end
  end
end
