import toml, pathlib, subprocess, sys


def generate_cmd(r1, r2, isolate):
    
    cmd = f"mash sketch -r {r1} {r2} -m 3 -k 31 -C {isolate} -o {isolate}/sketch"
    return cmd

def run_cmd(cmd):
    
    p = subprocess.run(cmd, shell = True, capture_output=True, encoding = 'utf-8')
    return p.stderr

def extract_metrics(mash_string):
    mash_string = mash_string.split('\n')
    d = ''
    for m in mash_string:
        print(m)
        if 'Estimated coverage' in m:
            d = m.split(':')[-1].strip()
            print(d)
            return d
    
def write_toml(data, output):
    
    with open(output, 'wt') as f:
        toml.dump(data, f)
    
def main(r1, r2, isolate, output):
    
    cmd = generate_cmd(r1 = r1, r2 = r2, isolate = isolate)
    mash_string = run_cmd(cmd)
    # print(mash_string)
    data = {}
    data[isolate] = {}
    data[isolate]['mash'] = {}
    data[isolate]['mash']['Estimated coverage'] = extract_metrics(mash_string)
    data[isolate]['mash']['sketch'] = f"{pathlib.Path(f'{isolate}', 'sketch.msh')}"

    write_toml(data = data, output= f'{isolate}/mash.toml')
    


if __name__ == '__main__':
    
    main(r1 = f"{sys.argv[1]}", r2 = f"{sys.argv[2]}", isolate = f"{sys.argv[3]}", output = f"{sys.argv[4]}")
    

