defmodule GeneratorsTest do
  use ExUnit.Case
  use PropCheck

  property "callect 1", [:verbose] do
    forall bin <- binary() do
      #       テスト          メトリクス
      collect(is_binary(bin), to_range(10, byte_size(bin)))
    end
  end

  def to_range(m, n) do
    base = div(n, m)
    {base * m, (base + 1) * m}
  end

  property "重複があってもマップ内の全キーを探索する", [:verbose] do
    forall kv <- list({key(), val()}) do
      m = Map.new(kv)
      for {k,_v} <- kv, do: Map.fetch!(m, k)
      uniques =
        kv
          |> List.keysort(0)
          |> Enum.dedup_by(fn {x, _} -> x end)
      collect(true, {:dupes, to_range(5, length(kv) - length(uniques))})
    end
  end

  def key(), do: oneof([range(1,10), integer()])
  def val(), do: term()
end
