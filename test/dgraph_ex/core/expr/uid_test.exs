defmodule DgraphEx.Core.Expr.UidTest do
  use ExUnit.Case, async: true
  doctest DgraphEx.Core.Expr.Uid

  import DgraphEx
  alias DgraphEx.Core.Expr.Uid
  alias DgraphEx.Core.Query.Block

  test "uid given a string renders a plain-old uid literal" do
    assert uid("0x9") |> Uid.render() == "<0x9>"
  end

  test "uid given a list of strings renders a multi-arg uid expr" do
    assert uid(["0x9", "0x10"]) |> Uid.render() == "uid(0x9, 0x10)"
  end

  test "uid given a list of atoms renders a multi-arg uid expr" do
    assert uid([:a, :b, :c]) |> Uid.render() == "uid(a, b, c)"
  end

  test "uid in a block renders as expression when given an atom/var" do
    assert Block.render(
             {[
                friends: uid(:b),
                name: :name@en
              ]}
           ) == "{ friends: uid(b) name: name@en }"
  end
end
