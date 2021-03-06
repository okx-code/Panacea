defmodule Main do
  import Atoms

  def main(args) do
    cond do
      length(args) > 0 ->
        functions = read_lines(File.read!(hd(args)))
        lines = read_lines(IO.read(:all))
        inputs = if length(lines) == 0, do: [], else: Stream.cycle(lines)
        stack = eval([], functions, 0, inputs)

        IO.inspect(case args do
          [_, "-t"] -> Enum.at(stack, 0)
          [_, "-j"] -> Enum.join(stack)
          [_, "-o"] -> System.halt(0)
          [_] -> stack
        end, charlists: :as_lists, width: :infinity, limit: :infinity)
      true ->
        IO.write """
        Usage: ./panacea <file> [options]
        Options:
          -t: Print top of stack instead of entire stack
          -j: Join stack together at end
          -o: Don't print the stack
        """
    end
  end

  def read_lines(x) do
    x
    |> String.split("\n")
    |> Enum.reverse()
    |> tl()
    |> Enum.reverse()
  end
end
