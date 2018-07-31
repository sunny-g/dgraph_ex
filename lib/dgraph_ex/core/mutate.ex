defmodule DgraphEx.Core.Mutate do
  @moduledoc false

  alias DgraphEx.Core.{Expr, Field, Vertex}
  alias Expr.Uid

  defstruct fields: []

  def new(fields \\ [])
  def new(fields) when is_list(fields), do: %__MODULE__{fields: fields}

  def new(model) do
    assert_vertex(model)

    fields = Vertex.populate_fields(nil, model)
    new(fields)
  end

  def update(model, uid) when is_bitstring(uid) do
    update(model, %Uid{value: uid, type: :literal})
  end

  def update(model, uid = %Uid{}) do
    assert_vertex(model)

    fields = Vertex.populate_fields(uid, model)
    new(fields)
  end

  def render(%__MODULE__{} = mut), do: render([mut])

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

  defp do_render(%__MODULE__{fields: fields}) do
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
        "set { " <> Enum.join(lines, "\n") <> " }"
    end
  end

  defp assert_vertex(%module{} = model) do
    if !Vertex.is_model?(model) do
      raise %ArgumentError{message: "#{inspect(module)} is not a Dgraph.Vertex model"}
    end
  end
end
