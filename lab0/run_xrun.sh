#!/bin/bash
source /cad/env/cadence_path.XCELIUM1909
xrun -f apple_tb.f \
-lineddebug \
-debug \
-gui \
-fsmdebug

