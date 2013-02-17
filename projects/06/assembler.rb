#!/usr/bin/env ruby
#
#USAGE: assembler.rb <infile> <outfile>




infilename = ARGV[0]
outfilename = ARGV[1]

rom_counter = 0
ram_counter = 16

# operations
# command => a c1 c2 c3 c4 c5 c6
operations = {
  "0"   => "0101010",
  "1"   => "0111111",
  "-1"  => "0111010",
  "D"   => "0001100",
  "A"   => "0110000",
  "!D"  => "0001101",
  "!A"  => "0110001",
  "-D"  => "0001111",
  "-A"  => "0110011",
  "D+1" => "0011111",
  "A+1" => "0110111",
  "D-1" => "0001110",
  "A-1" => "0110010",
  "D+A" => "0000010",
  "D-A" => "0010011",
  "A-D" => "0000111",
  "D&A" => "0000000",
  "D|A" => "0010101",

  "M"   => "1110000",
  "!M"  => "1110001",
  "-M"  => "1110011",
  "M+1" => "1110111",
  "M-1" => "1110010",
  "D+M" => "1000010",
  "D-M" => "1010011",
  "M-D" => "1000111",
  "D&M" => "1000000",
  "D|M" => "1010101"
}

# dest => d1 d2 d3
destinations = {
  "null" => "000",
  "M"    => "001",
  "D"    => "010",
  "MD"   => "011",
  "A"    => "100",
  "AM"   => "101",
  "AD"   => "110",
  "AMD"  => "111"
}

# jump => j1 j2 j3
jumps = {
  "null" => "000",
  "JGT"  => "001",
  "JEQ"  => "010",
  "JGE"  => "011",
  "JLT"  => "100",
  "JNE"  => "101",
  "JLE"  => "110",
  "JMP"  => "111"
}

symbol_table = {
"SP" => 0,
"LCL" => 1,
"ARG" => 2,
"THIS" => 3,
"THAT" => 4,
"SCREEN" => 16384,
"KBD" => 24576
}

0.upto(15) do |i|
  symbol_table["R#{i}"] = i
end

line_number = 0

infile = File.open(infilename, "r")

# first pass
infile.each_line do |line|
  line.gsub!(/\/\/.*$/, "") # replace // [anything] with empty string
  line.strip!

  if line == ""
    # do nothing
  elsif line =~ /\([A-Za-z_.$:][A-Za-z0-9_.$:]*\)/
    sym = line[/[A-Za-z_.$:][A-Za-z0-9_.$:]*/]
    if symbol_table.has_key?(sym)
      raise "Duplicate symbol #{sym} at line #{line_number}"
    end
    symbol_table[sym] = rom_counter
  elsif line =~ /^@[A-Za-z_.$:][A-Za-z0-9_.$:]*/
    # A instructions
    rom_counter += 1
  elsif line =~ /^@[0-9]+/
    # A instruction of literal value
    rom_counter += 1
  else
    # C instructions
    rom_counter += 1
  end
  
  line_number += 1
end

outfile = File.open(outfilename, "w")

infile = File.open(infilename, "r")

# second pass
infile.each_line do |line|
  line.gsub!(/\/\/.*$/, "") # replace // [anything] with empty string
  line.strip!
  
  if line == ""
    # do nothing
  elsif line =~ /\([A-Za-z_.$:][A-Za-z0-9_.$:]*\)/
    # do nothing
  elsif line =~ /^@[A-Za-z_.$:][A-Za-z0-9_.$:]*/
    # A instructions
    sym = line[/[A-Za-z_.$:][A-Za-z0-9_.$:]*/]
    if !symbol_table.has_key?(sym)
      symbol_table[sym] = ram_counter
      ram_counter += 1
    end
    value = symbol_table[sym]
    bin_value = value.to_s(2)

    if bin_value.size > 15
      raise "loaded value #{sym} = #{value} is too large"
    end

    out_line = "0" + ("0" * (15 - bin_value.size)) + bin_value

    outfile.puts(out_line)
  elsif line =~ /^@[0-9]+/
    # A instruction of literal value
    value = line[/[0-9]+$/].to_i
    bin_value = value.to_s(2)

    if bin_value.size > 15
      raise "loaded value #{value} is too large"
    end

    out_line = "0" + ("0" * (15 - bin_value.size)) + bin_value

    outfile.puts(out_line)
  else
    line_parts = line.split(";")
    command = line_parts[0]

    # if command contains equals, then destination is on the left
    command_parts = command.split("=")
    dest = "null"
    if command_parts.size == 2
      dest = command_parts[0]
      op = command_parts[1]
    else
      op = command
    end

    # if line contains semicolon, jump specifier is on the right
    jump = "null"
    if line_parts.size == 2
      jump = line_parts[1]
    end

    out_line = "111" + operations[op] + destinations[dest] + jumps[jump]
    outfile.puts(out_line)
  end
end

