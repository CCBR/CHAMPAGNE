# Release Guide

## How to test a pre-release on biowulf

Install the development version of champagne.

```sh
# activate the conda env for development
. "/data/CCBR_Pipeliner/db/PipeDB/Conda/etc/profile.d/conda.sh"
conda activate py311

# go to the source on biowulf and update
cd /data/CCBR_Pipeliner/Pipelines/CHAMPAGNE/champagne-dev
git pull
# optionally switch to different branch if needed

# install the version to a hidden path (e.g. .dev, .v1.0.0.9000) in /data/CCBR_Pipeliner/Pipelines/CHAMPAGNE
cd ..
pip install ./champagne-dev -t ./.dev
# add it to your PATH and PYTHONPATH with:
export PATH="$PATH:/data/CCBR_Pipeliner/Pipelines/CHAMPAGNE/.dev/bin/"
export PYTHONPATH="$PYTHONPATH:/data/CCBR_Pipeliner/Pipelines/CHAMPAGNE/.dev/"
```
