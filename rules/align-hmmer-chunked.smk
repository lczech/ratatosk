# =================================================================================================
#     Setup Dependencies
# =================================================================================================

include: "align-hmmer-common.smk"

# =================================================================================================
#     Alignment with hmmer
# =================================================================================================

rule hmmer_align:
    input:
        msa = config["data"]["reference-alignment"],
        hmmprofile = "hmmer/profile.hmm",
        sample="chunkify/chunks/{sample}.fasta"
    output:
        sequences = "chunkify/aligned/{sample}.fasta"
    params:
        extra=config["params"]["hmmer"]["align-extra"],

        # states = ["dna"] if config["states"] == 0 else ["amino"]
        states = "dna"
    log:
        "logs/align/{sample}.log"
    conda:
        "../envs/hmmer.yaml"
    threads:
        config["params"]["hmmer"]["threads"]
    script:
        "../scripts/hmmer.py"
