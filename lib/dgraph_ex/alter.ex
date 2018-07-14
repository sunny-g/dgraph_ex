defmodule DgraphEx.Alter do
  alias DgraphEx.{Alter, Field}

  defstruct [
    fields: []
  ]

  defmacro __using__(_) do
    quote do
      def alter(), do: %Alter{}
    end
  end

  def put_field(%__MODULE__{fields: prev_fields} = alter, %Field{} = field) do
    %{alter | fields: [field | prev_fields]}
  end

  @doc """
  Returns a DgraphEx.Alter struct with the given fields (defaults to []).

  ## Examples:

      iex> DgraphEx.Alter.new()
      %DgraphEx.Alter{fields: []}

      iex> DgraphEx.Alter.new([%DgraphEx.Field{predicate: :name}])
      %DgraphEx.Alter{fields: [%DgraphEx.Field{predicate: :name}]}
  """
  def new(fields \\ []) when is_list(fields), do: %__MODULE__{fields: fields}

  @doc """
  Appends a Field struct to the fields (uh...) field of the alter struct.

  ## Examples:

      iex> DgraphEx.Alter.new() |> DgraphEx.Alter.append(%DgraphEx.Field{predicate: :name})
      %DgraphEx.Alter{fields: [%DgraphEx.Field{predicate: :name}]}
  """
  def append(%__MODULE__{} = model, %Field{} = field) do
    %{model | fields: model.fields ++ [field]}
  end


  @doc """
  Renders the DgraphEx.Alter struct as a string
  """
  def render(%__MODULE__{fields: fields}) do
    fields
    |> Enum.map(fn field -> Field.as_schema(field) end)
    |> Enum.join("\n")
    |> Kernel.<>("\n")
  end
end
