defmodule Maths do
  require Integer

  def pow(_, 0), do: 1
  def pow(x, n) when Integer.is_odd(n), do: x * pow(x, n - 1)
  def pow(x, n) do
    result = pow(x, div(n, 2))
    result * result
  end

  def divisors(1), do: []
  def divisors(n), do: [1 | divisors(2,n,:math.sqrt(n))] |> Enum.sort

  defp divisors(k,_n,q) when k>q, do: []
  defp divisors(k,n,q) when rem(n,k)>0, do: divisors(k+1,n,q)
  defp divisors(k,n,q) when k * k == n, do: [k | divisors(k+1,n,q)]
  defp divisors(k,n,q)                , do: [k,div(n,k) | divisors(k+1,n,q)]

  def product([]), do: 1
  def product([hd | tl]), do: hd * product(tl)

  def decomposition(n), do: decomposition(n, 2, [])

  defp decomposition(n, k, acc) when n < k*k, do: Enum.reverse(acc, [n])
  defp decomposition(n, k, acc) when rem(n, k) == 0, do: decomposition(div(n, k), k, [k | acc])
  defp decomposition(n, k, acc), do: decomposition(n, k+1, acc)
end
