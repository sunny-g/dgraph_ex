defmodule DgraphEx.Client.TransactionTest do
  use ExUnit.Case, async: true
  doctest DgraphEx.Client.Transaction

  alias DgraphEx.Client.Transaction

  describe "Transaction.add_keys/2" do
    test "should add single key" do
      state = %Transaction{keys: ["a"]}

      expected = %Transaction{keys: ["a", "b"]}
      assert Transaction.add_keys(state, "b") == expected
    end

    test "should add keys" do
      state = %Transaction{keys: ["a"]}

      expected = %Transaction{keys: ["a", "b", "c"]}
      assert Transaction.add_keys(state, ["b", "c"]) == expected
    end
  end

  describe "Transaction.merge_lin_reads/2" do
    test "" do
      state = %Transaction{lin_read: %{"1" => 13, "2" => 15}}

      expected = {:ok, %Transaction{lin_read: %{"1" => 17, "2" => 15}}}
      assert Transaction.merge_lin_reads(state, %{"1" => 17}) == expected
    end
  end
end
