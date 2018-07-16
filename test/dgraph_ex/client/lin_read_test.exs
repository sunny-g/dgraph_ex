defmodule DgraphEx.Client.LinReadTest do
  use ExUnit.Case, async: true
  doctest DgraphEx.Client.LinRead

  alias DgraphEx.Client.LinRead

  describe "LinRead.merge_lin_reads/2" do
    test "should preserve an existing max key" do
      client = %{"1" => 14, "2" => 13}
      new = %{"2" => 12}

      expected = {:ok, %{"1" => 14, "2" => 13}}
      assert LinRead.merge_lin_reads(client, new) == expected
    end

    test "should merge in new max key" do
      client = %{"1" => 14, "2" => 13}
      new = %{"1" => 17}

      expected = {:ok, %{"1" => 17, "2" => 13}}
      assert LinRead.merge_lin_reads(client, new) == expected
    end
  end
end
