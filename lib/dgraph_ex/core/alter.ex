defmodule DgraphEx.Core.Alter do
  @moduledoc false

  alias DgraphEx.Core.{Alter, Field}

  defstruct fields: []

  defmacro __using__(_) do
    quote do
      def alter(), do: %Alter{}
    end
  end

  @doc """
  Returns a DgraphEx.Core.Alter struct with the given fields (defaults to []).

  ## Examples:

      iex> DgraphEx.Core.Alter.new()
      %DgraphEx.Core.Alter{fields: []}

      iex> DgraphEx.Core.Alter.new([%DgraphEx.Core.Field{predicate: :name}])
      %DgraphEx.Core.Alter{fields: [%DgraphEx.Core.Field{predicate: :name}]}
  """
  def new(fields \\ []) when is_list(fields), do: %__MODULE__{fields: fields}

  def put_field(%__MODULE__{fields: prev_fields} = alter, %Field{} = field) do
    %{alter | fields: [field | prev_fields]}
  end

  @doc """
  Appends a Field struct to the fields (uh...) field of the alter struct.

  ## Examples:

      iex> DgraphEx.Core.Alter.new() |> DgraphEx.Core.Alter.append(%DgraphEx.Core.Field{predicate: :name})
      %DgraphEx.Core.Alter{fields: [%DgraphEx.Core.Field{predicate: :name}]}
  """
  def append(%__MODULE__{} = model, %Field{} = field) do
    %{model | fields: model.fields ++ [field]}
  end

  @doc """
  Renders the DgraphEx.Core.Alter struct as a string
  """
  def render(%__MODULE__{fields: fields}) do
    fields
    |> Enum.map(fn field -> Field.as_schema(field) end)
    |> Enum.join("\n")
    |> Kernel.<>("\n")
  end
end
