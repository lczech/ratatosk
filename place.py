#!/usr/bin/env python3

import multiprocessing
import argparse, sys, os
sys.path.insert(0, './scripts')
from util import *
from datetime import datetime
import pandas as pd
import snakemake
import platform

# if we're on mac/arm, default back down to x86 compiled packages
# ideally this decision would be per-package availability
if( platform.machine() == 'arm64' ):
  os.environ['CONDA_SUBDIR'] = "osx-64"

parser = argparse.ArgumentParser(description='Wrapper to run the pipeline with some default settings.')
parser.add_argument('--fasta-paths', dest='fasta_files', type=str, nargs='+',
                    help='input fasta files', required=True)
parser.add_argument('--reference-tree', dest='ref_tree', type=str,
                    help='Reference tree, in newick format', required=True)
parser.add_argument('--reference-msa', dest='ref_msa', type=str,
                    help='Reference MSA, in fasta format', required=True)
parser.add_argument('--model-file', dest='model_file', type=str,
                    help='Reference tree, in newick format', required=True)

parser.add_argument('-d', '--datatype', dest='datatype', type=str, nargs='?',
                    const='nt', default='nt', choices=['nt', 'aa'],
                    help="datatype, 'aa' for protein, 'nt' for DNA data")
parser.add_argument('--out-dir', dest='out_dir', type=str,
                    default=None,
                    help='optional output directory. By default, the script creates a timestamped output directory.')
parser.add_argument('-p', '--prefix', dest='prefix', type=str,
                    default=None,
                    help='prefix to fasta paths and output (useful to specify where data was mounted to in docker)')

parser.add_argument('--threads', dest='threads', type=int,
                    default=multiprocessing.cpu_count(),
                    help='number of threads to use')
parser.add_argument('-v','--verbose', dest='verbose', action='store_true',
                    help='increase verbosity')
args = parser.parse_args()

# input validation
for f in args.fasta_files:
  expect_file_exists( f )

expect_file_exists( args.ref_tree )
expect_file_exists( args.ref_msa )
expect_file_exists( args.model_file )

if( args.prefix ):
  expect_dir_exists( args.prefix )

# make a unique output dir, labeled by date and time
out_dir = "search-{}".format(datetime.now().strftime("%Y-%m-%d-%H:%M:%S")) if( not args.out_dir ) else args.out_dir

# build up a samples.tsv file to be used in this execution
# 
# first read in a unique list of all the desired files
file_paths = []
if( args.fasta_files ):
  file_paths.extend( ingest_paths( args.fasta_files, extensions=['.fa', '.afa', '.fasta'] ) )

def get_unique_names( paths ):
  """
  We want to extract unique sample names from the file paths of the input files.
  To do so, we attempt to keep prepending directory names to the proposed sample
  names, until we have a unique set of names (the idea being that the user has encoded 
  the information about what the samples are called in their directory structure).
  Note that this can still fail, for example if the input files share name and directory,
  but not file extension ('x.fa x.fasta' for example).
  """

  names = []
  # extend by at most as long as the longest path
  for i in range(0, max( [num_dirs( f ) for f in paths] )):

    failed=False
    for path in paths:
      # get at most i preceding dir names as prefixes
      prefixes = last_n_dirnames( path, i )
      prefixes.append( filename( path ) )
      new_name = '_'.join( prefixes )
      if( new_name in names ):
        failed = True
        names = []
        break
      else:
        names.append( new_name )

    if( not failed ):
      break

  if( failed ):
    fail( "Could not find assignment of unique names to list of input files. The list:\n{paths}" )

  assert( len(names) == len(paths) )

  return names

# add file paths to the samples, giving it a sample name corresponding to the file name / directory
samples = pd.DataFrame({
  'sample':get_unique_names(file_paths),
  'input_file':file_paths
  }).set_index( 'sample' )

# finally, write the samples.tsv to the output folder
make_path( out_dir )
samples_file = os.path.join( out_dir, "samples.tsv" )
samples.to_csv( samples_file, sep='\t' )

# next, we set those config values that we wish to override from the defaults, by creating a dict
# of those values
config_overrrides = {
  'data':
  {
    'samples': samples_file,
    'reference-tree': args.ref_tree,
    'reference-alignment': args.ref_msa
  },
  'settings':
  {
    'outdir': out_dir,
    'datatype': args.datatype
  },
  'params':
  {
    'threads': args.threads
  }
}

calling_dir = os.path.dirname(os.path.abspath(__file__))

snakemake.snakemake(
  snakefile=os.path.join( calling_dir, "Snakefile" ),
  use_conda=True,
  cores=args.threads,
  config=config_overrrides,
  config_args=["dummy=0"]
  )
