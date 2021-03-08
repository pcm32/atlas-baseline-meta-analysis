# Atlas baseline meta-analysis

The current analysis setup enables to merge Atlas RNA-Seq baseline datasets that have the required compatibility in terms of metadata. To merge the metadata of datasets, you should use the [MAGE-Tab-merger](https://pypi.org/project/MAGE-Tab-merger/) package to produce:

- merged condensed SDRF file
- merged SDRF file
- merged XML configuration file

from an starting list of Atlas baseline experiment accessions. The process of dealing with the metadata will filter out datasets that cannot be merged due to experimental design or metadata limitations.

## Merge counts data prior to this analysis

The current analysis will also require a single counts table for all the selected studies. TODO how to obtain.

## Running the analysis

Once you have the following files in place in a `data` directory (TODO generalise this) with the `ACCESSION` being the newly minted accession for the merged dataset:

```
data/<ACCESSION>-analysis-methods.tsv
data/<ACCESSION>-configuration.xml
data/<ACCESSION>-raw-counts.tsv.undecorated
data/<ACCESSION>-transcripts-raw-counts.tsv.undecorated
data/<ACCESSION>.sdrf.tsv
data/reference.gtf
```

then run:

```
snakemake --cores 2 --use-conda --conda-frontend mamba \
tmp_results/<ACCESSION>-transcripts-corrected-fpkms \
tmp_results/<ACCESSION>-transcripts-corrected-tpms \
tmp_results/<ACCESSION>-genes-corrected-tpms \
tmp_results/<ACCESSION>-genes-corrected-fpkms
```

This will create results in two directories:

- tmp_results: main results, with all calculations for the merged dataset.
- lengths: where lengths per gene, exon and transcripts are produced, based on the reference GTF file provided. These are used to normalise to TPMs and FPKMs.
