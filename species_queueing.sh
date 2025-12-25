#!/bin/zsh

SPID=('Zma' 'Sly')
TAXID=(4577 4081)

for i in {1..2}; do
    echo "Starting ${SPID[$i]} (TAXID: ${TAXID[$i]}) at $(date)"
    scripts/0-DataPreparation/2-RNA-seq/p-31-ftp-bowtie-featureCounts-xarg.sh ${TAXID[$i]} ${SPID[$i]} .
    echo "Completed ${SPID[$i]} (TAXID: ${TAXID[$i]}) at $(date)"
done

echo "All species (except Tae) processing completed!"
# for tae, the parallelization is set to 20 instead of 60, due to its large genome size and high resources demand
echo "Start expressiond data generation on Tae"
scripts/0-DataPreparation/2-RNA-seq/p-31-ftp-bowtie-featureCounts-xarg_Tae.sh 4565 'Tae' .