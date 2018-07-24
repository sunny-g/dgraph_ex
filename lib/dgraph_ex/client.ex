defmodule DgraphEx.Client do
  @moduledoc """
  GenServer that tracks client and transaction state for client-server
  linearizability


  get client state
  create new transaction state by incrementing client state
  wrap alter, mutate and query, passing in client state
  pass altered functions into func
  call func within a task
  call either commit or rollback when done

  spec =
  DynamicSupervisor.start_child(__MODULE__, child_spec)

  stub = %{
    alter: &alter(&1),
    mutate: &mutate(&1),
    query: &query(&1),
    rollback: &rollback(&1),
  }

  func.()
  {:ok, nil}
  """

  use Supervisor
  alias DgraphEx.Client
  alias Client.{Adapters, Base, Services}
  alias Adapters.HTTP
  alias Client.Transaction, as: Tx
  alias Services.Client, as: ClientService
  alias Services.Transaction, as: TxService
  require OK
  require Tx

  @default_tx_child_spec_opts [restart: :transient, shutdown: 10_000]
  @initial_lin_read Application.get_env(:dgraph_ex, :lin_read, %{})
  @adapter Application.get_env(:dgraph_ex, :adapter, HTTP)

  @registry_name :dgraph_ex_transaction_registry
  @registry_spec {Registry, [keys: :unique, name: @registry_name]}
  @client_spec {Repo.Client, [@initial_lin_read]}
  @initial_children [@registry_spec, @client_spec]

  @spec start_link(_ :: any) :: Supervisor.on_start()
  def start_link(_) do
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @doc false
  @spec new_transaction() :: {:ok, Tx.id()} | {:error, any}
  def new_transaction() do
    OK.with do
      {txid, lin_read} <- ClientService.new_transaction()
      tx_spec = new_transaction_spec(txid, lin_read)
      _pid <- Supervisor.start_child(__MODULE__, tx_spec)
      {:ok, txid}
    end
  end

  @doc """
  Executes a Dgraph alteration
  """
  @spec alter(alteration :: Base.alter_input()) :: {:ok, Base.response()} | {:error, Base.error()}
  defdelegate alter(alteration), to: @adapter

  @doc """
  Executes a mutation within a transaction

  If the mutation results in a Dgraph error, the transaction is aborted and the
  return value is the original mutation error
  """
  @spec mutate(txid :: Tx.id(), mutation :: Base.mutate_input(), commit_now :: boolean) ::
          {:ok, Base.response()} | {:error, Base.error()}
  def mutate(txid, mutation, commit_now \\ false) do
    name = via_tuple(txid)
    lin_read = TxService.get_lin_read(name)
    opts = [txid: txid, commit_now: commit_now, lin_read: lin_read]

    OK.with do
      res <- @adapter.mutate(mutation, opts)
      _ <- update(name, res)
      {:ok, res}
    else
      {:dgraph_error, errors} ->
        abort(txid)
        {:error, {:dgraph_error, errors}}

      reason ->
        {:error, reason}
    end
  end

  @doc """
  Executes a query within a transaction
  """
  @spec query(txid :: Tx.id(), query :: Base.query_input()) ::
          {:ok, Base.response()} | {:error, Base.error()}
  def query(txid, query_input) do
    name = via_tuple(txid)
    lin_read = TxService.get_lin_read(name)
    opts = [lin_read: lin_read]

    OK.with do
      res <- @adapter.query(query_input, opts)
      _ <- update(name, res)
      {:ok, res}
    end
  end

  @doc """
  Aborts
  """
  @spec abort(txid :: Tx.id()) :: {:ok, Base.response()} | {:error, Base.error()}
  def abort(txid) do
    name = via_tuple(txid)

    OK.with do
      res <- @adapter.abort(txid)
      _ <- TxService.teardown(name)
      {:ok, res}
    end
  end

  @doc false
  @spec commit(txid :: Tx.id()) :: {:ok, Base.response()} | {:error, Base.error()}
  def commit(txid) do
    name = via_tuple(txid)
    keys = TxService.get_keys(name)

    OK.with do
      res <- @adapter.commit(keys, txid: txid)
      _ <- TxService.teardown(name)
      {:ok, res}
    end
  end

  ##############################################################################
  # PRIVATE
  ##############################################################################

  @spec via_tuple(txid :: Tx.id()) :: Tx.name()
  defp via_tuple(txid) when Tx.is_id(txid) do
    {:via, Registry, {@registry_name, txid}}
  end

  @spec new_transaction_spec(txid :: Tx.id(), lin_read :: LinRead.t()) :: any
  defp new_transaction_spec(txid, lin_read)
       when Tx.is_id(txid)
       when is_map(lin_read) do
    args = [name: via_tuple(txid), lin_read: lin_read]
    opts = [id: {TxService, txid}] ++ @default_tx_child_spec_opts
    Supervisor.child_spec({TxService, args}, opts)
  end

  @spec update(tx_name :: TxService.name(), response :: Base.response()) ::
          {:ok, Base.response()} | {:error, Base.error()}
  defp update(tx_name, response) do
    OK.with do
      _ <- ClientService.update(response)
      _ <- TxService.update(tx_name, response)
      {:ok, response}
    end
  end

  ##############################################################################
  # CALLBACKS
  ##############################################################################

  @impl true
  def init(_arg) do
    Supervisor.init(@initial_children, strategy: :one_for_one)
  end
end
