defmodule DgraphEx.Client.Services.Transaction do
  @moduledoc """
  GenServer for tracking a single Dgraph transaction's state
  """

  use GenServer
  alias DgraphEx.Client
  alias Client.Adapters.HTTP
  alias Client.{LinRead, Response}
  alias Client.Transaction, as: Tx
  require OK
  require Tx

  @type name :: {:via, module, {module, Tx.id()}}
  @type start_opts :: [lin_read: LinRead.t()]

  @adapter Application.get_env(:dgraph_ex, :adapter, HTTP)

  ##############################################################################
  # PUBLIC METHODS
  ##############################################################################

  @doc """
  Spawns a new Transaction process
  """
  @spec start_link(opts :: start_opts()) :: GenServer.on_start()
  def start_link(lin_read: lin_read) do
    GenServer.start_link(__MODULE__, lin_read)
  end

  @doc false
  @spec get_txid(pid :: pid()) :: Tx.id()
  def get_txid(pid), do: GenServer.call(pid, :get_txid)

  @doc false
  @spec get_keys(pid :: pid()) :: Tx.keys()
  def get_keys(pid), do: GenServer.call(pid, :get_keys)

  @doc false
  @spec get_lin_read(pid :: pid()) :: LinRead.t()
  def get_lin_read(pid), do: GenServer.call(pid, :get_lin_read)

  @doc """
  Given a Dgraph.Client.Response struct, update the transaction's state
  (namely, it's `lin_read` map)
  """
  @spec update(pid :: pid(), response :: Base.response()) ::
          {:ok, Base.response()} | {:error, Base.error() | :cannot_update_tx_state}
  def update(pid, %Response{} = response) do
    OK.with do
      tx <- Response.get_tx(response)
      nil <- GenServer.call(pid, {:update_tx, tx})
      {:ok, response}
    else
      :not_found ->
        {:ok, response}

      _ ->
        {:error, :cannot_update_tx_state}
    end
  end

  @spec teardown(pid :: pid()) :: {:ok, nil}
  def teardown(pid) do
    :ok = GenServer.stop(pid, :normal)
    {:ok, nil}
  end

  ##############################################################################
  # CALLBACKS
  ##############################################################################

  @impl true
  def init(%{} = lin_read) do
    if LinRead.valid?(lin_read) do
      Process.flag(:trap_exit, true)
      {:ok, %Tx{lin_read: lin_read}}
    else
      {:stop, :invalid_lin_read}
    end
  end

  @impl true
  def handle_call(:get_txid, _from, %Tx{start_ts: txid} = state) do
    {:reply, txid, state}
  end

  def handle_call(:get_keys, _from, %Tx{keys: keys} = state) do
    {:reply, keys, state}
  end

  def handle_call(:get_lin_read, _from, %Tx{lin_read: lin_read} = state) do
    {:reply, lin_read, state}
  end

  def handle_call({:update_tx, new_tx}, _, state) do
    case Tx.update(state, new_tx) do
      {:ok, new_state} ->
        {:reply, {:ok, nil}, new_state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  @doc """
  Handles transaction process terminations

  A transaction process can be terminated in one of three ways:
    1. the user successfully commits or aborts the transaction (:normal)
    2. a mutation within a transaction fails, resulting in a subsequent attempt
    to abort the transaction
    3. the supervising process terminates (:shutdown or {:shutdown, _}), upon
    which the transaction process will attempt to abort the transaction itself
  Because the return value is ignored, the transaction MAY still exist (from
  the perspective of the Dgraph server)
  """
  def terminate(:normal, _), do: nil

  def terminate(:shutdown, %Tx{start_ts: txid}), do: _terminate(txid)
  def terminate({:shutdown, _}, %Tx{start_ts: txid}), do: _terminate(txid)

  defp _terminate(txid), do: @adapter.abort(txid)
end
