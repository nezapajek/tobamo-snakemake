import sys
import pandas as pd
import os

# combine_results.py {input} {output}

filenames = sys.argv[1:-1]
out = sys.argv[-1]

dfs = []
for filename in filenames:
    if os.stat(filename).st_size != 0:
        dfs.append(pd.read_csv(filename, index_col=0))
    else:
        pass
dfs

dfs_concat = pd.concat(dfs) #ignore_index=True

dfs_concat.to_csv(out)