defmodule DgraphEx.Alter do
  alias DgraphEx.{Alter, Field}

  defstruct [
    fields: []
  ]

  @doc """
  A static string that is the http path for altering a schema.

      iex> DgraphEx.Alter.path
      "/alter"
  """
  def path do
    "/alter"
  end

  defmacro __using__(_) do
    quote do

      def alter() do
        %Alter{}
      end

    end
  end

  def put_field(%Alter{fields: prev_fields} = alter, %Field{} = field) do
    %{ alter | fields: [ field | prev_fields ]}
  end

  @doc """
  Returns a DgraphEx.Alter struct with the given fields. default [].

      iex> DgraphEx.Alter.new
      %DgraphEx.Alter{fields: []}

      iex> DgraphEx.Alter.new([%DgraphEx.Field{predicate: :name}])
      %DgraphEx.Alter{fields: [%DgraphEx.Field{predicate: :name}]}
  """
  def new(fields \\ []) when is_list(fields) do
    %Alter{fields: fields}
  end

  @doc """
  Appends a Field struct to the fields (uh...) field of the alter struct.

      iex> DgraphEx.Alter.new() |> DgraphEx.Alter.append(%DgraphEx.Field{predicate: :name})
      %DgraphEx.Alter{fields: [%DgraphEx.Field{predicate: :name}]}
  """
  def append(%Alter{} = model, %Field{} = field) do
    %{ model | fields: model.fields ++ [field] }
  end


  @doc """
  Renders
  """
  def render(%__MODULE__{fields: fields}) do
    fields
    |> Enum.map(fn field -> Field.as_schema(field) end)
    |> Enum.join("\n")
    |> Kernel.<>("\n")
  end

end