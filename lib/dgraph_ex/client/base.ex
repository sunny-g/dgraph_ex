defmodule DgraphEx.Client.Base do
  @moduledoc """
  The base Dgraph Client behaviour

  Defines methods for making requests directly against Dgraph
  """

  alias DgraphEx.{
    Alter,
    Client,
    Delete,
    Field,
    Query,
    Set
  }

  alias Client.{Base, LinRead, Transaction}
  alias Base.Response

  @type path :: bitstring

  @type executor :: (Request.t() -> any)
  @type error :: Response.error()
  @type response :: Response.t()

  @type abort_input :: Transaction.id()
  @type alter_input ::
          :drop_all
          | {:drop_attr, bitstring}
          | bitstring
          | module
          | [%Field{}]
          | %Alter{}
  @type alter_opts :: [lin_read: LinRead.t()]
  @type commit_input :: Transaction.keys()
  @type commit_opts :: [txid: Transaction.id()]
  @type mutate_input ::
          bitstring
          | %Set{}
          | %Delete{}
  @type mutate_opts :: [txid: Transaction.id(), commit_now: boolean, lin_read: LinRead.t()]
  @type query_input ::
          [...]
          | %Query{}
          | bitstring
          | {bitstring, query_vars}
  @type query_opts :: [lin_read: LinRead.t()]
  @type query_vars :: %{optional(bitstring) => any} | []

  @type send_opts ::
          alter_opts
          | commit_opts
          | mutate_opts
          | query_opts

  @doc false
  @callback alter(alteration :: alter_input) :: {:ok, response} | {:error, error}

  @doc false
  @callback mutate(mutation :: mutate_input, opts :: mutate_opts) ::
              {:ok, response} | {:error, error}

  @doc false
  @callback query(query :: query_input, opts :: query_opts) :: {:ok, response} | {:error, error}

  @doc false
  @callback abort(txid :: abort_input) :: {:ok, response} | {:error, error}

  @doc false
  @callback commit(keys :: commit_input, opts :: commit_opts) :: {:ok, response} | {:error, error}
end
