# SoC-ATE-pattern-compression
This project has scripts which can be used to compress test vectors or patterns generated to use on SoC testers like Advantest, Ultraflex. The concept is universal and can be extended to any SoC tester.

In my professional experience, I have implemented, used and driven acceptance for a number of pattern compression techniques which are able to compress a pattern to ~50% of its original size(depending on the vector content inside the pattern).

##  1 - Scan Channel Link
This methodology is a feature of the ATE tester, and can be leveraged upon by using half(channel link by 2), quarter(channel link by 4) of the segments in the hardware.
The scan channel link function increases the scan pattern capacity by linking the memory of each channel every 16 channels. The channel link information is specified in the PXR file.
When the scan channel link is used, there are restrictions on the number of scan channels that can be connected to the DUT. For example, for a 2 channel link, only 8 channels of a segment(of total 16) can be used to connect to the DUT scan I/Os. 
This enables the tester to use memory from the other unused channels to link to the used channels which are connected to DUT scan I/Os, thus increasing the effective memory available for use. 
Besides that, the other advantage is that when we modify the pattern to enable channel link, it reduces the pattern size too. 

#### PATTERN AFTER CHANNEL LINK:
> NOP         { V { all_pins = 1111000011100110011; } W { all_pins = scan_setup; } }
JSC           { V { all_pins = 1111000011100110011; } W { all_pins = scan_setup; } }
NOP         { V { all_pins = 0110LHLHL1 ; } W { all_pins = scan_shift; } }
NOP         { V { all_pins = 1010LLHHL1 ; } W { all_pins = scan_shift; } }
NOP         { V { all_pins = 0101HLLHH0; } W { all_pins = scan_shift; } }
NOP         { V { all_pins = 1001HLHLH0; } W { all_pins = scan_shift; } }
NOP         { V { all_pins = 0110LHHLH1; } W { all_pins = scan_shift; } }
NOP         { V { all_pins = 1010LHLLL1 ; } W { all_pins = scan_shift; } }
EXITSC     { V { all_pins = 1111000011100110011; } W { all_pins = scan_setup; } }
NOP         { V { all_pins = 1111000011100110011; } W { all_pins = scan_setup; } }
EXIT         { V { all_pins = 1111000011100110011; } W { all_pins = scan_setup; } }

## 2 - Replace Contiguous Vectors with Repeats
Developed modules to modify the pattern.
IDXI(repeat) instruction can be used in the pattern to tell the processor to apply the vector for the number of specified cycles. 
In this method, as can be seen in the example, we replace the contiguous repeating vectors with a single vector and IDXI instruction. 

#### BEFORE: 
NOP     { V { all_pins_norm = 10101010101; } W { all_pins_norm = scan_setup; } }
NOP     { V { all_pins_norm = 11110001111; } W { all_pins_norm = scan_setup; } }
NOP     { V { all_pins_norm = 11110001111; } W { all_pins_norm = scan_setup; } }
NOP     { V { all_pins_norm = 11110001111; } W { all_pins_norm = scan_setup; } }
EXIT     { V { all_pins_norm = 10101010101; } W { all_pins_norm = scan_setup; } }

#### AFTER:
NOP     { V { all_pins_norm = 10101010101; } W { all_pins_norm = scan_setup; } }
IDXI 3  { V { all_pins_norm = 11110001111; } W { all_pins_norm = scan_setup; } }
EXIT     { V { all_pins_norm = 10101010101; } W { all_pins_norm = scan_setup; } }


## 3 - Replace idle clock cycle with loops
A lot of times in the test patterns, there are sections wherein we only have the clock signal toggling 0101…  Or 0C0C… on one or more pins. The rest of the pins have constant value. 
If this is found, we can compress the pattern by replacing many tens/hundreds of vectors using a loop construct, which can be formed using STI-JNI instructions and only two vectors. 
The STI instruction specifies N, the value specified for the operand, as the repetition count for the JNI instruction.NOTE: STI-JNI construct can be used more than once, and nested. The maximum nesting level is 8. For simple clocks, we don’t need nesting. Nested structure can be used for more complex constructs, if needed.

#### BEFORE: 
NOP     { V { all_pins = 11110000111; } W { all_pins = scan_setup; } }
NOP     { V { all_pins = 1011000C111; } W { all_pins = scan_setup; } }
NOP     { V { all_pins = 11110000111; } W { all_pins = scan_setup; } }
NOP     { V { all_pins = 1011000C111; } W { all_pins = scan_setup; } }
NOP     { V { all_pins = 11110000111; } W { all_pins = scan_setup; } }
NOP     { V { all_pins = 1011000C111; } W { all_pins = scan_setup; } }
NOP     { V { all_pins = 11110000111; } W { all_pins = scan_setup; } }
NOP     { V { all_pins = 1011000C111; } W { all_pins = scan_setup; } }
NOP     { V { all_pins = 11110000111; } W { all_pins = scan_setup; } }
EXIT     { V { all_pins = 10101010101; } W { all_pins = scan_setup; } }

#### AFTER: 
STI 4    { V { all_pins = 11110000111; } W { all_pins = scan_setup; } }
L:  #label for looping
NOP     { V { all_pins = 1011000C111; } W { all_pins = scan_setup; } }
JNI  L    { V { all_pins = 11110000111; } W { all_pins = scan_setup; } }
EXIT     { V { all_pins = 10101010101; } W { all_pins = scan_setup; } }

## 4 - Combine repeats with loops for additional compression
We can combine both the above in a single-pass or multi-pass logic to get larger amounts of compression. This part is undergoing development and testing, so the code has not been uploaded yet. But the benefits have already been implemented and proven on a small set of vectors. 

#### BEFORE:
NOP    { V { all_pins = 1111; } W { all_pins = scan_setup; } }
NOP    { V { all_pins = 1011; } W { all_pins = scan_setup; } }
NOP    { V { all_pins = 1011; } W { all_pins = scan_setup; } }
NOP    { V { all_pins = 1111; } W { all_pins = scan_setup; } }
NOP    { V { all_pins = 1111; } W { all_pins = scan_setup; } }
.
. #repeats 4 more times
.
EXIT     { V { all_pins = 1010; } W { all_pins = scan_setup; } }

#### AFTER:
STI 5    { V { all_pins = 1111; } W { all_pins = scan_setup; } }
L:  #label for looping
IDXI 2  { V { all_pins = 1011; } W { all_pins = scan_setup; } }
NOP     { V { all_pins = 1111; } W { all_pins = scan_setup; } }
JNI L     { V { all_pins = 1111; } W { all_pins = scan_setup; } }
EXIT     { V { all_pins = 1010; } W { all_pins = scan_setup; } }
