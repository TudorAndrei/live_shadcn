defmodule LiveShadcnTools.Style do
  @moduledoc """
  Reads a shadcn style sheet.

  The `.tsx` sources are only half of shadcn's styling. Each class string starts
  with a `cn-` class — `cn-accordion-trigger`, `cn-accordion-content` — and
  those classes are defined in `apps/v4/registry/styles/style-<name>.css`:

      .style-vega {
        .cn-accordion-content {
          @apply data-open:animate-accordion-down data-closed:animate-accordion-up text-sm;
        }
      }

  That matters for more than looks. The rule above reads `data-closed`, an
  attribute the `.tsx` never mentions and the Base UI page does not document. A
  port reviewed from the `.tsx` alone would never set it, and the collapse
  animation would silently not run.

  So the style sheet is a source of contract, not only of appearance, and the
  spec records what its rules read alongside what the class strings read.
  """

  @doc """
  Every `cn-` rule in a style sheet, as `%{class => utilities}`.

  Nested rules contribute to their own class, so a rule that styles a
  descendant does not leak its utilities into the parent.
  """
  def rules(css) do
    ~r/\.(cn-[a-z0-9-]+)\s*\{/
    |> Regex.scan(css, return: :index)
    |> Enum.map(fn [{at, length}, {name_at, name_length}] ->
      {binary_part(css, name_at, name_length), body(css, at + length)}
    end)
    |> Enum.map(fn {class, body} -> {class, utilities(body)} end)
    |> Enum.reject(fn {_class, utilities} -> utilities == "" end)
    |> Map.new()
  end

  @doc "The style names a sheet index declares, most-preferred first."
  def names(index) do
    ~r/name:\s*"([a-z0-9-]+)"/
    |> Regex.scan(index, capture: :all_but_first)
    |> List.flatten()
    |> Enum.uniq()
  end

  # Everything the rule applies at its own level. A nested selector inside it
  # styles something else, so its utilities are skipped here and picked up when
  # the scan reaches that selector on its own.
  defp utilities(body) do
    body
    |> strip_nested()
    |> then(&Regex.scan(~r/@apply\s+([^;]+);/, &1, capture: :all_but_first))
    |> List.flatten()
    |> Enum.join(" ")
    |> String.split()
    |> Enum.join(" ")
  end

  defp strip_nested(body), do: do_strip(body, 0, "")

  defp do_strip("", _depth, acc), do: acc

  defp do_strip(<<c, rest::binary>>, depth, acc) do
    case c do
      ?{ -> do_strip(rest, depth + 1, acc)
      ?} -> do_strip(rest, max(depth - 1, 0), acc)
      _ when depth > 0 -> do_strip(rest, depth, acc)
      _ -> do_strip(rest, depth, acc <> <<c>>)
    end
  end

  defp body(css, at) do
    finish = scan(css, at, 1)
    binary_part(css, at, finish - at)
  end

  defp scan(css, at, depth) do
    case css do
      <<_::binary-size(^at), ?{, _::binary>> -> scan(css, at + 1, depth + 1)
      <<_::binary-size(^at), ?}, _::binary>> when depth == 1 -> at
      <<_::binary-size(^at), ?}, _::binary>> -> scan(css, at + 1, depth - 1)
      <<_::binary-size(^at), _, _::binary>> -> scan(css, at + 1, depth)
      _ -> byte_size(css)
    end
  end
end
