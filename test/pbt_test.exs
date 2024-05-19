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
end
