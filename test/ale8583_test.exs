defmodule Ale8583Test do
  use ExUnit.Case
  #doctest Ale8583
  require Logger

  test "list to iso type :prosa" do
    list_raw = 'ISO0060000400800822000000000000004000000000000000804180203010449101'
    # String.slice(data,0,12)
    str_head_prosa = list_raw |> Enum.take(12) |> List.to_string()
    #Logger.debug("Header PROSA : #{str_head_prosa} ")
    ## MTI
    str_mti = list_raw |> Enum.slice(12, 4) |> List.to_string()
    ##  BIT MAP PRIMARY
    #str_bit_map = Enum.slice(list_raw, 16, 16) |> List.to_string()
    str_bit_map = list_raw |> Enum.slice(16, 16) |> List.to_string()
    ##  BIT MAP IF TRANSACTION HAS BIT MAP SECONDARY
    assert Ale8583.have_bit_map_sec?(str_bit_map) == true
    str_bit_map =
      if Ale8583.have_bit_map_sec?(str_bit_map) == true do
        list_raw |> Enum.slice(16, 32) |> List.to_string()
      else
        str_bit_map
      end

    ## TAKE FIELDS SINCE FIELD 1.
    list_fields = Enum.take(list_raw, 32 - Kernel.length(list_raw))
    #list_fields = Enum.take(list_raw, 16 - Kernel.length(list_raw))
    ##  ISO MAKES FROM MTI AND CONFIGURATION FILE.
    iso_mti =
      Ale8583.new({str_mti, "/Users/ale/testPrograms/ale8583/ale8583/ascii.iso.cfg"})

    {:iso, _list_iso, {_list_bit_map_p, _list_bit_map_s, _flag_bm_sec, _list_iso_conf}, {status, message}} =
      iso_mti

    Logger.info("Result : #{inspect(status)} #{inspect(message)}")
    assert status == :ok
    # Logger.info "#{inspect iso_mti} "
    Logger.info("#{inspect(str_bit_map)}, #{inspect(list_fields)}, #{inspect(str_head_prosa)} ")
    iso_mti = Ale8583.list_to_iso({str_bit_map, list_fields, :prosa, str_head_prosa}, iso_mti)

    {:iso, list_iso, {_list_bit_map_p, _list_bit_map_s, _flag_bm_sec, _list_iso_conf}, {status, message}} =
      iso_mti

    ## INSPECT RESULT :ok or :error
    Logger.info("Result : #{inspect(status)} #{inspect(message)}")
    assert status == :ok

    Ale8583.printAll(iso_mti, "Print fields ISO type #{str_mti}:")

    # VALIDATE FIELDS CONTENT
    assert List.keymember?(list_iso, :c1, 0) == true
    assert List.keymember?(list_iso, :c7, 0) == true
    assert List.keymember?(list_iso, :c11, 0) == true
    assert List.keymember?(list_iso, :c70, 0) == true
    # { _ , strC3 } = List.keyfind( list_iso , :c3 ,0)
    # assert "111000" == strC3
    {_, str_bm_p} = List.keyfind(list_iso, :bp, 0)
    assert "8220000000000000" == str_bm_p
    Logger.info("Result : #{inspect(status)} #{inspect(message)}")
    assert status == :ok
  end

  test "ISO type :prosa makes" do
    # test "list to iso 2" do
    iso_0800 =
      Ale8583.new(
        {"0800", "/Users/ale/testPrograms/ale8583/ale8583/ascii.iso.cfg"},
        "ISO000000000"
      )

    status = :error
    {:iso, _, {_, _, _, _}, {status, _}} = iso_0800
    assert status == :ok

    iso_0800 = Ale8583.addField({7, "0207181112"}, iso_0800)
    status = :error
    {:iso, _, {_, _, _, _}, {status, _}} = iso_0800
    assert status == :ok

    iso_0800 = Ale8583.addField({11, "123456"}, iso_0800)
    status = :error
    {:iso, _, {_, _, _, _}, {status, _}} = iso_0800
    assert status == :ok

    iso_0800 = Ale8583.addField({70, "001"}, iso_0800)
    status = :error
    {:iso, _, {_, _, _, _}, {status, _}} = iso_0800
    assert status == :ok

    assert Ale8583.haveInISO?(iso_0800, :bs) == true
    assert Ale8583.haveInISO?(iso_0800, :c7) == true
    assert Ale8583.haveInISO?(iso_0800, :c11) == true
    assert Ale8583.haveInISO?(iso_0800, :c70) == true

    {_, list_iso, {_bit_map_p, _bit_map_s, _flag_bm_sec, _iso_conf}, {status, _message}} = iso_0800

    assert List.keymember?(list_iso, :c7, 0) == true
    {_, str_c7} = List.keyfind(list_iso, :c7, 0)
    assert "0207181112" == str_c7

    assert List.keymember?(list_iso, :c11, 0) == true
    {_, str_c11} = List.keyfind(list_iso, :c11, 0)
    assert "123456" == str_c11

    assert List.keymember?(list_iso, :c70, 0) == true
    {_, str_c70} = List.keyfind(list_iso, :c70, 0)
    assert "001" == str_c70
    trama_0800 = Ale8583.getTrama(iso_0800)
    assert trama_0800 == 'ISO0000000000800822000000000000004000000000000000207181112123456001'
    Logger.info("Trama PROSA ready for socket: <#{inspect(trama_0800)}>")
  end

  def test "list to iso type :master_card" do
    list_raw = 'ðøðð            ðððððððððððñòðööñðùðððððñôô÷ðöñðÂð@@@@ðððððððð'
    ## MTI
    str_mti = list_raw |> Enum.slice(0, 4) |> Ale8583.Convert.ebcdic_to_ascii() |> List.to_string()
    ##  BIT MAP PRIMARY , format bynary only 8 bytes
    str_bit_map = list_raw |> Enum.slice(4, 8) |> Ale8583.Convert.bin_to_ascii() |> List.to_string()
    ##  BIT MAP IF TRANSACTION HAS BIT MAP SECONDARY
    str_bit_map =
      if Ale8583.have_bit_map_sec?(str_bit_map) == true do
        list_raw |> Enum.slice(4, 16) |> Ale8583.Convert.bin_to_ascii() |> List.to_string()
      else
        str_bit_map
      end

    ## TAKE FIELDS SINCE FIELD 1.
    list_fields = Enum.take(list_raw, 20 - Kernel.length(list_raw))

    ##  ISO MAKES FROM MTI AND CONFIGURATION FILE.
    iso_mti =
      Ale8583.new(
        {str_mti, "/Users/ale/testPrograms/ale8583/ale8583/ebcdic.iso.cfg"}
      )

    {:iso, _list_iso, {_list_bit_map_p, _list_bit_map_s, _flag_bm_sec, _list_iso_conf}, {status, message}} =
      iso_mti

    Logger.info("Result : #{inspect(status)} #{inspect(message)}")
    assert status == :ok
    # Logger.info "#{inspect iso_mti} "
    Logger.info(" #{inspect(list_fields)}, #{inspect(str_mti)} ")
    iso_mti = Ale8583.list_to_iso({str_bit_map, list_fields, :master_card, ""}, iso_mti)

    {:iso, list_iso, {_list_bit_map_p, _list_bit_map_s, _flag_bm_sec, _list_iso_conf}, {status, _message}} =
      iso_mti

    ## INSPECT RESULT :ok or :error
    Logger.info("Result : #{inspect(status)} #{inspect(message)}")
    assert status == :ok

    Ale8583.printAll(iso_mti, "Print fields ISO type #{str_mti}:")

    # VALIDATE FIELDS CONTENT
    assert List.keymember?(list_iso, :bs, 0) == true
    assert List.keymember?(list_iso, :c7, 0) == true
    assert List.keymember?(list_iso, :c33, 0) == true
    assert List.keymember?(list_iso, :c70, 0) == true
    assert List.keymember?(list_iso, :c94, 0) == true
    assert List.keymember?(list_iso, :c96, 0) == true
    # { _ , strC3 } = List.keyfind( list_iso , :c3 ,0)
    # assert "111000" == strC3
    {_, str_bm_p} = List.keyfind(list_iso, :bp, 0)
    assert "8220000080000000" == str_bm_p
    assert status == :ok

    {_, str_bms} = List.keyfind(list_iso, :bs, 0)
    assert "0400000500000000" == str_bms
    assert status == :ok
  end

  test "ISO type :master_card makes" do
    # test "ISO type :prosa makes" do
    iso_0800 =
      Ale8583.new(
        {"0800", "/Users/ale/testPrograms/ale8583/ale8583/ebcdic.iso.cfg"}
      )

    status = :error
    {:iso, _, {_, _, _, _}, {status, _}} = iso_0800
    assert status == :ok

    iso_0800 = Ale8583.addField({7, "0207181112"}, iso_0800)
    status = :error
    {:iso, _, {_, _, _, _}, {status, _}} = iso_0800
    assert status == :ok

    iso_0800 = Ale8583.addField({11, "123456"}, iso_0800)
    status = :error
    {:iso, _, {_, _, _, _}, {status, _}} = iso_0800
    assert status == :ok

    iso_0800 = Ale8583.addField({33, "900000144"}, iso_0800)
    status = :error
    {:iso, _, {_, _, _, _}, {status, _}} = iso_0800
    assert status == :ok

    iso_0800 = Ale8583.addField({70, "061"}, iso_0800)
    status = :error
    {:iso, _, {_, _, _, _}, {status, _}} = iso_0800
    assert status == :ok

    iso_0800 = Ale8583.addField({96, "00000000"}, iso_0800)
    status = :error
    {:iso, _, {_, _, _, _}, {status, _}} = iso_0800
    assert status == :ok
    Logger.info "Status: #{status}"

    assert Ale8583.haveInISO?(iso_0800, :bs) == true
    assert Ale8583.haveInISO?(iso_0800, :c7) == true
    assert Ale8583.haveInISO?(iso_0800, :c11) == true
    assert Ale8583.haveInISO?(iso_0800, :c33) == true
    assert Ale8583.haveInISO?(iso_0800, :c70) == true
    assert Ale8583.haveInISO?(iso_0800, :c96) == true

    {_, list_iso, {_ , _ , _ , _ }, {_ , _ }} = iso_0800

    assert List.keymember?(list_iso, :c7, 0) == true
    {_, str_c7} = List.keyfind(list_iso, :c7, 0)
    assert "0207181112" == str_c7

    assert List.keymember?(list_iso, :c11, 0) == true
    {_, str_c11} = List.keyfind(list_iso, :c11, 0)
    assert "123456" == str_c11

    assert List.keymember?(list_iso, :c70, 0) == true
    {_, str_c70} = List.keyfind(list_iso, :c70, 0)
    assert "061" == str_c70

    trama_0800 = Ale8583.getTrama(iso_0800)
    Logger.info("Trama MASTERCARD ready for socket: <#{inspect(trama_0800)}>")
  end
end
