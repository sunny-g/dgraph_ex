defmodule DgraphEx.Repo.Client do
  @moduledoc """
  Agent for tracking a single Dgraph client's state
  """

  use Agent
  alias DgraphEx.Client.{Base, LinRead, Response, Transaction}
  require OK

  defstruct latest_ts: 0,
            lin_read: %{}

  @type t :: %__MODULE__{
          latest_ts: boolean,
          lin_read: LinRead.t()
        }

  @doc false
  @spec start_link(initial_lin_read :: LinRead.t()) :: Agent.on_start()
  def start_link(initial_lin_read \\ %{}) when is_map(initial_lin_read) do
    Agent.start_link(
      __MODULE__,
      fn ->
        %__MODULE__{lin_read: initial_lin_read}
      end,
      name: __MODULE__
    )
  end

  @doc """
  Increments the client's transaction id counter, and returns the `txid` and the
  client's current `lin_read` map
  """
  @spec new_transaction() :: {:ok, {Transaction.id(), LinRead.t()}}
  def new_transaction() do
    {txid, lin_read} =
      Agent.get_and_update(__MODULE__, fn state ->
        %__MODULE__{latest_ts: latest_ts, lin_read: lin_read} = state
        txid = latest_ts + 1
        {{txid, lin_read}, %__MODULE__{state | latest_ts: txid}}
      end)

    {:ok, {txid, lin_read}}
  end

  @doc """
  Given a Dgraph.Client.Response struct, update the client's state (namely,
  it's `lin_read` map) and return {:ok, nil}
  """
  @spec update(response :: Base.response()) ::
          {:ok, Base.response()} | {:error, Base.error() | :cannot_update_client_state}
  def update(response) do
    OK.with do
      new_lin_read <- Response.get_lin_read(response)

      nil <-
        Agent.get_and_update(__MODULE__, fn state ->
          %__MODULE__{lin_read: lin_read} = state

          case LinRead.merge_lin_reads(lin_read, new_lin_read) do
            {:ok, new_lin_read} ->
              {{:ok, nil}, %__MODULE__{state | lin_read: new_lin_read}}

            {:error, reason} ->
              {{:error, reason}, state}
          end
        end)

      {:ok, response}
    else
      {:error, _} ->
        {:error, :cannot_update_client_state}
    end
  end
end
