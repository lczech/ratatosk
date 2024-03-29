# =================================================================================================
#     Dependencies
# =================================================================================================

import pandas as pd
import os, re, sys
import socket, platform
import util

# Ensure min Snakemake version
snakemake.utils.min_version("5.7")

# =================================================================================================
#     Basic Configuration
# =================================================================================================

# Add a description of the workflow to the final report
# report: os.path.join(workflow.basedir, "reports/workflow.rst")

# Load the config. If --directory was provided, this is also loaded from there.
# This is useful to have runs that have different settings, but generally re-use the main setup.
configfile: "config.yaml"
# snakemake.utils.validate(config, schema="../schemas/config.schema.yaml")

# =================================================================================================
#     Get Samples List
# =================================================================================================


# Prepare a dictionary of samples, from name (used for our wildcards here, and hence for file
# naming within the pipeline) to absolute file paths.
samples = pd.read_table(config["data"]["samples"], dtype=str).set_index(["sample"], drop=False)

# Transform for ease of use
sample_names=list(set(samples.index.get_level_values("sample")))

print(sample_names)

# output prefix
outdir=config["settings"]["outdir"].rstrip("/")

hmmer_datatype_string  = "dna" if config["settings"]["datatype"] == 'nt' else "amino"

# =================================================================================================
#     Pipeline User Output
# =================================================================================================

# Get a nicely formatted hostname
hostname = socket.gethostname()
hostname = hostname + ("; " + platform.node() if platform.node() != socket.gethostname() else "")

# Some helpful messages
logger.info("===========================================================================")
logger.info("    RATATOSK")
logger.info("")
logger.info("    Host:               " + hostname)
logger.info("    Snakefile:          " + (workflow.snakefile))
logger.info("    Base directory:     " + (workflow.basedir))
logger.info("    Working directory:  " + os.getcwd())
logger.info("    Config files:       " + (", ".join(workflow.configfiles)))
logger.info("    Samples:            " + str(len(samples)))
logger.info("===========================================================================")
logger.info("")

# =================================================================================================
#     Common File Access Functions
# =================================================================================================

def get_sample_fasta(wildcards):
    """Get fasta file for a given sample"""
    return samples.loc[wildcards.sample, "input_file"]

# def get_all_sample_names():
#     """Get the samples names given to all fasta files"""
#     return list(samples.keys())

# def get_all_sample_paths():
#     """Get the paths to all fasta files"""
#     return list(samples.values())

# =================================================================================================
#     Config Related Functions
# =================================================================================================

def get_highest_override( tool, key ):
    """From the config, get the value labeled with "key", unless the "tool" overrides that value,
    in which case fetch the override"""

    if not tool in config["params"]:
        util.fail("invalid key for 'config['params']': '{}'".format( tool ))

    if key in config["params"][tool]:
        return config["params"][tool][key]
    else:
        return config["params"][key]
