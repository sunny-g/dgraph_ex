defmodule DgraphEx.FilterTest do
  use ExUnit.Case
  doctest DgraphEx.Query.Filter

  import DgraphEx
  alias DgraphEx.Query.Filter

  test "render filter" do
    assert filter(eq(:beef, "moo"), {
      :name
    }) |> Filter.render == "@filter(eq(beef, \"moo\")) { name }"
  end

  test "func and filter work together" do
    result =
      query()
      |> func(:person, eq(:name, "Jason"))
      |> filter(eq(:age, 42), {
        :name
      })
      |> render

    assert result ==  "{ person(func: eq(name, \"Jason\")) @filter(eq(age, 42)) { name } }"
  end

end