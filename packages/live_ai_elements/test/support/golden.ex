defmodule LiveAiElements.Golden do
  @moduledoc """
  Reads a recorded provider stream, and compares the part list it produces
  against a committed one.

  A recording is a `.jsonl` file: one provider event per line, in the order the
  socket delivered them. Its golden is the same name with `.parts.json`, and it
  holds the part list the reducer must produce.

  Both are committed, so a change to the reducer arrives in a pull request as a
  diff of what a reader would see rather than as a failing assertion nobody can
  picture.

  ## Rewriting a golden

      GOLDEN=overwrite mix test

  Read the diff before committing it. A golden that is rewritten without being
  read is a test that asserts the code does what the code does.
  """

  alias LiveAiElements.Stream

  @dir Path.expand("../fixtures", __DIR__)

  @doc "Every recorded event in a fixture, in order."
  @spec events(String.t()) :: [map()]
  def events(name) do
    @dir
    |> Path.join(name <> ".jsonl")
    |> File.read!()
    |> String.split("\n", trim: true)
    |> Enum.map(&Jason.decode!/1)
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
  @spec expected(String.t(), [LiveAiElements.Part.t()]) :: [map()]
  def expected(name, parts) do
    path = Path.join(@dir, name <> ".parts.json")
    actual = Enum.map(parts, &encode/1)

    if System.get_env("GOLDEN") == "overwrite" or not File.exists?(path) do
      File.write!(path, Jason.encode_to_iodata!(actual, pretty: true) ++ ["\n"])
    end

    path |> File.read!() |> Jason.decode!()
  end

  @doc "One part, as the golden records it."
  @spec encode(LiveAiElements.Part.t()) :: map()
  def encode(part) do
    %{
      "id" => part.id,
      "type" => Atom.to_string(part.type),
      "status" => Atom.to_string(part.status),
      "seq" => part.seq,
      "text" => part.text,
      "meta" => Map.new(part.meta, fn {key, value} -> {to_string(key), value} end)
    }
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
end
