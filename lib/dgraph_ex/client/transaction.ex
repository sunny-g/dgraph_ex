defmodule DgraphEx.Client.Transaction do
  @moduledoc """
  """

  alias DgraphEx.Client.LinRead

  defstruct [
    start_ts: 0,
    keys:     [],
    lin_read: %{},
  ]

  @type t     :: %__MODULE__{
    start_ts: __MODULE__.id,
    keys:     __MODULE__.keys,
    lin_read: LinRead.t,
  }
  @type id    :: non_neg_integer
  @type key   :: String.t
  @type keys  :: [key]

  @doc false
  defguard is_id(txid) when is_integer(txid) and txid > 0

  @doc """
  Concats a list of keys to the existing keys in the transaction's state
  """
  @spec add_keys(state :: t, keys :: key | [key]) :: t
  def add_keys(%__MODULE__{} = state, newKey)
      when is_bitstring(newKey), do: add_keys(state, [newKey])
  def add_keys(%__MODULE__{keys: keys} = state, newKeys)
      when is_list(newKeys) do
    %__MODULE__{state | keys: keys ++ newKeys}
  end

  @doc """
  Merges a new lin_read object into a transaction's state
  """
  @spec merge_lin_reads(state :: t, lin_read: LinRead.t) :: {:ok, t} | {:error, :invalid_lin_read}
  def merge_lin_reads(%__MODULE__{lin_read: %{} = lin_read} = state, %{} = new_lin_read) do
    case LinRead.merge_lin_reads(lin_read, new_lin_read) do
      {:ok, new_lin_read} ->
        %{state | lin_read: new_lin_read}
      {:error, reason} ->
        {:error, reason}
    end
  end
end
