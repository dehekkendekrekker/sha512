rm /tmp/test 2> /dev/null
iverilog -o /tmp/test ./src/rtl/*.v $1 && /tmp/test
