# DAOSLIMIT Protocol

Title:      Supplementary Software for "A practical guide to scanning light-field microscopy with digital adaptive optics"

Version:    2.0 

Copyright:  2021, ZHI LU, JIAMIN WU, QIONGHAI DAI

Licence: GNU General Public License v2.0

----------------

If you use this code, please cite the companion paper where the original method appeared:

Lu, Z. et al. A practical guide to scanning light-field microscopy with digital adaptive optics", Nature Protocols (2022). https://doi.org/10.1038/s41596-022-00703-9.

For algorithmic details, please refer to our paper.

The software and code are tested in Visual Studio 2015 and MATLAB 2018b (64 bit) under the MS Windows 10 64 bit version with an Intel i9-9980XE CPU, NVIDIA GeForce RTX 2080 Ti GPU and 128 GB RAM.

Supporting and example data in this study and DLL files can be downloaded with the following link: https://drive.google.com/drive/folders/1zCXlDlkdB2lWyqny-jmcRhDHQwoql1FR?usp=sharing

----------------
How to use
----------------
1. Unpack the package and install related framework

2. Open sLFdriver.exe to capture data

    a). The DLL files supporting OpenCV，OpenGL，NANOGUI，Andor SDK3 and LabVIEW should be placed in the main folder. The files are too large So we upload them in the google drive described before. 

    b). The raw data of the scanning light field would be stored in the folder of "Data". The detailed instructions can be found in Supplementary Manual 1 in our paper (Submitted to Nature Protocols, 2021).

2. Include subdirectory in your Matlab path

3. Run the demo code named main_for_timelapse_zebrafish_embryo.m

   a). The raw data of the scanning light field should be placed in the folder of "Data". We have provided an example data for testing, which is a time-lapse video of zebrafish embryo (63x/1.4NA oil immersion objective). The data are too large. So we upload them in the google drive described before. 
   
   b). The PSF files in the format of .mat should be placed in the folder of "PSF". We provide a system PSF calibration method. Readers can also generate the simulated ideal PSFs by running "main_computePSF_with_calibration.m" (based on wave optics theory [1], phase-space theory [2] and DAO algorithm [3]), which is located in the folder of "PSFcalculation_calibration".

   
----------------
Main modules description
----------------
1. sLF_driver.exe: acquisition software for sLFM (>=50 GB memory, GPU)

2. main_for_timelapse_zebrafish_embryos.m: Pre-processes and 3D reconstruciton with DAO, time-weighted algorithm and time-loop algorithm (for time-lapse data)(>=50 GB memory)

* Pre-processes including pixel realignment with system-error auto-correction, are involved in /Solve/Auto_realignment.m, which calls Realign.exe in main folder.

----------------
Configuration files description
----------------
1. DLL files: including dll files of OpenCV，OpenGL，NANOGUI，Andor SDK3 and LabVIEW, used for sLFdriver.exe and Realign.exe. The NIControl.dll was built from LabVIEW 2019. If another version of LabVIEW is used or if a different type of NI box is used, the user may need to modify and rebuild the project. NI project source codes are available in 'NI_codes' folder. When rebuilding the project, launch 'NI_codes/proj/NIController.lvproj' and build FinalDll. Then copy NIControl.dll from 'NI_codes/builds/scanProj/NIConrtolVersion2' to the main folder.

2. Configuration files: 3x3.conf.sk.png, 5x5.conf.sk.png, 13x13.conf.sk.png, represent different scanning patterns used for pixel-realignment.
		  SLFConfig.ini, includes the initial acquisition parameters.

3. Zemax files: for other microscopes from different companies, slight optimization of the distances between the lenses can be conducted in the Zemax (for details, see Supplementary Manual 2).

----------------
IMPORTANT NOTE 
---------------- 
Should you have any questions regarding this code and the corresponding results, please contact Zhi Lu (luz18@mails.tsinghua.edu.cn).

Reference:
1.  R. Prevedel, Y.-G. Yoon, M. Hoffmann, N. Pak, G. Wetzstein, S. Kato, T. Schr?del, R. Raskar, M. Zimmer, E. S. Boyden, and A. Vaziri, 
     "Simultaneous whole-animal 3D imaging of neuronal activity using light-field microscopy," Nature Methods, 2014, 11(7): 727-730.
2.  Lu Z, Wu J, Qiao H, et al. "Phase-space deconvolution for light field microscopy," Optics express, 2019, 27(13): 18131-18145.
3.  Wu J, Lu Z, Jiang D, et al. "Iterative tomography with digital adaptive optics permits hour-long intravital observation of 3D subcellular dynamics at millisecond scale" Cell, 2021, 184(12).

