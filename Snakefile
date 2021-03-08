rule all:
    input:
        #summarized_rdata="tmp_results/{accession}-{genes_or_transcripts}s-corrected_summarizedExp.rdata",
        #tsv_corrected_counts="tmp_results/{accession}-{genes_or_transcripts}s-corrected_counts.tsv"
        corrected_tpm="tmp_results/{accession}-{genes_or_transcripts}s-corrected-tpms",
        corrected_fpkm="tmp_results/{accession}-{genes_or_transcripts}s-corrected-fpkms"

rule copy_genes_data:
    input:
        raw_counts_file="data/{accession}-raw-counts.tsv.undecorated"
    output:
        labeled_genes_raw_counts="data/{accession}-genes-raw-counts.tsv.undecorated"
    shell:
        "cp {input.raw_counts_file} {output.labeled_genes_raw_counts}"

rule quantile_normalize:
    input:
        configuration_file="data/{accession}-configuration.xml",
        raw_counts_file="data/{accession}-{genes_or_transcripts}s-raw-counts.tsv.undecorated"
    output:
        quantile_result="tmp_results/{accession}-{genes_or_transcripts}s-quantile-counts.tsv"
    conda:
        "envs/ma_quantile_transform.yaml"
    shell:
        """
        {workflow.basedir}/bin/quantile_normalize.sh \
            -c {input.configuration_file} \
            -s {input.raw_counts_file} \
            -d {output.quantile_result}
        """

rule transform2R:
    input:
        quantile_result=rules.quantile_normalize.output.quantile_result,
        sdrf="data/{accession}.sdrf.txt",
        configuration_file=rules.quantile_normalize.input.configuration_file,
        methods_file="data/{accession}-analysis-methods.tsv"
    output:
        rdata="tmp_results/{accession}-{genes_or_transcripts}_summarizedExp.rdata"
    conda:
        "envs/ma_quantile_transform.yaml"
    shell:
        """
        {workflow.basedir}/bin/transform2R.r \
            --countstsv {input.quantile_result} \
            --sdrf {input.sdrf} \
            --configuration {input.configuration_file} \
            --methods {input.methods_file} \
            --batch study \
            --output {output.rdata}
        """

rule batch_correction_v2:
    input:
        counts=rules.transform2R.output.rdata
    output:
        summarized_rdata="tmp_results/{accession}-{genes_or_transcripts}-corrected_summarizedExp.rdata",
        tsv_corrected_counts="tmp_results/{accession}-{genes_or_transcripts}-corrected_counts.tsv"
    conda:
        "envs/ma_batch_correct_combat.yaml"
    shell:
        """
        {workflow.basedir}/bin/batch_correction_v2.R \
            -i {input.counts} \
            --output {output.summarized_rdata} \
            --tsv_corrected_counts {output.tsv_corrected_counts}
        """

rule irap_raw2metric:
    input:
        counts=rules.batch_correction_v2.output.tsv_corrected_counts,
        lengths="data/{accession}.lengths.Rdata"
    output:
        corrected="tmp_results/{accession}-{genes_or_transcripts}s-corrected-{metric}s"
    conda:
        "envs/ma_irap_components.yaml"
    shell:
        """
        irap_raw2metric -i {input.counts} \
            --lengths data/{wildcards.accession}.lengths.Rdata \
            --feature {wildcards.genes_or_transcripts} \
            --metric {wildcards.metric} \
            --out {output.corrected}
        """
