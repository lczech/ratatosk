# =================================================================================================
#     Chunkify and Unchunkify
# =================================================================================================

# We want the sample names of the output files to fit the naming given by the user.
# In case our input for the samples is a table with two columns, the sample names (first column)
# can be different from the file names. However, the gappa chunkify command uses file names as
# sample names. For now, it is easiest to just symlink to the files to get a list of properly
# named files. In the future, we might add an option to rename samples in gappa chunkify,
# to make this step a bit less convoluted...
rule chunkify_sample_prep:
    input:
        fasta=get_sample_fasta
    output:
        "chunkify/samples/{sample}.fasta"
    shell:
        "ln -s {input.fasta} {output}"

# No need to execute this on the cluster computed nodes.
localrules: chunkify_sample_prep

# The rule to chunkify input fasta samples (query sequences) into chunks of equal size without
# duplicate sequences.
# We need a snakemake checkpoint here, because we cannot predict the number of chunks being produced.
checkpoint chunkify:
    input:
        # Request renamed samples, using the rule above, to get chunkify to use proper sample names.
        expand( "chunkify/samples/{sample}.fasta", sample=samples.keys() )
        # get_all_sample_paths()
    output:
        chunks = directory("chunkify/chunks"),
        # abundances = directory("chunkify/abundances")
        abundances = expand("chunkify/abundances/abundances_{sample}.json", sample=samples.keys())
    params:
        hashfunction = config["params"]["chunkify"]["hash-function"],
        minabun = config["params"]["chunkify"]["min-abundance"],
        chunksize = config["params"]["chunkify"]["chunk-size"]
    log:
        "logs/chunkify.log"
    conda:
        "../envs/gappa.yaml"
    shell:
        "mkdir -p chunkify/chunks ; "
        "mkdir -p chunkify/abundances ; "
        "gappa prepare chunkify "
        "--fasta-path {input} "
        "--chunks-out-dir chunkify/chunks "
        "--abundances-out-dir chunkify/abundances "
        "--hash-function {params.hashfunction} "
        "--min-abundance {params.minabun} "
        "--chunk-size {params.chunksize} "
        "> {log} 2>&1"

# Following the documentation tutorial here:
# https://snakemake.readthedocs.io/en/stable/snakefiles/rules.html#data-dependent-conditional-execution
def aggregate_chunkify_chunks(wildcards):
    # Wildcards are ignored here, as the chunkify process is for the whole dataset,
    # so we do not have any wildcards to take into account;
    # but still have to use them in the argument list,
    # because otherwise snakemake complains.
    chunks     = checkpoints.chunkify.get().output["chunks"]
    # abundances = checkpoints.chunkify.get().output[1]
    return expand(
        "chunkify/placed/{chunk}.jplace",
        chunk = glob_wildcards( os.path.join(chunks, "{chunk}.fasta")).chunk
    )

rule unchunkify:
    input:
        aggregate_chunkify_chunks,
        expand("chunkify/abundances/abundances_{sample}.json", sample=samples.keys())
    output:
        protected( expand( "placed/{sample}.jplace", sample=samples.keys() ))
    params:
        hashfunction = config["params"]["chunkify"]["hash-function"]
    log:
        "logs/unchunkify.log"
    conda:
        "../envs/gappa.yaml"
    shell:
        "gappa prepare unchunkify "
        "--abundances-path chunkify/abundances "
        "--chunk-file-expression chunkify/placed/chunk_@.jplace " # TODO nope
        "--hash-function {params.hashfunction} "
        "--out-dir placed"
        "> {log} 2>&1"
