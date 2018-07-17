defmodule DgraphEx.Client.ResponseTest do
  @moduledoc false

  use ExUnit.Case, async: true
  alias DgraphEx.Client.Response
  alias DgraphEx.Client.Transaction, as: Tx

  describe "get_tx/1" do
    test "should get tx object from Dgraph response" do
      response = %Response{
        data: %{code: "Success", message: "Done", uids: {}},
        extensions: %{
          txn: %{
            start_ts: 4,
            keys: [
              "AAALX3ByZWRpY2F0ZV8AAAAAAAAAAAI=",
              "AAAHYmFsYW5jZQAAAAAAAAAAAg==",
              "AAALX3ByZWRpY2F0ZV8AAAAAAAAAAAE=",
              "AAAHYmFsYW5jZQAAAAAAAAAAAQ=="
            ],
            lin_read: %{
              ids: %{"1": 17}
            }
          }
        }
      }

      tx = %Tx{
        complete: false,
        start_ts: 4,
        keys: [
          "AAALX3ByZWRpY2F0ZV8AAAAAAAAAAAI=",
          "AAAHYmFsYW5jZQAAAAAAAAAAAg==",
          "AAALX3ByZWRpY2F0ZV8AAAAAAAAAAAE=",
          "AAAHYmFsYW5jZQAAAAAAAAAAAQ=="
        ],
        lin_read: %{"1": 17}
      }

      assert Response.get_tx(response) == {:ok, tx}
    end
  end
end
