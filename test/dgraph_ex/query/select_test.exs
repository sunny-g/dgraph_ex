defmodule DgraphEx.Query.SelectTest do
  use ExUnit.Case, async: true
  doctest DgraphEx.Query.Select
  import TestHelpers

  import DgraphEx
  alias DgraphEx.ModelPerson, as: Person
  alias DgraphEx.ModelCompany, as: Company

  test "select can destructure a module with a struct into a block for selection" do
    result =
      query()
      |> func(:person, eq(:name, "Jason"))
      |> select(Person)
      |> render

    assert result ==
             clean_format("""
               {
                 person(func: eq(name, \"Jason\")) {
                   _uid_
                   age
                   name
                   works_at
                 }
               }
             """)
  end

  test "select can destructure a struct into a block for selection" do
    result =
      query()
      |> func(:person, eq(:name, "Jason"))
      |> select(%Person{})
      |> render

    assert result ==
             clean_format("""
               {
                 person(func: eq(name, \"Jason\")) {
                   _uid_
                   age
                   name
                   works_at
                 }
               }
             """)
  end

  test "select can destructure nested models into a select" do
    result =
      query()
      |> func(:person, eq(:name, "Jason"))
      |> select(%Person{
        works_at: %Company{
          owner: %Person{}
        }
      })
      |> render

    assert result ==
             clean_format("""
               {
                 person(func: eq(name, \"Jason\")) {
                   _uid_
                   age
                   name
                   works_at {
                     _uid_
                     location
                     name
                     owner
                     {
                       _uid_
                       age
                       name
                       works_at
                     }
                   }
                 }
               }
             """)
  end

  test "a model's field can be removed from a select by setting it to false" do
    assert query()
           |> func(:person, eq(:name, "Jason"))
           |> select(%Person{
             works_at: false,
             age: false
           })
           |> render
           |> clean_format ==
             clean_format("""
               {
                 person(func: eq(name, \"Jason\")) {
                   _uid_
                   name
                 }
               }
             """)
  end

  test "a complex model query" do
    assert query()
           |> func(:person, eq(:name, "Jason"))
           |> select(%Person{
             age: false,
             works_at: %Company{
               owner: false
             }
           })
           |> render
           |> clean_format ==
             clean_format("""
               {
                 person(func: eq(name, \"Jason\")) {
                   _uid_
                   name
                   works_at {
                     _uid_
                     location
                     name
                   }
                 }
               }
             """)
  end
end
