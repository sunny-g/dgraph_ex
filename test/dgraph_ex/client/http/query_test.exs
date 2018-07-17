defmodule DgraphEx.Client.HTTP.UnitTest.QueryTest do
  use ExUnit.Case, async: true
  import Mox
  import TestHelpers.ExecMock
  alias DgraphEx.Client.HTTP

  describe "HTTP.query/1 and HTTP.query/2" do
    setup :verify_on_exit!

    test "should set non-transaction defaults" do
      expected_body = ""
      assert_exec_params({"/query", expected_body, %{}})
      HTTP.query(expected_body)
    end

    test "should set LinRead header" do
      expected_path = "/query"
      expected_body = ""
      expected_headers = %{"X-Dgraph-LinRead" => ~s({"1":12})}

      assert_exec_params({expected_path, expected_body, expected_headers})
      HTTP.query(expected_body, lin_read: %{"1" => 12})
    end

    test "should set query vars header" do
      expected_path = "/query"
      expected_body = ""
      vars = %{a: 13}
      expected_headers = %{"X-Dgraph-Vars" => ~s({"$a":"13"})}

      assert_exec_params({expected_path, expected_body, expected_headers})
      HTTP.query({expected_body, vars})
    end

    test "should set all appropriate headers" do
      expected_path = "/query"
      expected_body = ""
      lin_read = %{"1" => 12}
      vars = %{a: 13}

      expected_headers = %{
        "X-Dgraph-LinRead" => ~s({"1":12}),
        "X-Dgraph-Vars" => ~s({"$a":"13"})
      }

      assert_exec_params({expected_path, expected_body, expected_headers})
      HTTP.query({expected_body, vars}, lin_read: lin_read)
    end
  end
end
