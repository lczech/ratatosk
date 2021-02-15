# =================================================================================================
#     Dependencies
# =================================================================================================

import pandas as pd
import os, re, sys
import socket, platform

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

# Prepare regex for all sample files that we are looking for.
regex = re.compile("([^/\\\\]*)\\.(fasta|fas|fsa|fna|ffn|faa|frn)(\\.gz)?$")

# Prepare a dictionary of samples, from name (used for our wildcards here, and hence for file
# naming within the pipeline) to absolute file paths.
samples = {}
def add_sample( name, path ):
    if name in samples:
        print("Duplicate sample name '" + name + "' for file paths " + samples[name] + " and " + path )
        sys.exit(1)
    samples[name] = os.path.realpath(path)
    # samples.append(( m.group(1), os.path.realpath(file) ))

# Get sample file list. Depends on what is given in the config.
if os.path.isdir( config["data"]["samples"] ):
    # Directory. Scan for files matching the regex, and use their base names as sample names.
    for root, dirs, files in os.walk( config["data"]["samples"] ):
        for file in files:
            m = regex.match(file)
            if m:
                # If a file matches, get its file base name as sample name.
                fp = os.path.join( root, file )
                add_sample( m.group(1), os.path.realpath(fp) )

elif os.path.isfile( config["data"]["samples"] ):
    # File. Read its contents line by line.
    # Also, remove whitespace characters like `\n` at the end of each line.
    with open( config["data"]["samples"] ) as fh:
        for line in fh.readlines():
            # If the line contanis a tab, split it into sample name and path.
            parts = line.split("\t")
            if len(parts) == 2:
                add_sample( parts[0].strip(), os.path.realpath(parts[1].strip()) )

            elif len(parts) == 1:
                # If not, use the path, and extract the sample name, that is, no path, no common
                # extensions. Here, we cannot use the regex from above, as the file extensions
                # might be different. Instead, we filter by common file types that we expect - and
                # everything else will just be left as is.
                sample = os.path.basename(line.strip())
                sample = re.sub('\\.gz$', '', sample)
                sample = re.sub('\\.fasta$', '', sample)
                sample = re.sub('\\.fas$', '', sample)
                sample = re.sub('\\.fsa$', '', sample)
                sample = re.sub('\\.fna$', '', sample)
                sample = re.sub('\\.ffn$', '', sample)
                sample = re.sub('\\.faa$', '', sample)
                sample = re.sub('\\.frn$', '', sample)
                path = os.path.realpath(line.strip())
                add_sample( sample, path )

            else:
                print("Invalid sample line in table that contains more than two columns." )
                sys.exit(1)
else:
    print("Invalid sample path: " + config["data"]["samples"] )
    sys.exit(1)

# print(str(samples))

# Transform for ease of use
# sample_names=list(set(samples.index.get_level_values("sample")))
# unit_names=list(set(samples.index.get_level_values("unit")))

# Wildcard constraints: only allow sample names from the spreadsheet to be used
# wildcard_constraints:
#     sample="|".join(sample_names)

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
    return samples[wildcards.sample]
