defmodule LiveAiElements.Golden do
  @moduledoc """
  Reads a recorded provider stream, and compares the part list it produces
  against a committed one.

  A recording is one file per turn under `test/fixtures/<adapter>/`:

    * `.jsonl` — one JSON event per line, which is what a provider sends over
      the wire and what a recorder can write without interpreting anything
    * `.exs` — a list of Elixir terms, for a provider whose events are structs
      and never were JSON

  Its golden is the same name with `.parts.exs`, and it holds the part list the
  reducer must produce, as `inspect/2` prints it. Both are committed, so a
  change to the reducer arrives in a pull request as a diff of what a reader
  would see rather than as a failing assertion nobody can picture.

  The golden is the parts themselves rather than a projection of them, because
  a projection is a second thing to keep right.

  ## Rewriting a golden

      GOLDEN=overwrite mix test

  Read the diff before committing it. A golden that is rewritten without being
  read is a test that asserts the code does what the code does.
  """

  alias LiveAiElements.Stream

  @dir Path.expand("../fixtures", __DIR__)

  @doc "Every recorded event in a fixture, in order."
  @spec events(String.t()) :: [term()]
  def events(name) do
    jsonl = Path.join(@dir, name <> ".jsonl")

    if File.exists?(jsonl) do
      jsonl |> File.read!() |> String.split("\n", trim: true) |> Enum.map(&Jason.decode!/1)
    else
      @dir |> Path.join(name <> ".exs") |> eval()
    end
  end

  @doc """
  Replays a fixture and returns the reducer state and every patch it emitted.
  """
  @spec replay(String.t(), module()) :: {Stream.t(), [Stream.patch()]}
  def replay(name, adapter) do
    Stream.reduce_all(Stream.new(adapter: adapter), events(name))
  end

  @doc """
  The part list a fixture's golden records.

  Writes the golden instead when `GOLDEN=overwrite` is set, and when the golden
  does not exist yet — a fixture with no golden is a new recording, and failing
  on it would only ask for the same file to be typed by hand.
  """
  @spec expected(String.t(), [LiveAiElements.Part.t()]) :: [LiveAiElements.Part.t()]
  def expected(name, parts) do
    path = Path.join(@dir, name <> ".parts.exs")

    if System.get_env("GOLDEN") == "overwrite" or not File.exists?(path) do
      File.write!(path, format(parts))
    end

    eval(path)
  end

  # Written the way `mix format` would write it. A golden the formatter rewrites
  # is a generated file edited by a hook, and this repository has already paid
  # for that once: the next run fails and the diff shows nothing to explain why.
  defp format(parts) do
    parts
    |> inspect(pretty: true, limit: :infinity, printable_limit: :infinity)
    |> Code.format_string!()
    |> IO.iodata_to_binary()
    |> Kernel.<>("\n")
  end

  @doc """
  One patch, as a name and the ids it touches.

  A golden of the patches themselves would be a golden of the parts twice over,
  since both `:insert_part` and `:set_state` carry a whole part. What is worth
  recording is the shape of the traffic: how many DOM operations a turn costs,
  and in what order.
  """
  @spec summarize(Stream.patch()) :: String.t()
  def summarize({:insert_part, part}), do: "insert #{part.id}"
  def summarize({:set_state, part}), do: "set #{part.id} #{part.status}"
  def summarize({:append_delta, id, _chunk}), do: "delta #{id}"

  defp eval(path) do
    {term, _bindings} = Code.eval_file(path)
    term
  end
end
