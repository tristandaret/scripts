#!/bin/bash


# Tags
start=0       # starting event
nevent=0      # number of events processed
tags=""
rm_flag=false


while :; do
   case $1 in
      -s)
         if [ "$2" ]; then
            start=$2
            shift
         fi
      ;;
      -n)
         if [ "$2" ]; then
            nevent=$2
            shift
         fi
      ;;
      -d)
         if [ "$2" ]; then
            datafile=$2
            shift
         fi
      ;;
      --tags)
         if [ "$2" ]; then
            tags=$2
            shift
         fi
      ;;
      --rm)
         rm_flag=true
      ;;
      --) # End of all options
         shift
         break
      ;;
      -?*) # Unknown option
         printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
      ;;
      *) # No more options
         break
   esac
   shift
done

# Define data file
datarun="${datafile:0:${#datafile}-5}"
if [[ "$datafile" == *"dog1"* ]]; then
  datafile="/sps/t2k/Jparc/May_2024/dog1/${datarun}/${datafile}.daq.mid.gz"
elif [[ "$datafile" == *"MC"* ]]; then
  datafile="$HOME/public/data/MC/${datafile}.root"
fi
echo "File used:             ${datafile}"

# Output file names
if [[ "$datafile" == *"MC"* ]]; then
   dataflag="${datafile}"
   eventCalib_output="$HOME/public/output_nd280/root/MC/3_eventCalib_${tags}.root"
   eventRecon_output="$HOME/public/output_nd280/root/MC/4_eventRecon_${tags}.root"
   eventAnalysis_output="$HOME/public/output_nd280/root/MC/5_eventAnalysis_${tags}.root"
else
   dataflag="-m ${datafile}"
   eventCalib_output="$HOME/public/output_nd280/root/cosmics/3_eventCalib_${tags}.root"
   eventRecon_output="$HOME/public/output_nd280/root/4_eventRecon_${tags}.root"
   eventAnalysis_output="$HOME/public/output_nd280/root/5_eventAnalysis_${tags}.root"
fi
logs="$HOME/public/output_nd280/logs/logs_${tags}.log"
echo "Logs:                  ${logs}"

flags="-R"
# Handle cases with optional flags
if [ "$start" -ne 0 ]; then
  flags="${flags} -s ${start}"
fi

if [ "$nevent" -ne 0 ]; then
  flags="${flags} -n ${nevent}"
fi

# EventCalib
echo "eventCalib output:     ${eventCalib_output}"
echo -e "\n--- STEP 3: EVENTCALIB    ---" > "${logs}"
time RunEventCalib.exe ${dataflag} -o ${eventCalib_output} ${flags} &>> ${logs}

# EventRecon
echo "eventRecon output:     ${eventRecon_output}"
echo -e "\n--- STEP 4: EVENTRECON   ---" >> "${logs}"
time RunEventRecon.exe ${eventCalib_output} -o ${eventRecon_output} ${flags} &>> ${logs}

# EventAnalysis
echo "eventAnalysis output:  ${eventAnalysis_output}"
echo -e "\n--- STEP 5: EVENTANALYSIS ---" >> "${logs}"
time RunEventAnalysis.exe ${eventRecon_output} -o ${eventAnalysis_output} ${flags} &>> ${logs}

if [[ "$rm_flag" = true ]]; then
   ${eventCalib_output} ${eventRecon_output}
fi