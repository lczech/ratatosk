import os

# =================================================================================================
#     Auxilliary Rules and Functions
# =================================================================================================

rule raxml_ng_model_eval:
    input:
        reftree = config["data"]["reference-tree"],
        refmsa = config["data"]["reference-alignment"]
    output:
        "model/model_eval.raxml.bestModel"
    params:
        model = config["params"]["epa-ng"]["model"]
    log:
        "logs/model/model_eval.log"
    conda:
        "../envs/raxml-ng.yaml"
    shell:
        "raxml-ng --evaluate "
        "--msa {input.refmsa} "
        "--tree {input.reftree} "
        "--model {params.model} "
        "--prefix model/model_eval "
        "> {log} 2>&1"

rule epa_ng_split_sample:
    input:
        sample = "aligned/{sample}.fasta",
        refmsa = config["data"]["reference-alignment"]
    output:
        query = temp("split/{sample}/query.fasta"),
        reference = temp("split/{sample}/reference.fasta")
        # Somehow, piping doesn't work here, it just stalls endlessly. Need to investigate later.
        # query = pipe("split/{sample}/query.fasta"),
        # reference = pipe("split/{sample}/reference.fasta")
    log:
        "logs/split/{sample}.log"
    conda:
        "../envs/epa-ng.yaml"
    group:
        "epa_ng_place"
    shell:
        "epa-ng "
        "--split {input.refmsa} {input.sample} "
        "--out-dir split/{wildcards.sample} "
        "> {log} 2>&1"

def epa_ng_place_model( context ):
    # epa-ng expects a model of evolution to be given either as a string (such as the model
    # string used in raxml-ng), or as a file (such as the best model output file of raxml-ng).
    # For snakemake, this is tricky, because if we are given a file, we want this to exist.
    # If its a string, not. If it's emtpy however, we create the file ourself first (via the above rule),
    # and so also want to point to a file.
    # So let's use a function to make this distinction:
    # The function is called twice, from within the input, and from within the params section.
    # If this function is called with `context == input`, we return files (if appropriate),
    # so that snakemake can look for them. If `context == params` however, this is the function call
    # for the params, where we return the model string if it is not a file.
    if config["params"]["epa-ng"]["model-params"] == "":
        # Use the raxml best model file
        inp = "model/model_eval.raxml.bestModel"
        prm = ""
    elif os.path.isfile( config["params"]["epa-ng"]["model-params"] ):
        # Use the provided file
        inp = config["params"]["epa-ng"]["model-params"]
        prm = ""
    else:
        # Use the provided model string
        inp = ""
        prm = config["params"]["epa-ng"]["model-params"]

    # One of them has to be empty. This way, we can just concatenate them in the rule below.
    assert(( inp == "" ) ^ ( prm == "" ))
    if context == "input":
        return inp
    elif context == "params":
        return prm
    else:
        print("Invalid epa_ng_place_model context: " + context )
        sys.exit(1)

# =================================================================================================
#     Placement with epa-ng
# =================================================================================================

rule epa_ng_place:
    input:
        # Input reference tree and alignment. We here do not use the original reference alignment,
        # but the one resulting from the above split step instead, as this is guaranteed to have
        # the same width as the query alignment. Unfortunately, some aligners (such as version 3 of
        # hmmalign) mess around with gaps, so that the produced alignment does not fit with the
        # original any more. Hence, we cannot use the original here, and use the split one instead.
        reftree = config["data"]["reference-tree"],
        refmsa = "split/{sample}/reference.fasta",
        # refmsa = config["data"]["reference-alignment"],

        # Input sample, as provided by the above split rule.
        sample = "split/{sample}/query.fasta",

        # Get the model param file from the config if it is a file, or, if that is empty,
        # request a file, which will be created by the raxml_ng_model_eval rule.
        # If it is neither a file nor empty, we assume it's an actual model string, which will
        # be used below in the params section then.
        model = epa_ng_place_model( "input" )
    output:
        # epa-ng always names the output file `epa_result.jplace`. We rename this to a more useful
        # name per sample here.
        protected("placed/{sample}.jplace")
        # protected("placed/{sample}/epa_result.jplace")
    params:
        # Get the model if it is a string (and not a file).
        model = epa_ng_place_model( "params" ),

        # Get any extra params to use with epa-ng
        extra = config["params"]["epa-ng"]["extra"]
    log:
        "logs/place/{sample}.log"
    conda:
        "../envs/epa-ng.yaml"
    group:
        "epa_ng_place"
    threads:
        config["params"]["epa-ng"]["threads"]
    shell:
        # Due to epa-ng insisting in naming its output `epa_result.jplace`, we have to create
        # per-sample directories, and move the files later on. Quite cumbersone, but necessary.
        "mkdir -p placed/{wildcards.sample} ; "
        "epa-ng "
        "--redo "
        "--ref-msa {input.refmsa} "
        "--tree {input.reftree} "
        "--query {input.sample} "
        "--outdir placed/{wildcards.sample} "
        "--model {input.model}{params.model} "
        "--threads {threads} "
        "{params.extra} "
        "> {log} 2> ; "
        "mv placed/{wildcards.sample}/epa_result.jplace placed/{wildcards.sample}.jplace ; "
        "mv placed/{wildcards.sample}/epa_info.log logs/place/epa_info-{wildcards.sample}.log ; "
        "rm -rf placed/{wildcards.sample}"
