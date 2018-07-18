defmodule DgraphEx.Client.Response do
  @moduledoc """
  Dgraph API Response struct
  """

  alias DgraphEx.Client.Transaction
  require OK

  defstruct data: nil,
            extensions: %{},
            code: "",
            message: "",
            errors: []

  @type message :: %{
          code: bitstring,
          message: bitstring
        }
  @type error ::
          atom
          | bitstring
          | message
          | {:dgraph_error, [message]}
          | {:network_error, any}
  @type t :: %__MODULE__{
          data: map,
          extensions: map,
          code: bitstring,
          message: bitstring,
          errors: [error]
        }

  @spec get_tx(res :: t()) :: {:ok, Transaction.t()} | {:error, :not_found}
  def get_tx(%__MODULE__{} = response) do
    OK.with do
      extensions = response.extensions
      txn <- get_in_obj(extensions, [:txn])

      txid = Map.get(txn, :start_ts)
      keys = Map.get(txn, :keys, [])
      lin_read = get_in(txn, [:lin_read, :ids])

      tx = %Transaction{start_ts: txid, keys: keys, lin_read: lin_read}
      {:ok, tx}
    end
  end

  @spec get_in_obj(obj :: map, keys :: list(atom | bitstring)) ::
          {:ok, any} | {:error, :not_found}
  defp get_in_obj(obj, keys) when is_map(obj) do
    case get_in(obj, keys) do
      nil -> {:error, :not_found}
      val -> {:ok, val}
    end
  end
end
