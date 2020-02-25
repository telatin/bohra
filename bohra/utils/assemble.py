import toml, pathlib, subprocess, sys

def generate_asm_cmd(assembler, r1, r2, isolate, threads = 8, memory = 16):
    
    if assembler == 'shovill':
        cmd = f"shovill --R1 {r1} --R2 {r2} --outdir {isolate}/shovill --cpus {threads} --ram {memory} --force"
    elif assembler == 'spades':
        cmd = f"spades.py -1 {r1} -2 {r2} -o {isolate}/spades --threads {threads} --memory {memory}"
    else:
        cmd = f"skesa --fastq {r1},{r2} --contigs_out {isolate}/contigs.fa --cores {threads} --memory {memory}"
    
    return cmd


def generate_cmd(prfl, r1, r2, isolate, assembler, data):
    
    prfl = pathlib.Path(prefill, isolate, 'contigs.fa')
    if prfl.exists():
        cmd = f"cp {prfl} {isolate}/contigs.fa"
        data[isolate]['assembly']['source'] = f"Prefilled from: {prfl}"
    else:
        cmd = generate_asm_cmd(assembler = assembler, r1 = r1, r2 = r2, isolate = isolate)
        data[isolate]['assembly']['source'] = cmd

    return cmd, data

def generate_mv_cmd(assembler, isolate):

    cmd = f"mv {isolate}/{assembler}/contigs.fa {isolate}/contigs.fa"
    return cmd

def run_cmd(cmd):
    
    p = subprocess.run(cmd, shell = True, capture_output=True, encoding = 'utf-8')
    return p.returncode
   

def open_toml(tml):

    data = toml.load(tml)

    return data

def write_toml(data, output):
    
    with open(output, 'wt') as f:
        toml.dump(data, f)
    
def main(r1, r2, isolate, assembler, prefill, seqdata):
    
    # set up data dict
    seqdata = open_toml(tml = seqdata)
    
    data = {}
    data[isolate] = {}
    data[isolate]['assembly'] = {}
    # run kraken
    # data[isolate]['seqdata']['data']['Quality']
    if seqdata[isolate]['seqdata']['data']['Quality'] == 'PASS':
        cmd, data = generate_cmd(prfl = prefill, r1 = r1, r2 = r2, isolate = isolate, assembler =assembler, data = data)
        assembly_returncode = run_cmd(cmd)
        if assembly_returncode == 0:

            # add to data dict
            data[isolate]['assembly']['done'] = True
            data[isolate]['assembly']['assembler'] = assembler
    else:
        data[isolate]['assembly']['done'] = False
        data[isolate]['assembly']['assembler'] = f"Assembly not performed - failed QC"

    write_toml(data = data, output= 'assembly.toml')



if __name__ == '__main__':
    
    main(r1 = f"{sys.argv[1]}", r2 = f"{sys.argv[2]}", isolate = f"{sys.argv[3]}",  prefill =  f"{sys.argv[4]}", seqdata =  f"{sys.argv[5]}")
    

