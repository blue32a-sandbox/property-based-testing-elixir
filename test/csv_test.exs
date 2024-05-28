defmodule CsvTest do
  use ExUnit.Case
  use PropCheck
  alias Bday.Csv, as: Csv

  property "エンコードとデコードの往復" do
    forall maps <- csv_source() do
      maps == Csv.decode(Csv.encode(maps))
    end
  end

  test "１列のCSVファイルは本質的に曖昧" do
    assert "\r\n\r\n" == Csv.encode([%{"" => ""}, %{"" => ""}])
    assert [%{"" => ""}] == Csv.decode("\r\n\r\n")
  end

  test "１行に１レコード" do
    assert [%{"aaa" => "zzz", "bbb" => "yyy", "ccc" => "xxx"}] ==
      Csv.decode("aaa,bbb,ccc\r\nzzz,yyy,xxx\r\n")
  end

  test "オプションの末尾CRLF" do
    assert [%{"aaa" => "zzz", "bbb" => "yyy", "ccc" => "xxx"}] ==
      Csv.decode("aaa,bbb,ccc\r\nzzz,yyy,xxx")
  end

  test "二重引用符" do
    assert [%{"aaa" => "zzz", "bbb" => "yyy", "ccc" => "xxx"}] ==
      Csv.decode("\"aaa\",\"bbb\",\"ccc\"\r\nzzz,yyy,xxx")
  end

  test "CRLFのエスケープ" do
    assert [%{"aaa" => "zzz", "b\r\nbb" => "yyy", "ccc" => "xxx"}] ==
      Csv.decode("\"aaa\",\"b\r\nbb\",\"ccc\"\r\nzzz,yyy,xxx")
  end

  test "二重引用符のエスケープ" do
    assert [%{"aaa" => "", "b\"bb" => "", "ccc" => ""}] ==
      Csv.decode("\"aaa\",\"b\"\"bb\",\"ccc\"\r\n,,")
  end

  test "重複したキーはサポートされていない" do
    csv =
      "field_name,field_name,field_name\r\n" <>
        "aaa,bbb,ccc\r\n" <> "zzz,yyy,xxx\r\n"
    [map1, map2] = Csv.decode(csv)
    assert ["field_name"] == Map.keys(map1)
    assert ["field_name"] == Map.keys(map2)
  end

  def csv_source() do
    let size <- pos_integer() do
      let keys <- header(size + 1) do
        list(entry(size + 1, keys))
      end
    end
  end

  def entry(size, keys) do
    let vals <- record(size) do
      Map.new(Enum.zip(keys, vals))
    end
  end

  def header(size) do
    vector(size, name())
  end

  def record(size) do
    vector(size, field())
  end

  def name() do
    field()
  end

  def field() do
    oneof([uniquoted_text(), quoteble_text()])
  end

  def uniquoted_text() do
    let chars <- list(elements(textdata())) do
      to_string(chars)
    end
  end

  def quoteble_text() do
    let chars <- list(elements('\r\n",' ++ textdata())) do
      to_string(chars)
    end
  end

  def textdata() do
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789' ++
      ':;<=>?@ !#$%&\'()*+-./[\\]_`{|}~'
  end
end
