defmodule Stack do
    def next_input(inputs) do
      {Stream.drop(inputs, 1), Enum.at(inputs, 0)}
    end

    def convert(i) do
      if !is_binary(i) || i == nil do
        i
      else
        i = to_int(i)
        if is_integer(i) do
          i
        else
          i = to_float(i)
          if is_float(i) do
            i
          else
            try do
              elem(Code.eval_string(i, :"warnings-as-errors"), 0)
            rescue
              _ -> i
            end
          end
        end
      end

    end

    defp to_int(n) do
      case Integer.parse(n) do
        {num, ""} -> num
        _ -> n
      end
    end

    defp to_float(n) do
      case Float.parse(n) do
        {num, ""} -> num
        _ -> n
      end
    end

    defp to_list(a) when is_list(a), do: a
    defp to_list(a), do: [a]

    def pop(stack, inputs) do
      if length(stack) == 0 do
        {inputs, input} = next_input(inputs);
        {convert(input), stack, inputs}
      else
        {elem, stack} = List.pop_at(stack, 0)
        {elem, stack, inputs}
      end
    end
    def peek(stack, inputs) when length(stack) > 0, do: {inputs, hd(stack)}
    def peek(_stack, inputs) do
      {Stream.drop(inputs, 1), convert(Enum.at(inputs, 0))}
    end

    def run(inputs1, stack1, fun) do
      result = case :erlang.fun_info(fun)[:arity] do
        0 ->
          {fun.(), stack1, inputs1}
        1 ->
          {elem, stack, inputs} = pop(stack1, inputs1)
          {fun.(elem), stack, inputs}
        2 ->
          {a, stack, inputs} = pop(stack1, inputs1)
          {b, stack, inputs} = pop(stack, inputs)
          {fun.(a, b), stack, inputs}
      end

      case result do
        {{inputs, res}, stack, _} -> {res ++ stack, inputs}
        {res, stack, inputs} -> {to_list(res) ++ stack, inputs}
      end
    end

    defguard is_digit(n) when n in ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]

    def dextend(s) when is_binary(s), do: String.slice(s, 0..(String.length(s) - 2))
    def dextend_sequence(s) when is_binary(s) do
      [Stream.iterate(s, &dextend/1)
      |> Enum.take(String.length(s))]
    end
end
