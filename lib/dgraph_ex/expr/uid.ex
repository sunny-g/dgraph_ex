defmodule DgraphEx.Expr.Uid do
  @moduledoc """
  https://docs.dgraph.io/query-language/#uid

  Syntax Examples:

    q(func: uid(<uid>))
    predicate @filter(uid(<uid1>, ..., <uidn>))
    predicate @filter(uid(a)) for variable a
    q(func: uid(a,b)) for variables a and b

  """
  alias DgraphEx.Util

  defstruct [
    :value,
    :type,
  ]

  @types [
    :literal,
    :expression,
  ]

  defmacro __using__(_) do
    quote do
      def uid(value), do: unquote(__MODULE__).new(value)
    end
  end

  defguard is_uid(value, type)
      when (is_atom(value) or is_binary(value) or is_list(value))
      and type in @types

  @doc """
  lists of uid literals are rendered inside a `uid(<uids_here>)` function (as in @filter)
  lists of uid variables are rendered inside a `uid(<uids_here>)` function (as in @filter)
  therefore any list is an uid expression
  """
  def new(value) when is_uid(value, :literal), do: new(value, :literal)
  def new(value) when is_uid(value, :expression), do: new(value, :expression)
  def new(uids) when is_uid(uids, :expression), do: new(uids, :expression)
  def new(value, type) when is_uid(value, type) do
    %__MODULE__{value: value, type: type}
  end

  @doc """
  This function is used by Func to ensure that a uid string ("0x9") is rendered
  as an expression literal `uid(0x9)` instead of an actual literal `<0x9>`
  """
  def as_expression(%__MODULE__{} = u), do: %{u | type: :expression}

  def as_literal(%__MODULE__{} = u), do: %{u | type: :literal}

  def as_naked(%__MODULE__{} = u), do: %{u | type: :naked}

  def render(%__MODULE__{value: value})
      when is_atom(value), do: render_expression([value])
  def render(%__MODULE__{value: value, type: :literal}) when is_binary(value) do
    {:ok, uid_literal} = Util.as_literal(value, :uid)
    uid_literal
  end
  def render(%__MODULE__{value: value, type: :literal})
      when is_list(value), do: render_expression(value)
  def render(%__MODULE__{value: value, type: :naked})
      when is_binary(value), do: value
  def render(%__MODULE__{value: value, type: :expression})
      when (is_atom(value) or is_binary(value)), do: render_expression([value])
  def render(%__MODULE__{value: value, type: :expression})
      when is_list(value), do: render_expression(value)

  defp render_expression(uids) when is_list(uids) do
    args = uids
      |> Enum.map(&to_string/1)
      |> Enum.join(", ")
    "uid(" <> args <> ")"
  end
end

defimpl String.Chars, for: DgraphEx.Expr.Uid do
  def to_string(uid), do: DgraphEx.Expr.Uid.render(uid)
end
