[ ! -z ${CONFIGURATION_FILE+x} ] || ( echo "Env var CONFIGURATION_FILE for the config of the experiment needs to be defined." && exit 1 )
[ ! -z ${RAW_COUNTS_FILE+x} ] || ( echo "Env var RAW_COUNTS_FILE for the counts of the experiment needs to be defined." && exit 1 )
[ ! -z ${RESULTS_PREF+x} ] || ( echo "Env var RESULTS_PREF for the output quantile norm counts of the experiment needs to be defined." && exit 1 )
[ ! -z ${SDRF_FILE+x} ] || ( echo "Env var SDRF_FILE for the SDRF file." && exit 1 )
[ ! -z ${METHODS_FILE+x} ] || ( echo "Env var METHODS_FILE for the SDRF file." && exit 1 )
[ ! -z ${GENES_OR_TRANSCRIPTS+x} ] || ( echo "genes or transcripts." && exit 1 )
[ ! -z ${LENGTHS_PREF+x} ] || ( echo "Env var LENGTHS_PREF for the lengths file prefix." && exit 1 )

LENGTHS_FILE=${LENGTHS_PREF}.Rdata
RESULTS=results/$RESULTS_PREF
RESULTS_PREF=${RESULTS_PREF}-${GENES_OR_TRANSCRIPTS}
mkdir -p $RESULTS


# Get data from FTP

# Filter data based on selection in SDRF


. ~/miniconda3/bin/activate ~/miniconda3/envs/ma_quantile_transform
QUANT_RES=$RESULTS/${RESULTS_PREF}-quantile-counts.tsv
# Run quantile normalisation
bash quantile_normalize.sh -c $CONFIGURATION_FILE \
	-s $RAW_COUNTS_FILE \
	-d $QUANT_RES


RDATA_FOR_BC=$RESULTS/${RESULTS_PREF}_summarizedExp.rdata
# Transform to R object for Guilhemes
# requires r-atlas-internal, currently part of the ma_quantile_transform env.
Rscript bin/transform2R.r --countstsv $QUANT_RES --sdrf $SDRF_FILE \
	--configuration $CONFIGURATION_FILE \
	--methods $METHODS_FILE \
	--batch 'study' \
	--output $RDATA_FOR_BC

. ~/miniconda3/bin/deactivate
. ~/miniconda3/bin/activate ~/miniconda3/envs/ma_batch_correct_combat
BC_OUTPUT=$RESULTS/${RESULTS_PREF}-corrected
BC_OUTPUT_R=${BC_OUTPUT}_summarizedExp.rdata
BC_OUTPUT_COUNTS=${BC_OUTPUT}_counts.tsv
# Run batch correction
Rscript bin/batch_correction_v2.R -i $RDATA_FOR_BC --output $BC_OUTPUT_R --tsv_corrected_counts $BC_OUTPUT_COUNTS

# conda create -n irap-components -c ebi-gene-expression-group irap-components
. ~/miniconda3/bin/deactivate
. ~/miniconda3/bin/activate ~/miniconda3/envs/ma_irap_components

RPKM_RES_PREFIX=${RESULTS}/${RESULTS_PREF}-corrected-fpkms
RPKM_RES=${RPKM_RES_PREFIX}.tsv
TPM_RES_PREFIX=${RESULTS}/${RESULTS_PREF}-corrected-tpms
TPM_RES=${TPM_RES_PREFIX}.tsv

if [ "$GENES_OR_TRANSCRIPTS" = "genes" ]; then
  feature="gene"
else
  feature="transcript"
fi

irap_raw2metric -i $BC_OUTPUT_COUNTS --lengths $LENGTHS_FILE --feature $feature --metric rpkm --out ${RPKM_RES}
irap_raw2metric -i $BC_OUTPUT_COUNTS --lengths $LENGTHS_FILE --feature $feature --metric tpm --out ${TPM_RES}

inputs=${RESULTS}/inputs
mkdir -p ${inputs}
cp $CONFIGURATION_FILE $inputs/

if [ "$GENES_OR_TRANSCRIPTS" = "transcripts" ]; then
  cp $RAW_COUNTS_FILE $inputs/
fi
