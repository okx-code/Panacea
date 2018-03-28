defmodule Stack do
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

    def pop(stack, default) do
      if length(stack) == 0 do
        {convert(default), stack}
      else
        List.pop_at(stack, 0)
      end
    end
    def peek(stack, _) when length(stack) > 0, do: hd(stack)
    def peek(_, default), do: convert(default)

    def run(default, stack, fun) do
      case :erlang.fun_info(fun)[:arity] do
        0 ->
          to_list(fun.()) ++ stack
        1 ->
          {elem, stack} = pop(stack, default)
          to_list(fun.(elem)) ++ stack
        2 ->
          {a, stack} = pop(stack, default)
          {b, stack} = pop(stack, default)
          to_list(fun.(a, b)) ++ stack
      end
    end

    defguard is_digit(n) when n in ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]

    def dextend(s) when is_binary(s), do: String.slice(s, 0..(String.length(s) - 2))
    def dextend_sequence(s) when is_binary(s) do
      [Stream.iterate(s, &dextend/1)
      |> Enum.take(String.length(s))]
    end
end
