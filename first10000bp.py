


def extract_subsequence(fasta_file, start, end, output_file):
    with open(fasta_file) as f:
        seq = ''.join(line.strip() for line in f if not line.startswith('>'))
    
    subsequence = seq[start-1:end]
    
    with open(output_file, 'w') as out:
        out.write(f">subsequence\n{subsequence}\n")

    print(f"Subsequence from {start} to {end} saved to {output_file}")

# Example usage
extract_subsequence('assembly.fasta', 1, 10000, 'first10000bp.fasta')