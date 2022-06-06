###########################################################################
#
# Generated by : Version 8.0 Build 215 05/29/2008 SJ Full Version
#
# Project      : UART16750
# Revision     : UART16750
#
# Date         : Fri Jan 16 10:46:32 Westeuropäische Normalzeit 2009
#
###########################################################################
 
 
# WARNING: Expected ENABLE_CLOCK_LATENCY to be set to 'ON', but it is set to 'OFF'
#          In SDC, create_generated_clock auto-generates clock latency
#
# ------------------------------------------
#
# Create generated clocks based on PLLs
derive_pll_clocks -use_tan_name
#
# ------------------------------------------
# WARNING: Global Fmax translated to derive_clocks. Behavior is not identical
if {![info exist ::qsta_message_posted]} {
    post_message -type warning "Original Global Fmax translated from QSF using derive_clocks"
    set ::qsta_message_posted 1
}
derive_clocks -period "33 MHz"
#


# Original Clock Setting Name: CLK
create_clock -period "30.303 ns" \
             -name {CLK} {CLK}
# ---------------------------------------------

# ** Clock Latency
#    -------------

# ** Clock Uncertainty
#    -----------------

# ** Multicycles
#    -----------
# ** Cuts
#    ----

# ** Input/Output Delays
#    -------------------




# ** Tpd requirements
#    ----------------

# ** Setup/Hold Relationships
#    ------------------------

# ** Tsu/Th requirements
#    -------------------


# ** Tco/MinTco requirements
#    -----------------------

#
# Entity Specific Timing Assignments found in
# the Timing Analyzer Settings report panel
#


# ---------------------------------------------

