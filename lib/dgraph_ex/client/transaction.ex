defmodule DgraphEx.Client.Transaction do
  @moduledoc false

  alias DgraphEx.Client.LinRead
  require OK

  defstruct lin_read: LinRead.new(),
            keys: [],
            start_ts: 0

  @type id :: non_neg_integer
  @type key :: String.t()
  @type keys :: [key]
  @type update :: {keys :: key() | keys(), lin_read :: LinRead.t()}
  @type t :: %__MODULE__{
          lin_read: LinRead.t(),
          keys: keys(),
          start_ts: id()
        }

  @doc false
  defguard is_id(txid) when is_integer(txid) and txid > 0

  @doc """
  Concats a list of keys to the existing keys in the transaction's state
  """
  @spec add_keys(state :: t, keys :: key | [key]) :: t
  def add_keys(%__MODULE__{} = state, new_key)
      when is_bitstring(new_key),
      do: add_keys(state, [new_key])

  def add_keys(%__MODULE__{keys: keys} = state, new_keys)
      when is_list(new_keys) do
    %__MODULE__{state | keys: keys ++ new_keys}
  end

  @doc """
  Merges a new lin_read object into a transaction's state
  """
  @spec merge_lin_reads(state :: t, lin_read: LinRead.t()) ::
          {:ok, t} | {:error, :invalid_lin_read}
  def merge_lin_reads(%__MODULE__{lin_read: target} = state, %{} = source) do
    OK.with do
      new_lin_read <- LinRead.merge_lin_reads(target, source)
      new_state = %__MODULE__{state | lin_read: new_lin_read}
      {:ok, new_state}
    end
  end

  @doc """
  Merges a transaction state object into another

  Generally, the second transaction state object is created from a /mutate
  response
  """
  @spec update(state :: t(), new_tx :: t()) :: {:ok, t()} | {:error, :invalid_lin_read}
  def update(%__MODULE__{start_ts: txid}, %__MODULE__{start_ts: new_txid})
      when txid != new_txid,
      do: {:error, :txid_mismatch}

  def update(%__MODULE__{} = state, %__MODULE__{keys: keys, lin_read: new_lin_read}) do
    state
    |> add_keys(keys)
    |> merge_lin_reads(new_lin_read)
  end
end
