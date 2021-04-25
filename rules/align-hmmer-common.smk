# =================================================================================================
#     Auxilliary Rules and Functions
# =================================================================================================

rule hmmer_build:
    input:
        msa = config["data"]["reference-alignment"]
    output:
        hmmprofile = "hmmer/profile.hmm"
    params:
        extra=config["params"]["hmmer"]["build-extra"],
        # TODO allow different types of states, also below at align step
        # states = ["dna"] if config["states"] == 0 else ["amino"]
        states = "dna"
    log:
        "logs/hmmer/hmmer_build.log"
    threads:
        1
    conda:
        "../envs/hmmer.yaml"
    shell:
        "hmmbuild --cpu {threads} --{params.states} {params.extra} "
        "{output.hmmprofile} {input.msa} > {log} 2>&1"
