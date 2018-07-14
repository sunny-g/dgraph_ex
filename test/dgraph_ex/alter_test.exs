defmodule DgraphEx.AlterTest do
  use ExUnit.Case, async: true
  doctest DgraphEx.Alter

  test "render/1 renders an alter struct correctly" do
    one = %DgraphEx.Field{index: true, subject: "123", predicate: "loves", object: "cooking", type: :string}
    two = %DgraphEx.Field{index: true, subject: "123", predicate: "hates", object: "mean birds", type: :string}
    assert [one, two]
      |> DgraphEx.Alter.new
      |> DgraphEx.Alter.render == "loves: string @index(string) .\nhates: string @index(string) .\n"
  end
end
