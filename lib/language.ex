defmodule Atoms do
  import Stack

  def eval(stack, functions, index, inputs) do
    Enum.at(functions, index)
    |> String.replace(~r/\d{2}/, "\\0j")
    |> String.replace(~r/j\d/, "\\0j")
    |> String.graphemes
    |> Enum.reduce({stack, inputs}, fn(n, {stack, inputs}) ->
      top = peek(stack, inputs)
      IO.inspect top

      debug(stack, "stack")
      debug(n, "current")
      run(inputs, stack, case n do
        # print
        "p" when is_number(top) -> fn n -> IO.write(<<n>>); [] end
        "p" when is_binary(top) -> fn n -> IO.write(n); [] end
        "p" -> fn n -> IO.inspect(n); [] end
        "P" when is_number(top) -> fn n -> IO.write(n); [] end
        "P" when is_binary(top) -> fn n -> IO.puts(n); [] end
        "P" when is_list(top) -> fn n -> elem(List.pop_at(n, 0), 1) end

        # dup
        "D" -> fn a -> [a, a] end
        "d" -> fn a, b -> [List.duplicate(a, b)] end
        # ceil/chunk
        "C" when is_number(top) -> fn n -> round(Float.ceil(n)) end
        "C" when is_list(top) -> fn a, b -> [Enum.chunk_every(a, b)] end
        "c" when is_list(top) -> fn a, b -> [Enum.chunk_every(a, b, b, :discard)] end
        # increment/decrement
        ">" when is_number(top) -> fn n -> n + 1 end
        "<" when is_number(top) -> fn n -> n - 1 end
        # extend/dextend
        ">" when is_binary(top) -> fn s -> s <> String.last(s) end
        "<" when is_binary(top) -> &dextend/1
        # range
        "R" when is_number(top) -> fn n -> [Enum.to_list 1..n] end
        "r" when is_number(top) -> fn n -> [Enum.to_list 0..n] end
        # substrings
        "R" when is_binary(top) -> &dextend_sequence/1
        "r" when is_binary(top) -> &String.graphemes/1
        # reverse
        "r" -> fn a -> [Enum.reverse a] end
        # random
        "g" -> fn -> (if :rand.uniform(2) == 1, do: false, else: true) end
        # map
        "e" -> fn x -> [Enum.map(x, fn y -> hd(eval([y], functions, index + 1, inputs)) end)] end
        # any
        "a" -> fn x -> Enum.any?(x, fn y -> hd(eval([y], functions, index + 1, inputs)) end) end
        # filter
        "f" -> fn x -> [Enum.filter(x, fn y -> hd(eval([y], functions, index + 1, inputs)) end)] end
        # sum
        "s" when is_list(top) -> fn a -> Enum.sum a end
        "s" when is_integer(top) -> fn n -> Integer.digits(n) |> Enum.sum end
        # bool
        "!" -> fn x -> !x end
        "?" -> fn x -> !!x end
        # equal
        "=" -> fn a, b -> a==b end
        ":" -> fn a, b -> a===b end
        # add
        "+" -> fn
          a, b when is_number(a) and is_number(b) -> a + b
          a, b when is_binary(a) -> a <> b
          a, b when is_list(a) and is_list(b) -> [a ++ b]
        end
        # subtract
        "-" -> fn
          a, b when is_number(a) and is_number(b) -> a - b
          a, b when is_list(a) and is_list(b) -> [a -- b]
        end
        # multiply
        "*" -> fn
          a, b when is_number(a) and is_number(b) -> a * b
          a, b when is_list(a) and is_list(b) ->
            [Enum.zip(a, b)
            |> Enum.map(fn {x, y} -> x * y end)]
        end
        "^" -> fn
          a, b when is_number(a) and is_number(b) -> Maths.pow(a,b)
          a, b when is_list(a) and is_list(b) ->
            [Enum.zip(a, b)
            |> Enum.map(fn {x, y} -> Math.pow(x, y) end)]
        end

        # divide
        "/" -> fn
          a, b when is_number(a) and is_number(b) -> a / b
          a, b when is_list(a) and is_list(b) ->
            [Enum.zip(a, b)
            |> Enum.map(fn {x, y} -> x / y end)]
        end
        # join digit
        "j" -> fn a, b -> b * 10 + a end
        # convert (str -> int) or (int -> str)
        "i" when is_binary(top) -> &String.to_integer/1
        "i" when is_number(top) -> &to_string/1
        "I" when is_binary(top) -> &String.to_float/1
        "I" when is_number(top) -> fn n -> String.length(to_string(n))
        "I" when is_list(top) -> &length/1

        n when is_digit(n) -> fn -> String.to_integer(n) end
        # inputs
        "_" -> fn ->
          {inputs, input} = next_input(inputs);
          {inputs, [convert input]}
        end
        "[" -> fn -> [convert(Enum.at(inputs, 0))] end
        "]" -> fn -> [convert(Enum.at(inputs, 1))] end
        "E" -> fn s -> case Code.eval_string(s, __ENV__) do {v, _} -> v end end
        " " -> fn -> [] end
      end)
    end)
    |> debug("end")
    |> elem(0)
  end

  def debug(msg, label \\ nil) do
    if Application.get_env(:panacea, :debug) do
      IO.inspect(msg, label: label, charlists: :as_lists)
    end
    msg
  end
end
