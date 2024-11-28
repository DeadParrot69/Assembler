
args = commandArgs(trailingOnly=TRUE)

#install.packages('rmarkdown',repos='http://cran.us.r-project.org')
#install.packages('tinytex',repos='http://cran.us.r-project.org')
#install.packages('knitr',repos='http://cran.us.r-project.org')
#install.packages("pandoc",repos='http://cran.us.r-project.org')
#tinytex::install_tinytex() 
library('knitr')
library ('tinytex')
library ('rmarkdown')
library('pandoc')

print ("installed R-libraries")

#rmarkdown::render("report.Rmd", params=list (args="B23_A106"), output_file = paste ("Analysis_report","B23_A106", sep=""))
print (args)
rmarkdown::render("/fs/dss/groups/agmedmibi/Assembler/report.Rmd", params=list (args=args), output_file = paste ("/fs/dss/groups/agmedmibi/Assemblies/",args,"/Analysis_report_",args, sep=""))


