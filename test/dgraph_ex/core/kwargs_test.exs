defmodule DgraphEx.Core.KwargsTest do
  use ExUnit.Case, async: true
  doctest DgraphEx.Core.Kwargs
  import TestHelpers

  import DgraphEx
  import DgraphEx.Core.Kwargs
  alias DgraphEx.ModelPerson, as: Person

  test "a query call returns a query" do
    assert query([]) == %DgraphEx.Core.Query{}
  end

  test "a simple get func select query renders correctly" do
    assert clean_format("""
             {
               person(func: eq(name, \"Jason\")) {
                 name
                 age
                 height
               }
             }
           """) ==
             render(
               parse(
                 get: :person,
                 func: eq(:name, "Jason"),
                 select: {:name, :age, :height}
               )
             )
  end

  test "aliasing with :as works" do
    assert clean_format("""
             {
               person as var(func: eq(name, \"Jason\")) {
                 name
                 age
                 height
               }
             }
           """) ==
             render(
               parse(
                 as: :person,
                 func: eq(:name, "Jason"),
                 select: {:name, :age, :height}
               )
             )
  end

  test ":filter works" do
    assert clean_format("""
             {
               person(func: eq(name, \"Jason\")) @filter(lt(age, 15)) {
                 name
                 age
                 height
               }
             }
           """) ==
             render(
               parse(
                 get: :person,
                 func: eq(:name, "Jason"),
                 filter: lt(:age, 15),
                 select: {:name, :age, :height}
               )
             )
  end

  test "directives works" do
    assert clean_format("""
             {
               person(func: eq(name, \"Jason\")) @normalize @cascade @ignorereflex {
                 name
                 age
                 height
               }
             }
           """) ==
             render(
               parse(
                 get: :person,
                 func: eq(:name, "Jason"),
                 normalize: true,
                 cascade: true,
                 ignorereflex: true,
                 select: {
                   :name,
                   :age,
                   :height
                 }
               )
             )
  end

  test "directives list works" do
    assert TestHelpers.clean_format("""
             {
               person(func: eq(name, \"Jason\")) @cascade @ignorereflex {
                 name
                 age
                 height
               }
             }
           """) ==
             parse(
               get: :person,
               func: eq(:name, "Jason"),
               directives: [:cascade, :ignorereflex],
               select: {
                 :name,
                 :age,
                 :height
               }
             )
             |> render
  end

  test "groupby works" do
    assert TestHelpers.clean_format("""
             {
               @groupby(age) {
                 name
                 age
               }
             }
           """) ==
             render(
               parse(
                 groupby: :age,
                 select: {
                   :name,
                   :age
                 }
               )
             )
  end

  test "executors work" do
    assert parse(orderasc: :age, first: 5) |> render == "(orderasc: age, first: 5)"
  end

  test "complex query" do
    genres_count_var =
      parse(
        as: :genres,
        func: has(:"~genre"),
        select: {
          as(:num_genres, count(:"~genre"))
        }
      )

    reversed_genre =
      parse(
        orderasc: val(:num_genres),
        first: 5,
        select: {
          :name@en,
          genres: val(:num_genres)
        }
      )

    genres_selector =
      parse(
        get: :genres,
        func: uid(:genres),
        orderasc: :name@en,
        select: {
          :name@en,
          "~genre": reversed_genre
        }
      )

    complex_query =
      parse([
        genres_count_var,
        genres_selector
      ])

    assert render(complex_query) ==
             TestHelpers.clean_format("""
               {
                 genres as var(func: has(~genre)) {
                   num_genres as count(~genre)
                 }
                 genres(func: uid(genres), orderasc: name@en) {
                   name@en
                   ~genre (orderasc: val(num_genres), first: 5) {
                     name@en
                     genres: val(num_genres)
                   }
                 }
               }
             """)
  end

  test "render set from model" do
    assert set(
             set: %Person{
               name: "jason",
               age: 33
             }
           )
           |> render
           |> clean_format ==
             clean_format("""
               {
                 set {
                   _:person <name> \"jason\"^^<xs:string> .
                   _:person <age> \"33\"^^<xs:int> .
                 }
               }
             """)
  end

  # test "mutation schema works" do
  #   assert set([
  #     schema: Person
  #   ])
  #   |> render
  #   |> clean_format == clean_format("""
  #     mutation {
  #       schema {
  #         name: string .
  #         age: int .
  #         works_at: uid .
  #       }
  #     }
  #   """)
  # end

  # test "mutation delete works for a field" do
  #   assert query([
  #     delete: field(uid("1234567"), "*", "*")
  #   ])
  #   |> render
  #   |> clean_format == clean_format("""
  #     mutation {
  #       delete {
  #         <1234567> * * .
  #       }
  #     }
  #   """)
  # end

  # test "mutation delete works for tuple of fields " do
  #   assert query([
  #     delete: {
  #       field(uid("1234567"), "*", "*"),
  #       field(uid("1234567890"), "*", "*"),
  #     }
  #   ])
  #   |> render
  #   |> clean_format == clean_format("""
  #     {
  #       delete {
  #         <1234567> * * .
  #         <1234567890> * * .
  #     dd  }
  #     }
  #   """)
  # end

  #   test "a complex mutation" do
  #     assert query([
  #       delete: {
  #         field(uid("0x123"), :name, "Jason"),
  #       },
  #       set: %Person{
  #         name: "Not Jason",
  #       },
  #       schema: Person,
  #     ])
  #     |> render
  #     |> clean_format == clean_format("""
  #       mutation {
  #         delete {
  #           <0x123> <name> \"Jason\" .
  #         }
  #         set {
  #           _:person <name> \"Not Jason\"^^<xs:string> .
  #         }
  #         schema {
  #           name: string .
  #           age: int .
  #           works_at: uid .
  #         }
  #       }
  #     """)
  #   end
end
