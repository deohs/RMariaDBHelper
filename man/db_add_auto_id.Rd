% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/RMariaDBHelper.R
\name{db_add_auto_id}
\alias{db_add_auto_id}
\title{Add an id Field}
\usage{
db_add_auto_id(
  tablename,
  fieldname = "id",
  pk = TRUE,
  uniq = TRUE,
  conf_file = "~/.db_conf.yml"
)
}
\arguments{
\item{tablename}{(character) The table name that will get the new "id" field.}

\item{fieldname}{(character) The field name to use for the new "id" field.
(Default: "id")}

\item{pk}{(boolean) Add "id" as a PRIMARY KEY (TRUE) or not (FALSE).
(Default: TRUE)}

\item{uniq}{(boolean) Add "id" as a UNIQUE primary key (TRUE) or not (FALSE).
(Default: TRUE)}

\item{conf_file}{(character) A file containing database connection parameters.
(Default: "~/.db_conf.yml")}
}
\value{
(boolean) Success: TRUE; failure: FALSE.
}
\description{
Add an auto-number integer "id" field to a table.
}
\section{Details}{

An auto-incrementing, non-null, non-negative integer "id" field will be
added to a table, set as an index, and optionally set as a primary key.
}

\examples{
\dontrun{
db_add_auto_id("iris")
}
}
\keyword{MariaDB,}
\keyword{database,}
\keyword{sql,}
\keyword{utility}
