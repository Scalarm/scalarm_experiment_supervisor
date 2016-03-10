repo = "http://cran.uk.r-project.org"
list.of.packages <- c("rjson", "sensitivity", "httr", "stringr", "methods")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if (length(new.packages) > 0)
    install.packages(new.packages, repos = repo, quiet = FALSE)
