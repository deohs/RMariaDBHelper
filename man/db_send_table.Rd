% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/RMariaDBHelper.R
\name{db_send_table}
\alias{db_send_table}
\title{Save a Dataframe as a Table}
\usage{
db_send_table(df, tablename, conf_file = "~/.db_conf.yml", ...)
}
\arguments{
\item{df}{(dataframe) A dataframe to send to the database.}

\item{tablename}{(character) A table name to use for the new table.}

\item{conf_file}{(character) A file containing database connection parameters.
(Default: "~/.db_conf.yml")}

\item{...}{Additional arguments passed to RMariaDB::dbWriteTable().}
}
\value{
(boolean) Success: TRUE; failure: FALSE.
}
\description{
Send a dataframe to the database as a new table.
}
\section{Details}{

A dataframe will be sent to the database to be stored as a new table.
}

\examples{
\dontrun{
db_send_table(datasets::iris, "iris")
}
}
\keyword{MariaDB,}
\keyword{database,}
\keyword{sql,}
\keyword{utility}
