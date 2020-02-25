workdir:{% raw %}{% endraw %} '{{workdir}}'{% raw %}
configfile: 'config.yaml'
localrules: all, generate_yield, combine_seqdata, qc_snippy, index_reference, calculate_iqtree_command_core,combine_assembly_metrics,assembly_statistics,collate_report,write_html_report

def get_collation_input(pipeline):
	
	s = "{sample}/seqdata.toml"
	k = "{sample}/kraken.toml"
	output = [s,k]
	a = [
		"{sample}/mlst.toml",
		"{sample}/assembly.toml",
		"{sample}/resistome.toml",
		"{sample}/prokka.toml"
		]
	s = [
		"{sample}/snippy.toml",
		"{sample}/snippy_qc.toml"
		]
		
	if pipeline == 'sa' or pipeline == 'all':
		for x in s:
			output.append(x)
		for y in a:
			output.append(x)
	elif pipeline == 'a':
		for y in a:
			output.append(x)
	elif pipeline == 's':
		for x in s:
			output.append(x)

	return output


def get_report_tomls(pipeline):
	output = ["seqdata.toml"
		"kraken.toml"]
	a = ["mlst.toml", 
		"assembly.toml", 
		"resistome.toml"]
	s = ['gubbins.toml', 'snippy_core.toml']
	r = ["roary.toml",
		'pan_genome.toml']
	
	if pipeline == 'sa':
		for x in s:
			output.append(x)
		for y in a:
			output.append(y)
	elif pipeline == 'a':
		for y in a:
			output.append(y)
	elif pipeline == 's':
		for x in s:
			output.append(x)
	elif pipeline == 'all':
		for x in s:
			output.append(x)
		for y in a:
			output.append(y)
		for z in r:
			output.append(z)
	
	return output



PREFILLPATH = config['prefill_path']
SAMPLE = config['isolates'].split()
MIN_ALN = int(config['min_perc'])
REFERENCE = config['reference']
GUBBINS = config['gubbins']
PIPELINE = config['pipeline']
ALL_TOMLS = get_collation_input(pipeline = PIPELINE)
print(ALL_TOMLS)
REPORT_TOMLS = get_report_tomls(pipeline = PIPELINE)
print(REPORT_TOMLS)
WORKDIR = config['workdir']
JOB_ID = config['job_id']
ASSEMBLER = config['assembler']
TEMPLATE_PATH = config['template_path']
SCRIPT_PATH = config['script_path']
MASK_STRING = config['mask_string']
PREVIEW = config['preview']	
KRAKEN_DB=config['kraken_db']
MIN_COV = config['min_cov']

if GUBBINS:
	CORE_OUTPUT = 'gubbins.aln'
else:
	CORE_OUTPUT = 'core.aln'
	
rule all:
	input:
		"report.html", "report.toml",
		expand("{sample}/final.toml", sample = SAMPLE)

rule estimate_coverage:
	input:
		r1="{sample}/R1.fq.gz",
		r2="{sample}/R2.fq.gz"
	output:
		"{sample}/mash.toml"
	# singularity:{% endraw %}"{{singularity_dir}}/mash_kmc"{% raw %}
	shell:
		"""
		python3 {params.script_path}/mash.py {input.r1} {input.r2} {wildcards.sample} {output}
		"""

rule seqdata:
	input:
		r1 = '{sample}/R1.fq.gz',
		r2 = '{sample}/R2.fq.gz',
		mash = '{sample}/mash.toml'
	output:
		"{sample}/seqdata.toml"
	params:
		script_path=SCRIPT_PATH,
		mincov = MIN_COV
	# singularity:{% endraw %}"{{singularity_dir}}/seqtk"{% raw %}
	shell:
		"""
		python3 {params.script_path}/seqdata.py {input.r1} {input.r2} {wildcards.sample} {input.mash} {params.mincov}
		"""

rule combine_seqdata:
	input:
		expand("{sample}/seqdata.toml", sample = SAMPLE)
	output:
		"seqdata.tab"
	params:
		script_path=SCRIPT_PATH
	shell:
		"""
		python3 {params.script_path}/combine_seqdata.py {input} {output}
		"""

if preview:
	rule preview:
		input:
			expand("{sample}/mash.toml", sample = SAMPLE)
		output:
			expand("{sample}/preview.toml", sample = SAMPLE)
		params:
			reference = REFERENCE,
			script_path = SCRIPT_PATH
		shell:
			"""
			python3 {params.script_path}/preview.py {input} {output}
			"""
	rule combine_preview_tomls:
		input:
			"{sample}/preview.toml"
		output:
			"{sample}/final.toml"
		shell:
			"""
			cp {input} {output}
			"""
	rule compile:
		input:
			expand("{sample}/preview.toml", sample = SAMPLE)
		output: #this is where I stopped
			"report.toml"
		params:
			pipeline = 'preview',
			script_path = SCRIPT_PATH,
			job_id = JOB_ID
		shell:
			"""
			python3 {params.script_path}/compile.py {input} {params.pipeline} {params.job_id}
			"""
