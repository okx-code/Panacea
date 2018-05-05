defmodule Atoms do
  import Stack

  def eval(stack, functions, index, inputs) do
    # debug(Enum.to_list(inputs), "inputs")

    Enum.at(functions, index)
    |> String.replace(~r/\d{2}/, "\\0j")
    |> String.replace(~r/j\d/, "\\0j")
    |> String.graphemes
    |> Enum.reduce({stack, inputs}, fn(n, {stack, inputs}) ->
      {_, top} = peek(stack, inputs)

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
        "o" when is_number(top) -> fn n -> <<n>>; end

        # uniqify
        "o" when is_list(top) -> fn n -> [Enum.uniq(n)] end

        # proper divisors
        "v" when is_number(top) -> &([Maths.divisors(&1)])
        "v" when is_binary(top) -> &String.capitalize/1
        "v" when is_list(top) -> &Enum.join/1
        # divisors
        "V" when is_number(top) -> &([Maths.divisors(&1) ++ [&1]])
        "V" when is_binary(top) -> &String.split/1
        "V" when is_list(top) -> &(Enum.join(&1, " "))

        # dup
        "D" -> fn a -> [a, a] end
        # rev
        "G" -> fn a, b -> [b, a] end
         # ceil/chunk
        "C" when is_number(top) -> fn n -> round(Float.ceil(n)) end
        "C" when is_list(top) -> fn a, b -> [Enum.chunk_every(a, b)] end
        "C" when is_binary(top) -> &String.upcase/1
        "c" when is_number(top) -> fn n -> round(Float.floor(n)) end
        "c" when is_list(top) -> fn a, b -> [Enum.chunk_every(a, b, b, :discard)] end
        "c" when is_binary(top) -> &String.downcase/1
        # increment/extend
        ">" -> fn
          n when is_number(n) -> n + 1
          n when is_binary(n) -> n <> String.last(n)
          n when is_list(n) -> Enum.at(-1, n)
         end
        "<" -> fn
          n when is_number(n) -> n - 1
          n when is_binary(n) -> dextend(n)
          n when is_list(n) -> Enum.at(0, n)
        end
        # range
        "R" when is_number(top) -> fn n -> [Enum.to_list 1..n] end
        "r" when is_number(top) -> fn n -> [Enum.to_list 0..n] end
        # substrings
        "R" when is_binary(top) -> &dextend_sequence/1
        "r" when is_binary(top) -> fn n -> [String.graphemes(n)] end
        # reverse
        "r" when is_list(top) -> fn a -> [Enum.reverse a] end
        # random
        "g" -> fn -> (if :rand.uniform(2) == 1, do: false, else: true) end
        # map
        "e" -> fn x -> [Enum.map(x, fn y -> hd(eval([y], functions, index + 1, inputs)) end)] end
        # any
        "a" -> fn x -> Enum.any?(x, fn y -> hd(eval([y], functions, index + 1, inputs)) end) end
        # filter
        "f" -> fn x -> [Enum.filter(x, fn y -> hd(eval([y], functions, index + 1, inputs)) end)] end
        # nth that matches
        "n" when is_number(top) -> fn x ->
          Stream.iterate(0, &(&1 + 1))
          |> Stream.filter(fn y -> hd(eval([y], functions, index + 1, inputs)) end)
          |> Enum.at(x) end
        "N" when is_number(top) -> fn x ->
          Stream.iterate(1, &(&1 + 1))
          |> Stream.filter(fn y -> hd(eval([y], functions, index + 1, inputs)) end)
          |> Enum.at(x) end
        # run and swap with input and top of stack
        "u" -> fn x -> [x] ++ [convert(Enum.at(inputs, 0))] ++ [hd(eval([x], functions, index + 1, inputs))] end
        # while unchanging stack
        "w" -> fn x -> while_unchanging(x, &(hd(eval([&1], functions, index + 1, inputs)))) end
        # sum
        "s" -> fn
          n when is_list(n) -> Enum.sum(n)
          n when is_integer(n) -> n |> Integer.digits() |> Enum.sum()
          n when is_binary(n) -> String.reverse(n)
        end
        # product
        "d" -> fn
          n when is_list(n) -> Maths.product(n)
          n when is_integer(n) -> n |> Integer.digits() |> Maths.product()
          n when is_binary(n) -> String.last(n)
        end
        # bool
        "!" -> fn x -> !x end
        "?" -> fn x -> !!x end
        # equal
        "=" -> fn a, b -> a==b end
        ":" -> fn a, b -> a===b end
        ";" -> fn a, b -> a&&b end
        # sqrt
        "q" -> fn
          n when is_number(n) -> :math.sqrt(n)
          n when is_list(n) -> tl(n)
          n when is_binary(n) -> String.slice(n, 1..-1)
        end
        # add
        "+" -> fn
          a, b when is_binary(a) and is_number(b) -> String.duplicate(a, b)
          a, b when is_number(a) and is_binary(b) -> String.duplicate(b, a)
          a, b when is_binary(a) and is_binary(b) -> a <> b
          a, b when is_list(a) and is_list(b) -> [a ++ b]
          a, b when is_number(a) and is_number(b) -> a + b
          a, b when is_list(a) and is_number(b) -> [Enum.map(a, &(&1 + b))]
          a, b when is_number(a) and is_list(b) -> [Enum.map(b, &(&1 + a))]
        end
        # subtract
        "-" -> fn
          a, b when is_number(a) and is_number(b) -> a - b
          a, b when is_list(a) and is_list(b) -> [a -- b]
          a, b when is_list(a) and is_number(b) -> [Enum.map(a, &(&1 - b))]
          a, b when is_number(a) and is_list(b) -> [Enum.map(b, &(a - &1))]
        end
        # multiply
        "*" -> fn
          a, b when is_number(a) and is_number(b) -> a * b
          a, b when is_list(a) and is_list(b) ->
            [Enum.zip(a, b)
            |> Enum.map(fn {x, y} -> x * y end)]
          a, b when is_list(a) and is_number(b) -> [Enum.map(a, &(&1 * b))]
          a, b when is_number(a) and is_list(b) -> [Enum.map(b, &(&1 * a))]
        end
        "^" -> fn
          a, b when is_number(a) and is_number(b) -> Maths.pow(a,b)
          a, b when is_list(a) and is_list(b) ->
            [Enum.zip(a, b)
            |> Enum.map(fn {x, y} -> Maths.pow(x, y) end)]
          a, b when is_list(a) and is_number(b) -> [Enum.map(a, &(Maths.pow(&1, b)))]
          a, b when is_number(a) and is_list(b) -> [Enum.map(b, &(Maths.pow(a, &1)))]
        end
        # divide
        "/" -> fn
          a, b when is_number(a) and is_number(b) -> a / b
          a, b when is_list(a) and is_list(b) ->
            [Enum.zip(a, b)
            |> Enum.map(fn {x, y} -> x / y end)]
          a, b when is_list(a) and is_number(b) -> [Enum.map(a, &(&1 / b))]
          a, b when is_number(a) and is_list(b) -> [Enum.map(b, &(a / &1))]
        end

        # prime
        "m" -> fn
          n when is_number(n) -> length(Maths.divisors(n)) == 1
        end
        "z" -> fn
          n when is_number(n) -> [Maths.decomposition(n)]
        end

        "{" -> fn
          n when is_number(n) -> rem(n, 2) == 0
          n when is_binary(n) -> rem(String.length(n), 2) == 0
          n when is_list(n) -> rem(length(n), 2) == 0
        end
        "}" when is_number(top) -> fn
          n when is_number(n) -> rem(n, 2) == 1
          n when is_binary(n) -> rem(String.length(n), 2) == 1
          n when is_list(n) -> rem(length(n), 2) == 1
        end
        "$" -> &is_number/1
        "\\" -> &is_list/1
        "~" -> &is_binary/1

        # join digit
        "j" -> fn
          a, b when is_number(a) and is_number(b) -> b * 10 + a
          a, b when is_list(a) and is_number(b) -> [List.duplicate(a, b)]
          a, b when is_number(a) and is_list(b) -> [List.duplicate(b, a)]
         end
        # convert (str -> int) or (int -> str)
        "i" when is_binary(top) -> fn n ->
          case Integer.parse(n) do
            {value, ""} -> value
            {_value, _part} -> String.to_float(n)
          end
        end
        "i" when is_number(top) -> &to_string/1
        "I" when is_binary(top) -> &String.to_float/1
        "I" when is_number(top) -> fn n -> String.length(to_string(n)) end
        "I" when is_list(top) -> &length/1

        n when is_digit(n) -> fn -> String.to_integer(n) end
        # inputs
        "_" -> fn ->
          {inputs, input} = next_input(inputs);
          {inputs, [convert input]}
        end
        "[" -> fn -> [convert(Enum.at(inputs, 0))] end
        "]" -> fn -> [convert(Enum.at(inputs, 1))] end
        "E" when is_binary(top) -> fn s -> case Code.eval_string(s, __ENV__) do {v, _} -> v end end
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
