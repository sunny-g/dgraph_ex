use Mix.Config

ip_addr = System.get_env("DOCKER_HOST")
  |> String.split("://")
  |> Enum.at(1)
  |> String.split(":")
  |> Enum.at(0)
endpoint = "http://#{ip_addr}:8080"

config :dgraph_ex,
  adapter: DgraphEx.Client.Adapters.HTTP,
  endpoint: endpoint
