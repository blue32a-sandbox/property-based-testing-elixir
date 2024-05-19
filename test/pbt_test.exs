defmodule PbtTest do
  use ExUnit.Case
  use PropCheck

  property "always works" do
    forall type <- my_type() do
      boolean(type)
    end
  end

  property "最大の要素を見つける" do
    forall x <- non_empty(list(integer())) do
      biggest(x) == List.last(Enum.sort(x))
    end
  end

  def boolean(_) do
    true
  end

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

  def my_type() do
    term()
  end
end
