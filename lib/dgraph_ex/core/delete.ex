defmodule DgraphEx.Core.Delete do
  @moduledoc false

  alias DgraphEx.Core.{Delete, Field}

  defstruct fields: []

  defmacro __using__(_) do
    quote do
      def delete(), do: %Delete{}
      def delete(block), do: Delete.delete(block)
      def delete(%Delete{} = m, block), do: Delete.delete(m, block)

      def delete(subject, predicate, object) do
        Delete.delete(subject, predicate, object)
      end
    end
  end

  def delete(%Field{} = field), do: put_field(%__MODULE__{}, field)

  def delete(block) when is_tuple(block) do
    fields = Tuple.to_list(block)
    put_field(%__MODULE__{}, fields)
  end

  def delete(%__MODULE__{} = del, %Field{} = field), do: put_field(del, field)

  def delete(subject, predicate, object) do
    field = Field.delete_field(subject, predicate, object)
    put_field(%__MODULE__{}, field)
  end

  def put_field(%__MODULE__{} = md, fields) when is_list(fields) do
    Enum.reduce(fields, md, fn field, acc_md -> put_field(acc_md, field) end)
  end

  def put_field(%__MODULE__{fields: prev_fields} = md, %Field{} = field) do
    %{md | fields: [field | prev_fields]}
  end

  def render(%__MODULE__{fields: []}), do: ""

  def render(%__MODULE__{fields: fields}) do
    "{ delete { " <> render_fields(fields) <> " } }"
  end

  defp render_fields(fields) do
    fields
    |> Enum.reverse()
    |> Enum.map(&Field.as_delete/1)
    |> Enum.join("\n")
  end
end
