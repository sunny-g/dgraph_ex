defmodule DgraphEx.Client.TransactionTest do
  use ExUnit.Case, async: true
  alias DgraphEx.Client.Transaction

  describe "Transaction.add_keys/2" do
    test "should add single key" do
      state = %Transaction{keys: ["a"]}
      key = "b"

      expected = %Transaction{keys: ["a", "b"]}
      assert Transaction.add_keys(state, key) == expected
    end

    test "should add keys" do
      state = %Transaction{keys: ["a"]}
      keys = ["b", "c"]

      expected = %Transaction{keys: ["a", "b", "c"]}
      assert Transaction.add_keys(state, keys) == expected
    end
  end

  describe "Transaction.merge_lin_reads/2" do
    test "" do
      state = %Transaction{lin_read: %{"1" => 13, "2" => 15}}
      new_lin_read = %{"1" => 17}

      expected = %Transaction{lin_read: %{"1" => 17, "2" => 15}}
      assert Transaction.merge_lin_reads(state, new_lin_read) == expected
    end
  end
end
