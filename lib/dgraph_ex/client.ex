defmodule DgraphEx.Client do
  @moduledoc """
  Supervisor that tracks client and transaction state for client-server
  linearizability
  """

  use Supervisor
  alias DgraphEx.{Client, Core}
  alias Client.{Adapters, Base, Services}
  alias Core.Vertex
  alias Adapters.HTTP
  alias Client.Transaction, as: Tx
  alias Services.Client, as: ClientService
  alias Services.Transaction, as: TxService
  require OK
  require Tx

  @default_tx_child_spec_opts [restart: :transient, shutdown: 10_000]
  @initial_lin_read Application.get_env(:dgraph_ex, :lin_read, %{})
  @adapter Application.get_env(:dgraph_ex, :adapter, HTTP)

  @registry_spec {Registry, [keys: :unique, name: @registry_name]}
  @client_spec {ClientService, @initial_lin_read}
  @initial_children [
    @registry_spec,
    @client_spec
  ]

  @spec start_link(_ :: any) :: Supervisor.on_start()
  def start_link(_ \\ []) do
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @doc false
  @spec new_transaction() :: {:ok, Tx.id()} | {:error, any}
  def new_transaction() do
    lin_read = ClientService.get_lin_read()
    tx_spec = new_transaction_spec(lin_read)
    Supervisor.start_child(__MODULE__, tx_spec)
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
  @spec mutate(tx_pid :: pid(), mutation :: Base.mutate_input(), Base.mutate_opts()) ::
          {:ok, Base.response()} | {:error, Base.error()}
  def mutate(tx_pid, mutation, opts \\ [commit_now: false])

  def mutate(tx_pid, mutation, commit_now: commit_now) do
    txid = TxService.get_txid(tx_pid)
    lin_read = TxService.get_lin_read(tx_pid)
    opts = [txid: txid, commit_now: commit_now, lin_read: lin_read]

    OK.with do
      res <- @adapter.mutate(mutation, opts)
      _ <- update(tx_pid, res)
      {:ok, res}
    else
      reason = {:dgraph_error, errors} ->
        IO.warn(
          "failed to mutate, aborting transaction #{txid} with errors #{
            Enum.map(errors, &Poison.encode!/1)
          }"
        )

        abort(tx_pid)
        {:error, reason}

      reason ->
        {:error, reason}
    end
  end

  @doc """
  Executes a query within a transaction
  """
  @spec query(tx_pid :: pid(), query :: Base.query_input()) ::
          {:ok, Base.response()} | {:error, Base.error()}
  def query(tx_pid, query_input) do
    lin_read = TxService.get_lin_read(tx_pid)
    opts = [lin_read: lin_read]

    OK.with do
      res <- @adapter.query(query_input, opts)
      _ <- update(tx_pid, res)
      {:ok, res}
    end
  end

  @doc """
  Aborts
  """
  @spec abort(tx_pid :: pid()) :: {:ok, Base.response()} | {:error, Base.error()}
  def abort(tx_pid) do
    txid = TxService.get_txid(tx_pid)

    OK.with do
      res <- @adapter.abort(txid)
      _ <- TxService.teardown(tx_pid)
      {:ok, res}
    end
  end

  @doc false
  @spec commit(tx_pid :: pid()) :: {:ok, Base.response()} | {:error, Base.error()}
  def commit(tx_pid) do
    txid = TxService.get_txid(tx_pid)
    keys = TxService.get_keys(tx_pid)

    OK.with do
      res <- @adapter.commit(keys, txid: txid)
      _ <- TxService.teardown(tx_pid)
      {:ok, res}
    end
  end

  ##############################################################################
  # PRIVATE
  ##############################################################################

  @spec new_transaction_spec(lin_read :: LinRead.t()) :: any
  defp new_transaction_spec(lin_read) when is_map(lin_read) do
    args = [lin_read: lin_read]
    Supervisor.child_spec({TxService, args}, @default_tx_child_spec_opts)
  end

  @spec update(tx_pid :: pid(), response :: Base.response()) ::
          {:ok, Base.response()} | {:error, Base.error()}
  defp update(tx_pid, response) do
    OK.with do
      _ <- ClientService.update(response)
      _ <- TxService.update(tx_pid, response)
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
