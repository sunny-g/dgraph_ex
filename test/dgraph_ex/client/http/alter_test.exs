defmodule DgraphEx.Client.HTTP.UnitTest.AlterTest do
  use ExUnit.Case, async: true
  import Mox
  import TestHelpers.RequestMock

  alias DgraphEx.Client.HTTP

  describe "HTTP.alter/1" do
    setup :verify_on_exit!

    test "should set default path" do
      expected_body = ""
      assert_exec_params({"/alter", expected_body, %{}})
      HTTP.alter(expected_body)
    end
  end
end
