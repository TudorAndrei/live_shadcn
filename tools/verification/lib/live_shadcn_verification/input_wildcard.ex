defmodule LiveShadcnVerification.InputWildcard do
  @moduledoc false

  # Keep the native wildcard engine, file metadata and lexical symlink paths.
  # Only directory contents already excluded from identity inputs are pruned.
  def read_link_info(file), do: :file.read_link_info(file)
  def read_file_info(file), do: :file.read_file_info(file)

  def list_dir(dir) do
    if generated_directory_path?(IO.chardata_to_string(dir) <> "/") do
      {:ok, []}
    else
      case :file.list_dir(dir) do
        {:ok, files} -> {:ok, for(file <- files, hd(file) != ?., do: file)}
        other -> other
      end
    end
  end

  def generated_directory_path?(path) do
    String.contains?(path, "/node_modules/") or
      String.contains?(path, "/_build/") or
      String.contains?(path, "/priv/static/assets/") or
      String.contains?(path, "/assets/css/upstream/")
  end
end
