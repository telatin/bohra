import toml, pathlib, subprocess, sys, pandas, json


def get_roary(inputs):

    tml = open_toml(inputs)
    return tml['roary']['csv']

def generate_svg_cmd(script_path, csv, output):

    cmd = f"perl {script_path}/roary2svg.pl {csv} > {output}"
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
    
def main(inputs, script_path):
    
    csv = get_roary(inputs)
    data = {}
    data['pan_figure'] = {}
    data['pan_figure']['figure'] = "pan_genome.svg"   
    fig = run_cmd(generate_svg_cmd(csv = csv, script_path = script_path, output = data['pan_figure']['figure']))
    if fig == 0:
        data['pan_figure']['done'] = True
    else:
        data['pan_figure']['done'] = False
    write_toml(data = data, output= f'pan_genome.toml')



if __name__ == '__main__':
    
    main(inputs = f"{sys.argv[1]}", script_path = f"{sys.argv[2]}")
    
