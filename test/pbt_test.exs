defmodule PbtTest do
  use ExUnit.Case
  use PropCheck

  property "always works" do
    forall type <- my_type() do
      boolean(type)
    end
  end

  def boolean(_) do
    true
  end

  def my_type() do
    term()
  end

  property "最大の要素を見つける" do
    forall x <- non_empty(list(integer())) do
      Pbt.biggest(x) == model_biggest(x)
    end
  end

  def model_biggest(list) do
    List.last(Enum.sort(list))
  end

  property "最後の数を選ぶ" do
    forall {list, known_last} <- {list(number()), number()} do
      known_list = list ++ [known_last]
      known_last == List.last(known_list)
    end
  end

  property "ソート済みリストは整列したペアを持つ" do
    forall list <- list(term()) do
      is_orderd(Enum.sort(list))
    end
  end

  def is_orderd([a, b | t]) do
    a <= b and is_orderd([b | t])
  end

  def is_orderd(_) do
    true
  end

  property "ソート済みリストはサイズを維持する" do
    forall l <- list(number()) do
      length(l) == length(Enum.sort(l))
    end
  end

  property "何も要素が追加されなかった" do
    forall l <- list(number()) do
      sorted = Enum.sort(l)
      Enum.all?(sorted, fn element -> element in l end)
    end
  end

  property "何も要素が削除されなかった" do
    forall l <- list(number()) do
      sorted = Enum.sort(l)
      Enum.all?(l, fn element -> element in sorted end)
    end
  end
end
