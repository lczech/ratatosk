![ratatosk logo](/docs/logo/logo.png?raw=true)

Snakemake pipeline for phylogenetic placement of metagenomic sequences.

**Advantages**:

  - Takes care of the whole placement process
  - Optimized for large datasets and cluster environments

This pipeline is meant for worry-free single-stop placement.
We recommend to use it in combination with the excellent
[PEWO workflow](https://github.com/phylo42/PEWO),
which determines the best tools and settings to be used prior to running ratatosk.

Pipeline Overview
-------------------

**Minimal input:**

  - Reference phylogenetic tree (newick)
  - Reference multiple-sequence alignment (fasta or phylip)
  - Query sequences to be placed (fasta)

**Process and available tools:**

  - Aligning queries
    - ...
  - Placing queries
    - ...

**Output:**

  - Placed sequences (jplace)

Getting Started
-------------------

See [**the Wiki pages**](https://github.com/lczech/ratatosk/wiki) for setup and documentation.

For **bug reports and feature requests**, please
[open an issue](https://github.com/lczech/ratatosk/issues).

What's in a name?!
-------------------

In Norse mythology, Ratatosk, the drill-tooth, lives in the world-tree Yggdrasil,
to which all of the Nine Worlds are linked. Like our mundane squirrels,
Ratatosk enjoys whizzing through Yggdrasil’s many branches.
He is regarded as a troublemaker, which we hope is a quality that is not reflected in our software.
