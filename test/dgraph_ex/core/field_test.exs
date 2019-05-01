defmodule DgraphEx.Core.FieldTest do
  use ExUnit.Case, async: true
  doctest DgraphEx.Core.Field

  alias DgraphEx.Core.Field
  alias DgraphEx.Core.Expr.Uid

  test "a field as_setter can render `uid pred uid .` correctly " do
    my_field = %Field{
      subject: %Uid{value: "1234", type: :literal},
      type: :uid_literal,
      predicate: :owner,
      object: %Uid{value: "5678", type: :literal}
    }

    assert Field.as_setter(my_field) == "<1234> <owner> <5678> ."
  end

  test "put_object works with a geo field" do
    some_location = [-112.44615353350031, 33.35600630797468]

    the_field =
      %Field{
        subject: %Uid{value: "1234", type: :literal},
        type: :geo,
        predicate: :location
      }
      |> Field.put_object(some_location)

    assert the_field.object == some_location
  end

  test "geo point renders correctly" do
    some_location = [-112.44615353350031, 33.35600630797468]

    the_field =
      %Field{
        subject: %Uid{value: "1234", type: :literal},
        type: :geo,
        predicate: :location
      }
      |> Field.put_object(some_location)

    assert the_field.object == some_location

    assert Field.as_setter(the_field) ==
             "<1234> <location> \"{'type':'Point','coordinates':[-112.44615353350031,33.35600630797468]}\"^^<geo:geojson> ."
  end

  test "geo polygon renders correctly" do
    some_polygon = [
      [
        [-122.503325343132, 37.73345766902749],
        [-122.503325343132, 37.733903134117966],
        [-122.50271648168564, 37.733903134117966],
        [-122.50271648168564, 37.73345766902749],
        [-122.503325343132, 37.73345766902749]
      ]
    ]

    the_field =
      %Field{
        subject: %Uid{value: "1234", type: :literal},
        type: :geo,
        predicate: :some_polygon
      }
      |> Field.put_object(some_polygon)

    assert the_field.object == some_polygon

    assert Field.as_setter(the_field) ==
             "<1234> <some_polygon> \"{'type':'Polygon','coordinates':[[[-122.503325343132,37.73345766902749],[-122.503325343132,37.733903134117966],[-122.50271648168564,37.733903134117966],[-122.50271648168564,37.73345766902749],[-122.503325343132,37.73345766902749]]]}\"^^<geo:geojson> ."
  end

  test "a field can be of type password and be put_objected and renders correctly" do
    the_field =
      %Field{
        subject: %Uid{value: "1234", type: :literal},
        type: :password,
        predicate: :user_pw
      }
      |> Field.put_object("12345")

    assert the_field.object == "12345"
    assert Field.as_setter(the_field) == "<1234> <user_pw> \"12345\"^^<pwd:password> ."
  end
end
