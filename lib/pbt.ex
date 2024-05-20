defmodule Pbt do
  def biggest([head | tail]) do
    biggest(tail, head)
  end

  defp biggest([], max) do
    max
  end

  defp biggest([head | tail], max) when head >= max do
    biggest(tail, head)
  end

  defp biggest([head | tail], max) when head < max do
    biggest(tail, max)
  end
end
