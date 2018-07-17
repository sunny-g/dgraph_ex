defmodule DgraphEx.Client.HTTP.UnitTest.MutateTest do
  use ExUnit.Case, async: true
  import Mox
  import TestHelpers.ExecMock
  alias DgraphEx.Client.HTTP

  describe "HTTP.mutate/2" do
    setup :verify_on_exit!

    test "should set transaction id in path" do
      expected_path = "/mutate/12"
      expected_body = ""

      assert_exec_params({expected_path, expected_body, %{}})
      HTTP.mutate(expected_body, txid: 12)
    end

    test "should set CommitNow header" do
      expected_path = "/mutate/12"
      expected_body = ""
      expected_headers = %{"X-Dgraph-CommitNow" => true}

      assert_exec_params({expected_path, expected_body, expected_headers})
      HTTP.mutate(expected_body, [commit_now: true, txid: 12])
    end

    test "should set LinRead header" do
      expected_path = "/mutate/12"
      expected_body = ""
      expected_headers = %{"X-Dgraph-LinRead" => ~s({"1":13})}

      assert_exec_params({expected_path, expected_body, expected_headers})
      HTTP.mutate(expected_body, [lin_read: %{"1" => 13}, txid: 12])
    end

    test "should set transaction id in path and LinRead header" do
      expected_path = "/mutate/12"
      expected_body = ""
      expected_headers = %{
        "X-Dgraph-LinRead" => ~s({"1":12})
      }

      assert_exec_params({expected_path, expected_body, expected_headers})
      HTTP.mutate(expected_body, [txid: 12, lin_read: %{"1" => 12}])
    end

    test "should apply all transaction options" do
      expected_path = "/mutate/12"
      expected_body = ""
      expected_headers = %{
        "X-Dgraph-CommitNow" => true,
        "X-Dgraph-LinRead" => ~s({"1":12})
      }

      assert_exec_params({expected_path, expected_body, expected_headers})
      HTTP.mutate(expected_body, [txid: 12, commit_now: true, lin_read: %{"1" => 12}])
    end
  end
end
