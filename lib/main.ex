defmodule Main do
  import Atoms

  def main(args) do
    cond do
      length(args) >= 1 ->
        functions = read_lines(File.read!(hd(args)))
        inputs = read_lines(IO.read(:all))
        stack = eval([], functions, 0, inputs)

        IO.inspect(case args do
          [_, "-t"] -> hd(stack)
          [_, "-j"] -> Enum.join(stack)
          [_] ->  stack
        end, charlists: :as_lists, width: :infinity, limit: :infinity)
      true ->
        IO.write """
        Usage: ./panacea <file> [options]
        Options:
          -t: Print top of stack instead of entire stack
          -j: Join stack together at end
        """
    end
  end

  def read_lines(x) do
    x
    |> String.split("\n")
    |> Enum.reverse
    |> tl
    |> Enum.reverse
  end
end
