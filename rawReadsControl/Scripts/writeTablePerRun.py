'''
Created on 29 nov. 2016

@author: herault
'''
import csv
import sys
import re
import zipfile

run = sys.argv[1]

#run = "/gpfs/tgml/herault/qualityControl/Run_165_NS500-072_24.11.2016_DP_BSoS"

c = csv.writer(open(run+"/result/general_report/qualityMetrics.csv", "w"))
c.writerow(["Num_echantillon","nom","Reads","Nombre_sequences_total","Duplicats%","GC%",">=Q30%"])

try:
    FileNotFoundError
except NameError:
    FileNotFoundError = IOError


with open(run+"/result/general_report/multiqc/multiqc_data/multiqc_general_stats.txt","r") as f:
    lines=f.readlines() 

indexSample = lines[0].split("\n")[0].split("\t").index("Sample")
indexDup = lines[0].split("\n")[0].split("\t").index("FastQC_percent_duplicates")
indexTotalSeq = lines[0].split("\n")[0].split("\t").index("FastQC_total_sequences")
indexPercentGC = lines[0].split("\n")[0].split("\t").index("FastQC_percent_gc")


for i in range(1,len(lines)):
    if (lines[i].split("\t")[indexSample].split("_")[0].startswith('S')):	## Au cas ou Undetermined quand bcl2fastq manuel -> rajout longueur moyenne?
        IDread = lines[i].split("\t")[indexSample].split("_")[0].split("S")[1] 
    else:
        IDread = 'NA' 
    regexR = re.compile("_R[12]_")
    sampleName = lines[i].split("\t")[indexSample].split(regexR.search(lines[i]).group())[0]
    r = regexR.search(lines[i]).group().split("_")[1]
    duplicates = lines[i].split("\t")[indexDup]
    totalSequences = lines[i].split("\t")[indexTotalSeq]
    percentGC = lines[i].split("\t")[indexPercentGC]  ## pb de retour à la ligne sur run 129??
    
    try:
        zip_fileFastqcData = zipfile.ZipFile(run + "/result/fastqc/" + sampleName +"/"+sampleName + "_" + r + "_001_fastqc.zip")    #TO DO rendre indépendant des noms des fichiers avec recherche de re
        zip_fileFastqcData.extractall(run + "/result/fastqc/" + sampleName +"/")
        zip_fileFastqcData.close()
        fileFastqcData=open(run + "/result/fastqc/" + sampleName +"/"+sampleName + "_" + r + "_001_fastqc/fastqc_data.txt","r")
        fileFastqcContent=fileFastqcData.readlines()
        moduleStart = fileFastqcContent.index([l for l in fileFastqcContent if l.startswith(">>Per sequence quality scores")][0])
        moduleEnd = fileFastqcContent[moduleStart:].index([l for l in fileFastqcContent[moduleStart:] if l.startswith(">>END_MODULE")][0])
        perSequenceQuality = fileFastqcContent[moduleStart+2:moduleStart+moduleEnd]
        dataQual=[q.rstrip("\n").split("\t") for q in perSequenceQuality]
        qualCount = [[int(dataQual[i][0]),float(dataQual[i][1])] for i in range(len(dataQual))]
        q30 = [i for i in qualCount if i[0] >= 30]
        q30Count = sum([i[1] for i in q30])
        totalCount = sum([i[1] for i in qualCount])
        q30percent = (q30Count/totalCount)*100
        print(IDread,sampleName, r, totalSequences, duplicates, percentGC, q30percent)
        c.writerow([IDread,sampleName, r, totalSequences, duplicates, percentGC, q30percent])
        fileFastqcData.close()	
    except FileNotFoundError:
        pass
