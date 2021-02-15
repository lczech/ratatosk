# =================================================================================================
#     Placement with epa-ng
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
        "raxml-ng --evaluate --msa {input.refmsa} --tree {input.reftree} --model {params.model} "
        "--prefix model/model_eval > {log} 2>&1"

rule epa_ng_split_sample:
    input:
        sample = "aligned/{sample}.fasta",
        refmsa = config["data"]["reference-alignment"]
    output:
        query = temp("split/{sample}/query.fasta"),
        reference = temp("split/{sample}/reference.fasta")
        # query = pipe("split/{sample}/query.fasta"),
        # reference = pipe("split/{sample}/reference.fasta")
    log:
        "logs/split/{sample}.log"
    conda:
        "../envs/epa-ng.yaml"
    shell:
        "epa-ng --split {input.refmsa} {input.sample} --out-dir split/{wildcards.sample} "
        "> {log} 2>&1"

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

        # Get the model params (file or string, both accepted by epa-ng) from the condig, or,
        # if that is empty, request a file, which will be created by the raxml_ng_model_eval rule.
        model = config["params"]["epa-ng"]["model-params"] or "model/model_eval.raxml.bestModel"
    output:
        # epa-ng always names the output file `epa_result.jplace`. We rename this to a more useful
        # name per sample here.
        protected("placed/{sample}.jplace")
        # protected("placed/{sample}/epa_result.jplace")
    params:
        extra = config["params"]["epa-ng"]["extra"]
    log:
        "logs/place/{sample}.log"
    conda:
        "../envs/epa-ng.yaml"
    threads:
        config["params"]["epa-ng"]["threads"]
    shell:
        # Due to epa-ng insisting in naming its output `epa_result.jplace`, we have to create
        # per-sample directories, and move the files later on. Quite cumbersone, but necessary.
        "mkdir -p placed/{wildcards.sample} ; "
        "epa-ng --redo --ref-msa {input.refmsa} --tree {input.reftree} --query {input.sample} "
        "--outdir placed/{wildcards.sample} --model {input.model} --threads {threads} {params.extra} "
        "> {output[0]} 2> {log} ; "
        "mv placed/{wildcards.sample}/epa_result.jplace placed/{wildcards.sample}.jplace ; "
        "mv placed/{wildcards.sample}/epa_info.log logs/place/epa_info-{wildcards.sample}.log ; "
        "rm -rf placed/{wildcards.sample}"
