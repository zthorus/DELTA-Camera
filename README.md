# DELTA-Camera
Digital electronics of the DELTA photon-counting camera

The DELTA (Detection of Events of Light by Three Axes) is a concept of photon-counting camera (originally designed for observations in astrophysics using speckle-interferometry or long-baseline interferometry techniques in the visible spectrum). It uses three fast-readout linear CCDs (Thomson TH7809A), on which the spots of photo-events (coming out from a stack of image-intensifiers) is projected. A challenge of such an instrument is to process in real-time the digitized signals from the CCDs to recover the (x,y) coordinates of the photo-events. When the DELTA camera was designed at the end of the 1990s, this would have required a complex digital electronics, but progress in the development of FPGAs over the last 20 years have made the digital electronics fully implementable now on an FPGA available at very low price, like the Altera MAX10 in its 10M08 version. The current version of this digital electronics only requires 720 logical elements and 6912 bits of on-chip memory. For a real implementation using TH7809A CCDs, these figures would likely be multiplied by four, which remains compatible with the MAX10 10M08 characteristics.

This repository contains the VHDL code for a possible implementation of the DELTA-Camera digital electronics, in a simplified version (for demonstration purpose) that considers linear CCDs with 2 segments of pixels (128 pixels in each segment) instead of 8 segments (case of the TH7809A CCDs that have been considered for the DELTA-Camera). The CCD segments are read in parallel by pairs of even/odd pixels for each segment. This VHDL code contains a simulator of digitized (1 bit/pixel) CCD frames of the three axes that are stored in a ROM. This simulator also provides the "new frame" pulses and the clocks.

The VHDL code is based on the original architecture design (1998) of the DELTA-Camera digital electronics and features:
* Edge detection of the projected photo-event spots on each segment by Mealy machines (implemented by self-addressed ROMs) = Process-1 (one instance by CCD segment).
* Calculation of the coordinates of the projected spots on each axis (A, B and C) = Process-2 (one instance by projection axis).
* Recovering of the (x,y) coordinates by testing the sum of the coordinates A, B and C = Process-3 (one instance for the whole camera).

The interface between Process-1 and Process-2 consists of two banks of FIFOs. While one bank is written in by Process-1, the other is read out by Process-2. Likewise, the interface between process 2 and process 3 consists of two banks of RAM components. While one bank is written in by Process-2, the other is read out by Process-3. The roles of the banks are swapped at each new frame. This ensures a continuous flow of data from the CCD to the acquisition computer located downstream of the camera.

In this code, "DeltaCam.vhd" is the top-level entity that is equivalent to a "virtual printed circuit board" grouping all the needed components of the DELTA-Camera digital electronics. The current implementation does not feature "Process-4" which would consist of a look-up table stored in ROM to scale down the resolved y-coordinates. Also, the timestamping of the detected photo-events is not implemented yet.

The repository also includes a C program "frame_simu.c" that generates a ROM-content file (mif) of simulated CCD frames from given photo-event (x,y) coordinates.

References:
* S. Morel, L. Koechlin, "The DELTA photon counting camera concept", Astronomy & Astrophysics Supplement Series, vol. 130, pp. 395-401 (1998). 
* S. Morel. PhD dissertation (in french), available at: https://tel.archives-ouvertes.fr/tel-01053919 (see pages 79 to 94).

