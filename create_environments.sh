conda env list | awk '{ print $1 }' > existing_envs.txt

grep -s ma_quantile_transform existing_envs.txt
if [ $? -gt 0 ]; then
  conda create -y -n ma_quantile_transform -c ebi-gene-expression-group perl-xml-xpath r-optparse bioconductor-limma r-atlas-internal
fi

grep -s ma_batch_correct_combat existing_envs.txt
if [ $? -gt 0 ]; then
  conda create -y -n ma_batch_correct_combat r-optparse bioconductor-sva r-purrr r-magrittr bioconductor-summarizedexperiment
fi

grep -s ma_irap_components existing_envs.txt
if [ $? -gt 0 ]; then
  conda create -y -n ma_irap_components -c ebi-gene-expression-group irap-components
fi

rm existing_envs.txt
