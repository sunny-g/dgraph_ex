use Mix.Config

config :dgraph_ex,
  adapter: DgraphEx.Client.Adapters.HTTP,
  endpoint: "http://localhost:8080"
