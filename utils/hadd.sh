folder="public/Output_root"
output_file="${folder}/hatRecon_dog1_00001022_master_T04_all01.root"
input_files=""

rm ${output_file}

for i in $(seq -w 0 1); do
    input_files+="${folder}/hatRecon_dog1_00001022_000${i}_s0_n28000.root "
done

hadd -T $output_file $input_files