def prebuild
    File.open("#{__dir__}/midi_table.inc", "w+") do |f|
        f.puts "const unsigned char midi_table[256] = {"

        for m in 0..127 do
            exp = (m.to_f - 69)/12
            freq = (2 ** exp) * 440

            n = (CLK_SPEED_HZ.to_f / (32 * freq)).round

            bin = "%010b" % n
            if bin.size > 10
                puts "Warning: Frequency #{freq.round(2)} (\##{m}) out of range for 10-bit expression."
                bin = "1111111111"
            end

            upper = "00" + bin[0..5]
            lower = "0000" + bin[6..9]

            f.puts "    0b#{lower}, // Note \##{m} (#{freq}Hz)"
            f.puts "    0b#{upper},"
        end

        f.puts "};"
        f.puts ""
    end
end
