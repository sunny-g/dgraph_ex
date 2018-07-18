defmodule DgraphEx.Client.HTTP.UnitTest.AbortTest do
  use ExUnit.Case, async: true
  import Mox
  import TestHelpers.RequestMock

  alias DgraphEx.Client.HTTP

  describe "HTTP.abort/1" do
    setup :verify_on_exit!

    test "should set transaction id in path" do
      assert_exec_params({"/abort/12", "", %{}})
      HTTP.abort(12)
    end

    test "should fail with invalid transaction id" do
      assert HTTP.abort(-1) == {:error, :invalid_txid}
    end
  end
end