else:
	rule run_kraken:
		input:
			r1='{sample}/R1.fq.gz',
			r2='{sample}/R2.fq.gz'
		output:
			"{sample}/kraken.toml"
		params:
			prefill_path = PREFILLPATH,
			kraken_db = KRAKEN_DB,
			script_path = SCRIPT_PATH
		shell:
			"""
			python3 {params.script_path}/kraken.py {input.r1} {input.r2} {wildcards.sample} {params.kraken_db}
			"""
	rule combine_kraken:
		input:
			expand("{sample}/kraken.toml", sample = SAMPLE)
		output:
			"kraken.toml"
		params:
			script_path = SCRIPT_PATH
		shell:
			"""
			python3 {params.script_path}/combine_kraken.py {input}
			"""
	
	if PIPELINE != 'a': 
		rule snippy:
			input:
				'{sample}/seqdata.toml'
				
			output:
				'{sample}/snippy.toml',
			threads:
				8
			singularity:{% endraw %}"{{singularity_dir}}/snippy"{% raw %}
			params:
				script_path=SCRIPT_PATH,
				reference = REFERENCE
			shell:
				"""
				python3 {params.script_path}/snippy.py {input} {wildcards.sample} {output} {params.reference} {threads}
				"""
			

		rule qc_snippy: 
			input:
				'{sample}/snippy.toml'
				
			output:
				'{sample}/snippy_qc.toml'
			params:
				script_path = SCRIPT_PATH,
				minalin = MIN_ALN
			shell:
				"""
				python3 {params.script_path}/snippy.py {input} {wildcards.sample} {output} {params.minaln}
				"""

		rule run_snippy_core:
			input:
				expand("{sample}/snippy_qc.toml", sample = SAMPLE)
			output:
				'snippy_core.toml'
				# 'core.vcf',
				# 'core.txt',
				# 'core.aln', 
				# 'core.full.aln',
				# 'core.tab'
			singularity:{% endraw %}"{{singularity_dir}}/snippy"{% raw %}
			params:
				mask_string = MASK_STRING,
				script_path = SCRIPT_PATH,
				reference = REFERENCE
			shell:
				"""
				python3 {params.script_path}/snippy_core.py {input} {params.mask_string} {params.reference}
				"""

		rule run_gubbins:
			input:
				'snippy_core.toml'
			output:
				'gubbins.toml'
			params:
				script_path = SCRIPT_PATH,	
				gubbins = GUBBINS
			shell:
				"""
				python3 {params.script_path}/gubbins.py {input} {params.gubbins}
				"""

		rule run_snpdists:
			input:
				'gubbins.toml'
			output:
				'distances.toml' 
			# singularity:{% endraw %}"{{singularity_dir}}/snippy"{% raw %}
			params:
				script_path = SCRIPT_PATH
			shell:
				"""
				python3 {params.script_path}/snpdists.py {input}
				"""
			

		rule index_reference:
			input:
				REFERENCE
			output:
				"ref.fa",
				"ref.fa.fai"
			run:
				from Bio import SeqIO
				import pathlib, subprocess
				ref = f"{output[0]}"
				idx = f"{output[1]}"
				print(type(ref))
				print(type(idx))
				if '.fa' not in REFERENCE:
					print(f"converting {REFERENCE}")
					SeqIO.convert(f"{input[0]}", 'genbank', ref	, 'fasta')
					print(f"converted {REFERENCE}")
				else:
					subprocess.run(f"ln -sf {REFERENCE} {ref}", shell = True)
				subprocess.run(f"samtools faidx {ref}", shell =True)

		rule run_iqtree_core:
			input:
				'gubbins.toml', 'ref.fa', 'ref.fa.fai'
			
			output:
				'iqtree.toml',
			params:
				script_path = SCRIPT_PATH	
			# singularity:{% endraw %}"{{singularity_dir}}/iqtree"{% raw %}
			shell:
				"""	
				python3 {params.script_path}/iqtree.py {input} {params.script_path}
				"""
				
		
	if PIPELINE != 's':
		rule assemble:
			input:
				'{sample}/seqdata.toml'
			output:
				'{sample}/assembly.toml'
			threads:
				16
			params:
				prefill_path = PREFILLPATH,
				assembler = ASSEMBLER, 
				script_path = SCRIPT_PATH
			# singularity:{% endraw %}"{{singularity_dir}}/assemblers"{% raw %}
			shell:
				"""
				python3 {params.script_path}/assembly.py {input} {wildcards.sample}  {params.assembler}
				"""
		rule assembly_statistics:
			input:
				"{sample}/assembly.toml"
			output:
				"{sample}/assembly_stats.toml"
			params:
				script_path = SCRIPT_PATH
			shell:
				"""
				python3 {params.script_path}/assembly_stat.py {input} {wildcards.sample}
				"""
			
		rule run_prokka:
			input:
				"{sample}/assembly_stats.toml"
			output:
				"{sample}/prokka.toml"
			params:
				script_path = SCRIPT_PATH
			# singularity:{% endraw %}"{{singularity_dir}}/prokka"{% raw %}
			shell:
				"""
				python3 {params.script_path}/prokka.py {input} {wildcards.sample}
				"""
		

		rule combine_assembly_metrics:
			input:
				prokka = expand("{sample}/prokka.toml",sample = SAMPLE), 
				assembly = expand("{sample}/assembly_stats.toml",sample = SAMPLE)
			output:
				"assembly.toml"
			params:
				script_path= SCRIPT_PATH
			shell:
				"""
				python3 {params.script_path}/prokka.py {input.assembly} {assembly.prokka}
				"""


		rule resistome:
			input:
				assembly = "{sample}/assembly.toml",
				seqdata = '{sample}/seqdata.toml'
			output:
				'{sample}/resistome.toml'
			# singularity:{% endraw %}"{{singularity_dir}}/abricate"{% raw %}
			shadow:
				"full"
			params:
				script_path= SCRIPT_PATH
			shell:
				"""
				python3 {params.script_path}/resistome.py {input.assembly} {wildcards.sample} {input.seqdata}
				"""
		rule combine_resistome:
			input:
				expand("{sample}/resistome.toml", sample = SAMPLE)
			output:
				'resistome.toml'
			params:
				script_path=SCRIPT_PATH
			shell:
				"""
				python3 {params.script_path}/combine_resistome.py {input}
				"""

		rule mlst:
			input:
				assembly = "{sample}/assembly.toml",
				seqdata = "{sample}/seqdata.toml"
			output:
				'{sample}/mlst.toml'
			params:
				script_path=SCRIPT_PATH
			# singularity:{% endraw %}"{{singularity_dir}}/mlst"{% raw %}
			shell:
				"""
				python3 {params.script_path}/mlst.py {input.assembly} {wildcards.sample} {input.seqdata}
				"""		
		rule combine_mlst:
			input:
				expand('{sample}/mlst.toml', sample = SAMPLE)
			output:
				"mlst.toml"
			params:
				script_path = SCRIPT_PATH
			shell:
				"""
				python3 {script_path}/combine_mlst.py {input}
				"""
			
		

	if PIPELINE == 'all':
	
		rule run_roary:
			input:
				prokka = expand("{sample}/prokka.toml",sample = SAMPLE)
			output:
				"roary.toml"
			params:
				script_path = SCRIPT_PATH
			shell:
				"""
				python3 {script_path}/roary.py {input}
				"""

		rule pan_figure:
			input:
				"roary.toml"
			output:
				"pan_genome.toml"
			params:
				script_path = SCRIPT_PATH
			shell:
				"""
				python3 {script_path}/pan_figure.py {input} {params.script_path} 
				"""

	rule collate_isolate_tomls:
		input:
			ALL_TOMLS
		output:
			"{sample}/final.toml"
		params:
			script_path = SCRIPT_PATH
		shell:	
			"""
			python3 {script_path}/collate_tomls.py {input}
			"""
		
	rule compile_report_toml:
		input:
			REPORT_TOMLS
		output:
			"report.toml"
		params:
			pipeline = PIPELINE,
			script_path = SCRIPT_PATH,
			assembler = ASSEMBLER, 
			job_id = JOB_ID
		shell:
			"""
			python3 {params.script_path}/compile.py {input} {params.pipeline} {params.job_id} {params.assembler} 
			"""

rule write_html_report:
	input:
		"report.toml"
	output:
		'report.html'
	params:
		work_dir = WORKDIR,
		jobid = JOB_ID,
		assembler = ASSEMBLER,
		template_path = TEMPLATE_PATH,
		script_path = SCRIPT_PATH,
		pipeline = PIPELINE
	shell:
		"""
		python3 {params.script_path}/write_report.py {input} {params.work_dir} {params.template_path}
		"""