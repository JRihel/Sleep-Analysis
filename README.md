# Sleep-Analysis
This is a set of code to analyze data for zebrafish tracking datasets. 
There are two branches:
1) Format-Viewpoint Files, which is used to reformat quantized data from Viewpoint tracking experiments
2) Sleep_Analysis Code, which is used to pull out sleep/wake data and graphs. 

The code requires the folder strucutres available in the .zip file.
perl_batch_192.m is a Matlab code that runs as a Dos .bat file, and requires PERL. 
sleep_analysis_2020.m is a Matlab code (tested on R2019 and newer versions) written for Windows.
Installing should take less than 5 minutes.

Demo: To run a test for sleep_analysis2020, place 221031_06_DATA.txt into the Perl Batch Folder2/output folder and 221031_06genotype.txt into the /Genotype_list folder. The output, which will appear in the Analysis_output folder, should look like the sample output data found in  221031_06_Example output Sleep_Analysis.zip files.
The code should execute in less than 5 minutes.
