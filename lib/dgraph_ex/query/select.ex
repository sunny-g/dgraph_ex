defmodule DgraphEx.Query.Select do
  alias DgraphEx.Query
  alias DgraphEx.Query.Select

  defstruct [
    fields: []
  ]

  defmacro __using__(_) do
    quote do
      def select(block) when is_tuple(block) or is_list(block) or is_atom(block) do
        DgraphEx.Query.Select.new(block)
      end
      def select(%Query{} = q, block) do
        Query.put_sequence(q, select(block))
      end
    end
  end


  @doc """
  Example
    iex> DgraphEx.Query.Select.new({:me, :he, you: :too, they: nil})
    %DgraphEx.Query.Select{fields: [{:they, nil}, {:you, :too}, {:he, nil}, {:me, nil}]}

  """
  def new(block) when is_tuple(block) do
    block
    |> Tuple.to_list
    |> new
  end
  def new(field) when is_atom(field) do
    new([{field, nil}])
  end
  def new(fields) when is_list(fields) do
    %Select{}
    |> put(fields)
  end

  @doc """
  Example

    iex> DgraphEx.Query.Select.put(%DgraphEx.Query.Select{}, :me)
    %DgraphEx.Query.Select{fields: [{:me, nil}]}

    iex> DgraphEx.Query.Select.put(%DgraphEx.Query.Select{}, [:me, :he, you: :too, they: nil])
    %DgraphEx.Query.Select{fields: [{:they, nil}, {:you, :too}, {:he, nil}, {:me, nil}]}

  """
  def put(%Select{} = s, []) do
    s
  end
  def put(%Select{} = s, [ item | rest ]) do
    s
    |> put(item)
    |> put(rest)
  end
  def put(%Select{} = s, item) when is_atom(item) do
    put(s, {item, nil})
  end
  def put(%Select{fields: prev} = s, {key, value}) when is_atom(key) do
    %{ s | fields: [ {key, value} | prev ]}
  end
  def put(%Select{} = s, key, value) when is_atom(key) do
    put(s, {key, value})
  end

  def render(%Select{fields: fields}) do
    [" { " | fields |> Enum.reverse |> do_render ]
    |> Enum.join(" ")
    |> Kernel.<>(" } ")
  end

  defp do_render(fields) when is_list(fields) do
    fields
    |> Enum.map(&do_render/1)
  end
  defp do_render({key, nil}) do
    to_string(key)
  end
  defp do_render({key, value}) when is_atom(value) do
    do_render({key, to_string(value)})
  end
  defp do_render({key, value}) when is_binary(value) do
    to_string(key) <> ": " <> to_string(value)
  end
  defp do_render({key, %Select{} = s}) do
    to_string(key) <> " " <> render(s)
  end
  defp do_render({key, %Query{} = q}) do
    to_string(key) <> " " <> Query.render(q)
  end
  defp do_render({key, %{__struct__: module} = model}) do
    do_render({key, module.render(model)})
  end

end