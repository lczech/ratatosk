![ratatosk logo](/docs/logo/logo.png?raw=true)

Snakemake pipeline for phylogenetic placement of metagenomic sequences.

**Advantages**:

  - Simplicity: Only expects your files (and settings), and runs everything for you.
  - Interoperability: Takes care of file format (in)compatibility between tools.
  - Scalability: Works from single files to large datasets, also in cluster environments.

This pipeline is meant for worry-free single-stop placement to run analyses on your data.
We recommend to use it in combination with the excellent
[PEWO workflow](https://github.com/phylo42/PEWO). PEWO determines the best tools and settings
to be used for accurate placement &ndash; which you can then set in ratatosk to get the best of
both worlds: accurate and scalable placement.

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
  - Visualization
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
to which all of the Nine Worlds are connected. Like our mundane squirrels,
Ratatosk enjoys whizzing through Yggdrasil’s many branches &ndash;
which is also how phylogenetic placement algorithms operate!
He is regarded as a troublemaker though,
which we hope is a quality that is not reflected in our software.
