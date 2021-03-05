import re

rule quantile_normalize:
    input:
        configuration_file=data/{accession}-configuration.xml,
        raw_counts_file=data/{accession}-{genes_or_transcripts}-raw-counts.tsv.undecorated
    output:
        quantile_result=tmp_results/{accession}-{genes_or_transcripts}-quantile-counts.tsv
    conda:
        "envs/ma_quantile_transform.yaml"
    shell:
        """
        bash quantile_normalize.sh \
            -c {input.configuration_file} \
            -s {input.raw_counts_file} \
            -d {output.quantile_result}
        """

rule transform2R:
    input:
        quantile_result=rules.quantile_normalize.output.quantile_result,
        sdrf=data/{accession}.sdrf.txt,
        configuration_file=rules.quantile_normalize.input.configuration_file,
        methods_file=data/{accession}-analysis-methods.tsv,
        batch="study"
    output:
        rdata=tmp_results/{accession}-{genes_or_transcripts}_summarizedExp.rdata
    conda:
        "envs/ma_quantile_transform.yaml"
    shell:
        """
        Rscript bin/transform2R \
            --countstsv {input.quantile_result} \
            --sdrf {input.sdrf} \
            --configuration {input.configuration_file} \
            --methods {input.methods_file} \
            --batch {input.batch} \
            --output {output.rdata}
        """

rule batch_correction_v2:
    input:
        counts=rules.transform2R.output.rdata
    output:
        summarized_rdata=tmp_results/{accession}-{genes_or_transcripts}-corrected_summarizedExp.rdata,
        tsv_corrected_counts=tmp_results/{accession}-{genes_or_transcripts}-corrected_counts.tsv
    conda:
        "envs/ma_batch_correct_combat.yaml"
    shell:
        """
        Rscript batch_correction_v2.R \
            -i {input.counts} \
            --output {output.summarized_rdata} \
            --tsv_corrected_counts {output.tsv_corrected_counts}
        """


METRICS=["tpm", "fpkm"]

rule irap_raw2metric:
    input:
        counts=rules.batch_correction_v2.output.tsv_corrected_counts,
        lengths=data/{accession}.lengths,
        feature=re.sub("s$", "", "{genes_or_transcripts}")
        metric=expand("{metric}", metric=METRICS)
    output:
        length_corrected=expand("{accession}-{genes_or_transcripts}-corrected-{metric}", metric=METRICS)
    conda:
        "envs/ma_irap_components.yaml"
    shell:
        """
        irap_raw2metric -i {input.counts} \
            --lengths {input.lengths} \
            --feature {input.feature} \
            --metric {input.metric} \
            --out {length.corrected}
        """
