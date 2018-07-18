defmodule DgraphEx.Core.AlterTest do
  use ExUnit.Case, async: true
  doctest DgraphEx.Core.Alter

  alias DgraphEx.Core.{Alter, Field}

  test "render/1 renders an alter struct correctly" do
    one = %Field{
      index: true,
      subject: "123",
      predicate: "loves",
      object: "cooking",
      type: :string
    }

    two = %Field{
      index: true,
      subject: "123",
      predicate: "hates",
      object: "mean birds",
      type: :string
    }

    assert [one, two]
           |> Alter.new()
           |> Alter.render() == "loves: string @index(string) .\nhates: string @index(string) .\n"
  end
end
