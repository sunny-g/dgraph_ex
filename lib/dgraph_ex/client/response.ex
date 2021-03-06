defmodule DgraphEx.Client.Response do
  @moduledoc """
  Dgraph API Response struct
  """

  alias DgraphEx.Client.Transaction
  require OK

  defstruct data: %{},
            code: "",
            message: "",
            uids: %{},
            extensions: %{},
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
          code: bitstring,
          message: bitstring,
          uids: map,
          extensions: map,
          errors: [error]
        }

  @spec get_lin_read(res :: t()) :: {:ok, LinRead.t()} | {:error, :not_found}
  def get_lin_read(%__MODULE__{} = response) do
    OK.with do
      %Transaction{lin_read: lin_read} <- get_tx(response)
      {:ok, lin_read}
    end
  end

  @spec get_tx(res :: t()) :: {:ok, Transaction.t()} | {:error, :not_found}
  def get_tx(%__MODULE__{} = response) do
    OK.with do
      txn <- get_in_obj(response.extensions, ["txn"])
      lin_read <- get_in_obj(txn, ["lin_read", "ids"])

      tx = %Transaction{
        start_ts: Map.get(txn, "start_ts"),
        keys: Map.get(txn, "keys", []),
        lin_read: lin_read
      }

      {:ok, tx}
    end
  end

  @spec get_in_obj(obj :: map, keys :: list(atom | bitstring)) ::
          {:ok, any} | {:error, :not_found}
  defp get_in_obj(obj, keys) when is_map(obj) and is_list(keys) do
    case get_in(obj, keys) do
      nil -> {:error, :not_found}
      val -> {:ok, val}
    end
  end
end
