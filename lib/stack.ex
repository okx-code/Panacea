defmodule Stack do
    def next_input({inputs, index}) do
      {{inputs, rem(index + 1, length(inputs))}, Enum.at(inputs, index)}
    end

    def convert(i) do
      i = to_int(i)
      if is_integer(i) do
        i
      else
        i = to_float(i)
        if is_float(i) do
          i
        else
          case Code.eval_string(i) do
            {v, _} -> v
          end
        end
      end
    end

    defp to_int(n) do
      case Integer.parse(n) do
        :error -> n
        {num, ""} -> num
      end
    end

    defp to_float(n) do
      case Float.parse(n) do
        :error -> n
        {num, ""} -> num
      end
    end

    defp to_list(a) when is_list(a), do: a
    defp to_list(a), do: [a]

    def pop(stack, inputs) do
      if length(stack) == 0 do
        {inputs, input} = next_input(inputs);
        {convert(input), stack, inputs}
      else
        {elem, ins} = List.pop_at(stack, 0)
        {elem, stack, ins}
      end
    end
    def peek(stack, _) when length(stack) > 0, do: hd(stack)
    def peek(_, inputs) do
      {_, input} = next_input(inputs);
      [convert input]
    end

    def run(inputs1, stack1, fun) do
      result = case :erlang.fun_info(fun)[:arity] do
        0 ->
          {to_list(fun.()), stack1, inputs1}
        1 ->
          {elem, stack, inputs} = pop(stack1, inputs1)
          {to_list(fun.(elem)), stack, inputs}
        2 ->
          {a, stack, inputs} = pop(stack1, inputs1)
          {b, stack, inputs} = pop(stack, inputs)
          {to_list(fun.(a, b)), stack, inputs}
      end

      case result do
        {res, stack, inputs} -> {res ++ stack, inputs}
      end
    end

    defguard is_digit(n) when n in ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]

    def dextend(s) when is_binary(s), do: String.slice(s, 0..(String.length(s) - 2))
    def dextend_sequence(s) when is_binary(s) do
      [Stream.iterate(s, &dextend/1)
      |> Enum.take(String.length(s))]
    end
end
