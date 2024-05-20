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
      Pbt.biggest(x) == model_biggest(x)
    end
  end

  property "最後の数を選ぶ" do
    forall {list, known_last} <- {list(number()), number()} do
      known_list = list ++ [known_last]
      known_last == List.last(known_list)
    end
  end

  def boolean(_) do
    true
  end

  def model_biggest(list) do
    List.last(Enum.sort(list))
  end

  def my_type() do
    term()
  end
end
