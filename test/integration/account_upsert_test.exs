defmodule DgraphEx.Integration.Account do
  use DgraphEx.Core.Vertex
  alias DgraphEx.Core.{Changeset, Mutate}

  @allowed_fields [:first, :last, :age, :when]
  @required_fields [:first, :last, :age]

  vertex :account do
    field(:first, :string, index: [:term])
    field(:last, :string, index: [:hash])
    field(:age, :int, index: [:int])
    field(:when, :int)
  end

  def changeset(changes), do: changeset(%__MODULE__{}, changes)

  def changeset(account = %__MODULE__{}, changes) when is_map(changes) do
    account
    |> Changeset.cast(changes, @allowed_fields)
    |> Changeset.validate_required(@required_fields)
    |> Changeset.uncast()
  end

  def find_all(names) do
    """
      {
        all(func: anyofterms(first, "#{Enum.join(names, " ")}")) {
          first
          last
          age
        }
      }
    """
  end

  def find_one(%{first: first, last: last, age: age}) do
    """
      {
        find(func: eq(first, "#{first}")) @filter(eq(last, "#{last}") AND eq(age, "#{age}")) {
          uid: _uid_
        }
      }
    """
  end

  def mutate_new(account = %__MODULE__{}), do: Mutate.new(account)

  def mutate_update(uid, %{} = changes) do
    changeset =
      %__MODULE__{}
      |> Changeset.cast(changes, @allowed_fields)
      |> Changeset.uncast()

    case changeset do
      {:error, reason} ->
        {:error, reason}

      {:ok, account} ->
        {:ok, Mutate.update(account, uid)}
    end
  end
end

defmodule DgraphEx.Integration.AccountUpsertTest do
  @moduledoc false

  use ExUnit.Case
  alias DgraphEx.{Client, Integration}
  alias Client.Response
  alias Integration.Account
  require OK

  @moduletag :integration

  @schema Account.__vertex__(:fields)
  @firsts ["Paul", "Eric", "Jack", "John", "Martin"]
  @lasts ["Brown", "Smith", "Robinson", "Waters", "Taylor"]
  @ages [20, 25, 30, 35]
  @accounts Enum.flat_map(@firsts, fn first_name ->
              Enum.flat_map(@lasts, fn last_name ->
                Enum.map(@ages, fn age ->
                  {:ok, account} =
                    Account.changeset(%Account{}, %{
                      first: first_name,
                      last: last_name,
                      age: age
                    })

                  account
                end)
              end)
            end)

  setup_all do
    OK.with do
      pid <- Client.start_link()
      _ <- drop_all()
      _ <- set_schema()
      {:ok, client: pid}
    end
  end

  test "" do
    query = Account.find_all(@firsts)

    try_upsert(List.first(@accounts))
  end

  defp drop_all(), do: Client.alter(:drop_all)
  defp set_schema(), do: Client.alter(@schema)

  defp upsert(account) do

  end

  defp try_upsert(account) do
    query = Account.find_one(account)

    {:ok, tx_pid} = Client.new_transaction()

    OK.with do
      %Response{data: %{"find" => find}} <- Client.query(tx_pid, query)

      uid =
        if length(find) == 1 do
          find
          |> Enum.at(0)
          |> Map.get("uid")
        else
          mutation = Account.mutate_new(account)

          {:ok, res} = Client.mutate(tx_pid, mutation)
          %Response{uids: %{"account" => uid}} = res

          assert uid != ""
          uid
        end

      mutation <- Account.mutate_update(uid, %{
        when: DateTime.utc_now() |> DateTime.to_unix(:milliseconds)
      })

      _ <- Client.mutate(tx_pid, mutation)
      _ <- Client.commit(tx_pid)
    else
      _ ->
        Client.abort(tx_pid)
    end
  end
end
