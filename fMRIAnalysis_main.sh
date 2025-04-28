#!/bin/sh

#Following script has been made by Naman Jain with following features included in the
#different version upgrades

##Calling all the functions that will be used in the upcoming script

#01.04.2025: Intial Script Planned, all functions called through external script

source ./All_functions_to_be_called.sh #converting data from either Bruker or Dicom format to NIFTI format

##In order to use awk, you need to convert xlsx file to csv file

root_location="/Volumes/pr_ohlendorf/fMRI"

cd $root_location/RawData
xlsx2csv Animal_Experiments_Sequences_v2.xlsx Animal_Experiments_Sequences_v2.csv

# Read the CSV file line by line, skipping the header
awk -F ',' 'NR==3 {print $0}' "Animal_Experiments_Sequences_v2.csv" | while IFS=',' read -r col1 dataset_name project_name sub_project_name structural_name functional_name _
do
    # Trim any extra whitespace
    project_name=$(echo "$project_name" | xargs)
    
    if [[ "$project_name" == "Project_MMP9_NJ_MP" ]]; then
        export Project_Name="$project_name"
        export Sub_project_Name="$sub_project_name"
        export Dataset_Name="$dataset_name"
        export run_number="$functional_name"
        
        Path_Raw_Data="$root_location/RawData/$project_name/$sub_project_name"
        Path_Analysed_Data="$root_location/AnalysedData/$project_name/$sub_project_name/$Dataset_Name"
        echo "Processing: $Path_Raw_Data"
        echo $run_number
        # Add your further processing steps here

        datapath=$(find "$Path_Raw_Data" -type d -name "*${Dataset_Name}*" 2>/dev/null)
        echo "$datapath"     
        
      
        echo "Dataset Currently Being Analysed is": $Dataset_Name "and run number is:" $run_number  

        if [ -d "$Path_Analysed_Data" ]; then
            echo "$Path_Analysed_Data does exist."
        else
            mkdir $Path_Analysed_Data
        fi

        cd $Path_Analysed_Data
        pwd

        LOG_DIR="$datapath/Data_Analysis_log" # Define the log directory where you want to store the script.
        user=$(whoami)
        log_execution "$LOG_DIR" || exit 1

        FUNC_PARAM_EXTARCT $datapath/$run_number

        CHECK_FILE_EXISTENCE "$Path_Analysed_Data/$run_number$SequenceName"
        cd $Path_Analysed_Data/$run_number''$SequenceName
        
        BRUKER_to_NIFTI $datapath $run_number $datapath/$run_number/method
        echo "This data is acquired using $SequenceName"

        log_function_execution "$LOG_DIR" "Motion Correction using AFNI executed on Run Number $run_number acquired using $SequenceName"|| exit 1
        MOTION_CORRECTION $MiddleVolume G1_cp.nii.gz mc_func
                    
        log_function_execution "$LOG_DIR" "Checked for presence of spikes in the data on Run Number $run_number acquired using $SequenceName"|| exit 1
        CHECK_SPIKES mc_func+orig

        log_function_execution "$LOG_DIR" "Temporal SNR estimated on Run Number $run_number acquired using $SequenceName"|| exit 1
        TEMPORAL_SNR_using_AFNI mc_func+orig

        log_function_execution "$LOG_DIR" "Smoothing using FSL executed on Run Number $run_number acquired using $SequenceName"|| exit 1
        SMOOTHING_using_FSL mc_func.nii.gz
 
        log_function_execution "$LOG_DIR" "Signal Change Map created for Run Number $run_number acquired using $SequenceName"|| exit 1
        SIGNAL_CHANGE_MAPS mc_func.nii.gz 2 30 $datapath/$run_number 5 5 mean_mc_func.nii.gz

    fi
done