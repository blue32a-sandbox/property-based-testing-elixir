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

  property "aggregate", [:verbose] do
    suits = [:club, :diamond, :heart, :spade]

    forall hand <- vector(5, {oneof(suits), choose(1, 13)}) do
      aggregate(true, hand)
    end
  end

  property "aggregateを試す為のエスケープのテスト", [:verbose] do
    forall str <- utf8() do
      aggregate(escape(str), classes(str))
    end
  end

  defp escape(_), do: true

  def classes(str) do
    l = letters(str)
    n = numbers(str)
    p = punctuation(str)
    o = String.length(str) - (l+n+p)
    [{:letters, to_range(5, l)},
     {:numbers, to_range(5, n)},
     {:punctuation, to_range(5, p)},
     {:other, to_range(5, o)}]
  end

  def letters(str) do
    is_letter = fn c -> (c >= ?a && c <= ?z) || (c >= ?A && c <= ?Z) end
    length(for <<c::utf8 <- str>>, is_letter.(c), do: 1)
  end

  def numbers(str) do
    is_num = fn c -> c >= ?0 && c <= ?9 end
    length(for <<c::utf8 <- str>>, is_num.(c), do: 1)
  end

  def punctuation(str) do
    is_punctuation = fn c -> c in '.,;:\'"-' end
    length(for <<c::utf8 <- str>>, is_punctuation.(c), do: 1)
  end

  property "resize", [:verbose] do
    forall bin <- resize(150, binary()) do
      collect(is_binary(bin), to_range(10, byte_size(bin)))
    end
  end

  property "profile 1", [:verbose] do
    forall profile <- [
             name: resize(10, utf8()),
             age: pos_integer(),
             bio: resize(350, utf8())
           ] do
      name_len = to_range(10, String.length(profile[:name]))
      bio_len = to_range(300, String.length(profile[:bio]))
      aggregate(true, name: name_len, bio: bio_len)
    end
  end

  property "profile 2", [:verbose] do
    forall profile <- [
             name: utf8(),
             age: pos_integer(),
             bio: sized(s, resize(s * 35, utf8()))
           ] do
      name_len = to_range(10, String.length(profile[:name]))
      bio_len = to_range(300, String.length(profile[:bio]))
      aggregate(true, name: name_len, bio: bio_len)
    end
  end

  property "ナイーブなキューの生成" do
    forall list <- list({term(), term()}) do
      q = :queue.from_list(list)
      :queue.is_queue(q)
    end
  end

  property "letマクロを使ったキュー" do
    forall q <- queue() do
      :queue.is_queue(q)
    end
  end

  def queue() do
    let list <- list({term(), term()}) do
      :queue.from_list(list)
    end
  end

  def non_empty(list_type) do
    such_that l <- list_type, when: l != [] and l != <<>>
  end

  def non_empty_map(gen) do
    such_that g <- gen, when: g != %{}
  end

  # def even(), do: such_that n <- integer(), when: rem(n, 2) == 0
  # def uneven(), do: such_that n <- integer(), when: rem(n, 2) != 0
  # 制約を変換に置き換える
  def even() do
    let n <- integer(), do: n * 2
  end
  def uneven() do
    let n <- integer(), do: n * 2 + 1
  end

  def text_like() do
    let l <-
        list(
          frequency([
            {80, range(?a, ?z)},
            {10, ?\s},
            {1, ?\n},
            {1, oneof([?., ?-, ?!, ??, ?,])},
            {1, range(?0, ?9)}
          ])
        ) do
      to_string(l)
    end
  end

  def mostly_sorted() do
    gen = list(
      frequency([
        {5, sorted_list()},
        {1, list()}
      ])
    )
    let lists <- gen, do: Enum.concat(lists)
  end

  def sorted_list() do
    let l <- list(), do: Enum.sort(l)
  end

  def path() do
    sized(
      size,
      path(size, {0,0}, [], %{{0,0} => :seen}, [])
    )
  end

  def path(0, _current, acc, _seen, _ignore) do
    acc
  end

  def path(_max, _current, acc, _seen, [_,_,_,_]) do
    acc
  end

  def path(max, current, acc, seen, ignore) do
    increase_path(max, current, acc, seen, ignore)
  end

  def increase_path(max, current, acc, seen, ignore) do
    let direction <- oneof([:left, :right, :up, :down] -- ignore) do
      new_pos = move(direction, current)
      case seen do
        %{^new_pos => _} ->
          path(max, current, acc, seen, [direction|ignore])
        _ ->
          path(max-1, new_pos, [direction|acc], Map.put(seen, new_pos, :seen), [])
      end
    end
  end
  def move(:left, {x, y}), do: {x-1, y}
  def move(:right, {x, y}), do: {x+1, y}
  def move(:up, {x, y}), do: {x, y+1}
  def move(:down, {x, y}), do: {x, y-1}

  property "辞書ジェネレーター" do
    forall d <- dict_gen() do
      :dict.size(d) < 5
    end
  end

  property "シンボリックジェネレーター" do
    forall d <- dict_symb() do
      :dict.size(:proper_symb.eval(d)) < 5
    end
  end

  property "自動化されたシンボリックジェネレーター" do
    forall d <- dict_autosymb() do
      :dict.size(d) < 5
    end
  end

  def dict_gen() do
    let(x <- list({integer(), integer()}), do: :dict.from_list(x))
  end

  def dict_symb(),
    do: sized(size, dict_symb(size, {:call, :dict, :new, []}))

  def dict_symb(0, dict), do: dict

  def dict_symb(n, dict) do
    dict_symb(
      n - 1,
      {:call, :dict, :store, [integer(), integer(), dict]}
    )
  end

  def dict_autosymb() do
    sized(size, dict_autosymb(size, {:"$call", :dict, :new, []}))
  end

  def dict_autosymb(0, dict), do: dict

  def dict_autosymb(n, dict) do
    dict_autosymb(
      n - 1,
      {:"$call", :dict, :store, [integer(), integer(), dict]}
    )
  end
end
