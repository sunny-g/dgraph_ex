defmodule DgraphEx.Client.TransactionTest do
  use ExUnit.Case, async: true
  doctest DgraphEx.Client.Transaction

  alias DgraphEx.Client.Transaction

  describe "Transaction.add_keys/2" do
    test "should add single key" do
      state = %Transaction{keys: ["a"]}
      new_key = "b"

      expected = %Transaction{keys: ["a", new_key]}
      assert Transaction.add_keys(state, new_key) == expected
    end

    test "should add keys" do
      state = %Transaction{keys: ["a"]}
      new_keys = ["b", "c"]

      expected = %Transaction{keys: ["a", "b", "c"]}
      assert Transaction.add_keys(state, new_keys) == expected
    end
  end

  describe "Transaction.merge_lin_reads/2" do
    test "should preserve an existing max key" do
      state = %Transaction{lin_read: %{"1" => 17, "2" => 15}}
      new_lin_read = %{"1" => 13}

      expected = {:ok, %Transaction{lin_read: %{"1" => 17, "2" => 15}}}
      assert Transaction.merge_lin_reads(state, new_lin_read) == expected
    end

    test "should merge in new max key" do
      state = %Transaction{lin_read: %{"1" => 13, "2" => 15}}
      new_lin_read = %{"1" => 17}

      expected = {:ok, %Transaction{lin_read: %{"1" => 17, "2" => 15}}}
      assert Transaction.merge_lin_reads(state, new_lin_read) == expected
    end
  end
end
