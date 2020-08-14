[ ! -z ${LENGTHS_PREF+x} ] || ( echo "Env var LENGTHS_PREF for the lengths file prefix." && exit 1 )
[ ! -z ${GTF+x} ] || ( echo "Env var GTF for the GTF file." && exit 1 )

# conda create -n irap-components -c ebi-gene-expression-group irap-components
. ~/miniconda3/bin/deactivate
. ~/miniconda3/bin/activate ~/miniconda3/envs/irap-components


LENGTHS_FILE=${LENGTHS_PREF}.Rdata
 
irap_gtf2featlength --gtf $GTF --out $LENGTHS_PREF --cores 2

echo "Lenghts file: $LENGTHS_FILE"
