import csv
import json
import argparse

parser = argparse.ArgumentParser() # Initialize Parser
parser.add_argument("filename") # Adding positional argument
# parser.add_argument("-i", "--input", help = "Name of the Input File") # Adding optional Argument
args = parser.parse_args() # Read arguments from commandline

a = 0
column_name =["CreationTime", "Operation", 'UserId', 'ObjectId']

with open(args.filename, mode = 'r') as audit, open('results-{}'.format(args.filename), mode = 'w') as result:
    csvFile = csv.reader(audit)
    writer = csv.DictWriter(result, fieldnames=column_name)
    writer.writeheader() # Writing column names to result file
    
    for lines in csvFile: # Skipping the non json line of input file
        if a == 0:
            a = a+1
            continue
            
        obj = json.loads(lines[5]) # Assigning JSON object. Index should be 5 for report pulled from Purview portal and 4 for report from script

        print(obj)
        input()
        row = "{CreationTime}, {Operation}, {UserId}, {ObjectId}".format(**obj) # Formatting the string to write to result
        # print(row)
        result.write(row) # Writing the row to result file
        result.write("\n")

print("Results have been exported")