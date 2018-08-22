defmodule DgraphEx.Core.Query.Select do
  @moduledoc false

  alias DgraphEx.Core.{Query, Vertex}
  alias DgraphEx.Util
  alias Query.As

  defstruct fields: []

  defmacro __using__(_) do
    quote do
      def select(block)
          when is_tuple(block)
          when is_list(block)
          when is_map(block)
          when is_atom(block) do
        unquote(__MODULE__).new(block)
      end

      def select(%Query{} = q, block) do
        Query.put_sequence(q, select(block))
      end
    end
  end

  @doc """
  ## Examples

      iex> DgraphEx.Core.Query.Select.new({:me, :he, you: :too, they: nil})
      %DgraphEx.Core.Query.Select{fields: [{:they, nil}, {:you, :too}, {:he, nil}, {:me, nil}]}
  """
  def new(block) when is_tuple(block) do
    block
    |> Tuple.to_list()
    |> new
  end

  def new(%{__struct__: _} = model) do
    model
    |> Vertex.as_selector()
    |> new
  end

  def new(atom) when is_atom(atom) do
    if Util.has_struct?(atom) do
      new(atom.__struct__)
    else
      new([{atom, nil}])
    end
  end

  def new(fields) when is_list(fields), do: put(%__MODULE__{}, fields)

  @doc """
  ## Examples

      iex> DgraphEx.Core.Query.Select.put(%DgraphEx.Core.Query.Select{}, :me)
      %DgraphEx.Core.Query.Select{fields: [{:me, nil}]}

      iex> DgraphEx.Core.Query.Select.put(%DgraphEx.Core.Query.Select{}, [:me, :he, you: :too, they: nil])
      %DgraphEx.Core.Query.Select{fields: [{:they, nil}, {:you, :too}, {:he, nil}, {:me, nil}]}
  """
  def put(%__MODULE__{} = s, []), do: s

  def put(%__MODULE__{} = s, [item | rest]) do
    s
    |> put(item)
    |> put(rest)
  end

  def put(%__MODULE__{} = s, item) when is_atom(item), do: put(s, {item, nil})

  def put(%__MODULE__{fields: prev} = s, {key, value}) when is_atom(key) do
    %{s | fields: [{key, value} | prev]}
  end

  def put(%__MODULE__{fields: prev} = s, %As{} = as) do
    %{s | fields: [as | prev]}
  end

  def put(%__MODULE__{} = s, key, value) when is_atom(key), do: put(s, {key, value})

  def render(%__MODULE__{fields: fields}) do
    rendered_fields = fields |> Enum.reverse() |> do_render
    parts = ["{" | rendered_fields] ++ ["}"]
    Enum.join(parts, " ")
  end

  defp do_render(fields) when is_list(fields) do
    Enum.map(fields, &do_render/1)
  end

  defp do_render({key, nil}), do: to_string(key)

  defp do_render({key, value}) when is_atom(value) do
    do_render({key, to_string(value)})
  end

  defp do_render({key, value}) when is_binary(value) do
    to_string(key) <> ": " <> to_string(value)
  end

  defp do_render({key, %__MODULE__{} = s}), do: to_string(key) <> " " <> render(s)

  defp do_render({key, %Query{} = q}) do
    to_string(key) <> " " <> Query.render(q)
  end

  defp do_render({key, %{__struct__: module} = model}) do
    do_render({key, module.render(model)})
  end

  defp do_render(%As{} = as), do: As.render(as)
end
