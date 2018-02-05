for path <- Path.wildcard("tmp/test*"), do: File.rm_rf!(path)
ExUnit.start()
