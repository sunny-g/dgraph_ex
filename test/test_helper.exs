ExUnit.configure(exclude: [:integration])
ExUnit.start()

Code.load_file("./test/model_company.exs")
Code.load_file("./test/model_person.exs")

defmodule TestHelpers do
  @moduledoc false

  def clean_format(item) when is_binary(item) do
    item
    |> String.replace(~r/(\s+)/, " ")
    |> String.trim()
  end
end

defmodule TestHelpers.RequestMock do
  @moduledoc false

  use ExUnit.Case, async: true
  import Mox
  alias DgraphEx.Client.Adapters.HTTP.RequestMock

  def assert_exec_params({expected_path, expected_body, expected_headers}) do
    expect(RequestMock, :exec, fn path, body, headers ->
      assert path == expected_path
      assert body == expected_body
      assert headers == expected_headers
      {:error, nil}
    end)
  end
end
