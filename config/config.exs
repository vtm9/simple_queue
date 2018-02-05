use Mix.Config

config :simple_queue,
  # file extension for queue segments
  buffer_extension: ".buff",
  timed_extension: ".[0-9A-F]*",
  timeout: 1_000_000,
  # queue segment size 64MB
  segment: 64 * 1024 * 1024,
  chunk: 65_536,
  delay: 2000
