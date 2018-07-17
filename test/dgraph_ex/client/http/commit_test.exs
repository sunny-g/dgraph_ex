defmodule DgraphEx.Client.HTTP.UnitTest.CommitTest do
  use ExUnit.Case, async: true
  import Mox
  import TestHelpers.ExecMock
  alias DgraphEx.Client.HTTP

  describe "HTTP.commit/2" do
    setup :verify_on_exit!

    test "should set transaction id in path" do
      expected_path = "/commit/13"
      expected_body = "[]"
      keys = []

      assert_exec_params({expected_path, expected_body, %{}})
      HTTP.commit(keys, [txid: 13])
    end

    test "should set keys in request body" do
      expected_path = "/commit/13"
      keys = [
        "AAALX3ByZWRpY2F0ZV8AAAAAAAAAAAI=",
        "AAAHYmFsYW5jZQAAAAAAAAAAAg==",
        "AAALX3ByZWRpY2F0ZV8AAAAAAAAAAAE=",
        "AAAHYmFsYW5jZQAAAAAAAAAAAQ=="
      ]
      expected_body = ~s(["AAALX3ByZWRpY2F0ZV8AAAAAAAAAAAI=","AAAHYmFsYW5jZQAAAAAAAAAAAg==","AAALX3ByZWRpY2F0ZV8AAAAAAAAAAAE=","AAAHYmFsYW5jZQAAAAAAAAAAAQ=="])

      assert_exec_params({expected_path, expected_body, %{}})
      HTTP.commit(keys, [txid: 13])
    end
  end
end
