#James Diao
#July 11, 2016
#Kohane Lab

library(dplyr)
library(tidyr)
library(scrapeR)
library(RMySQL)
setwd("/Users/jamesdiao/Documents/Kohane_Lab/")
load(file = paste(getwd(), "ACMG.files", sep = "/HST-2016/week_5/"))

#Union-Join
ACMG_Variant <- lapply(1:num.genes, function(i) {
  id.1000g <- ACMG.1000g.id[[i]]$ID
  id.exac <- ACMG.exac.id[[i]]$ID
  all.vars <- sort(union(id.1000g, id.exac))
  AF_1000G <- AF_ExAC <- rep(NULL, length(all.vars))
  AF_1000G[all.vars %in% id.1000g] <- as.numeric(ACMG.1000g.id[[i]]$AF)
  AF_ExAC [all.vars %in% id.exac]  <- as.numeric(ACMG.exac.id[[i]]$Allele.Frequency)
  data.frame("Gene"     = I(gene.list[i]),
             "ID"       = I(all.vars),
             "AF_1000G" = AF_1000G,
             "AF_ExAC"  = AF_ExAC)
})
af_cor <- sapply(1:num.genes, function(i) cor(freq.join[[i]]['AF_1000G'], freq.join[[i]]['AF_ExAC']))
plot(af_cor, ylim = c(0,1))

#Setup Data Table
ACMG_Variant <- lapply(1:num.genes, function(i) {
  temp <- separate(ACMG_Variant[[i]], "ID", c("Chrom","Position","Ref","Alt"))
  temp$Position <- as.numeric(temp$Position)
  temp
})
ACMG_Variant <- do.call(rbind, ACMG_Variant)
#output <- data.frame("NumKey" = 1:nrow(output), output)

setwd("/Users/jamesdiao/Documents/Kohane_Lab/")
write.loc.ACMG.variant <- paste(getwd(),"ACMG_Variant.txt",sep="/HST-2016/week_5/")
write.table(ACMG_Variant, file = write.loc.ACMG.variant, sep = "\t", na = "\\N", quote = FALSE, row.names = FALSE, col.names = FALSE)

write.loc.ACMG.disease <- paste(getwd(),"ACMG_Disease.txt",sep="/HST-2016/week_5/")
write.table(ACMG.table, file = write.loc.ACMG.disease, sep = "\t", na = "\\N", quote = FALSE, row.names = FALSE, col.names = FALSE)



#######################################
###  Upload to host on MySQL table  ###
#######################################

for (con in dbListConnections(MySQL())) dbDisconnect(con)
con <- dbConnect(MySQL(), dbname = 'kohane_lab', host = 'localhost', user = 'root', password = 'root',
                 unix.sock = "/Applications/MAMP/tmp/mysql/mysql.sock")
query <- function (input) { suppressWarnings(dbGetQuery(con, input)) }

#query("drop table ACMG_Variant")
#query(paste("create table ACMG_Variant (Gene varchar(20), Chrom varchar(3), Position int,Ref varchar(30),",
#      "Alt varchar(30), AF_1000G decimal(15,10), AF_ExAC decimal(15,10))", sep=""))
query("describe ACMG_Variant")
paste("load data local infile '",write.loc.ACMG.variant,"' into table ACMG_Variant lines terminated by '\n'", sep = "") %>% query
query("select * from ACMG_Variant limit 3")

#query("drop table ACMG_Disease")
#query("create table ACMG_Disease (Disease varchar(200), Disease_MIM varchar(10), Gene varchar(20), Gene_MIM varchar(10))")
query("describe ACMG_Disease")
paste("load data local infile '",write.loc.ACMG.disease,"' into table ACMG_Disease lines terminated by '\n'", sep = "") %>% query
query("select * from ACMG_Disease limit 3")



#write(ACMG.table$Disease_Name, paste(getwd(),"ACMG_Disease_Names.txt",sep="/HST-2016/week_5/"))
ACMG_lit <- read.delim(stringsAsFactors = F, sep = "\t", header = T, file = paste(getwd(),"ACMG_Lit_Full.txt",sep="/HST-2016/week_5/"))
ACMG_lit$Prevalence <- 1/ACMG_lit$Inverse.Prevalence
ACMG_lit <- select(ACMG_lit, Disease, Prevalence, Citation)
write.loc.ACMG.lit <- paste(getwd(),"ACMG_Lit.txt",sep="/HST-2016/week_5/")
write.table(ACMG_lit, file = write.loc.ACMG.lit, sep = "\t", na = "\\N", quote = FALSE, row.names = FALSE, col.names = FALSE)

#query("drop table ACMG_Lit")
#query("create table ACMG_Lit (Disease varchar(200), Prevalence decimal (10,9), Citation varchar(300))")
query("describe ACMG_Lit")
paste("load data local infile '",write.loc.ACMG.lit,"' into table ACMG_Lit lines terminated by '\n'", sep = "") %>% query
query("select * from ACMG_Lit limit 5")

geneinfo <- read.delim(file = paste(getwd() , "ACMG_gene_info_tab_delim.txt", sep = "/")  )
write.table(geneinfo, file = paste(getwd() , "ACMG_gene_info_tab_delim_no_header.txt", sep = "/"),
            quote = F, col.names = F, row.names = F, sep = "\t")

query("drop table ACMG_Gene")
query("create table ACMG_Gene (gene varchar(20), chrom varchar (3), txstart int, txend int)")
query("describe ACMG_Gene")
paste("load data local infile '",paste(getwd() , "ACMG_gene_info_tab_delim_no_header.txt", sep = "/"), "' into table ACMG_Gene lines terminated by '\n'", sep = "") %>% query
query("select * from ACMG_Gene")









