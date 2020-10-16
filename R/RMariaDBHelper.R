#' Read Configuration
#'
#' Read database configuration file.
#' @param conf_file (character) Configuration file to read/write.
#'     (Default: "~/.db_conf.yml")
#' @param username (character) Username. See: RMariaDB::MariaDB. (Default: "")
#' @param host (character) Database erver hostname. See: RMariaDB::MariaDB.
#'     (Default: "")
#' @param dbname (character) Database name. See: RMariaDB::MariaDB. (Default: "")
#' @param sslmode (character) SSL mode. See: RMariaDB::MariaDB. (Default: "")
#' @param sslca (character) CCL CA path. See: RMariaDB::MariaDB. (Default: "")
#' @param sslkey (character) SSL key path. See: RMariaDB::MariaDB. (Default: "")
#' @param sslcert (character) SSL certificate path. See: RMariaDB::MariaDB.
#'     (Default: "")
#' @return (boolean) TRUE for success; FALSE for failure.
#' @keywords database, sql, MariaDB, utility
#' @section Details:
#' A configuration file will be read if found, otherwise one will be created.
#' @examples
#' \dontrun{
#' # First, run once to create the file with the values provided:
#' db_read_conf(conf_file = "~/.db_conf.yml",
#'              username = "my_username",
#'              host = "db.server.example.com",
#'              dbname = "my_dbname",
#'              sslmode = "REQUIRED",
#'              sslca = "/etc/db-ssl/ca-cert.pem",
#'              sslkey = "/etc/db-ssl/client-key-pkcs1.pem",
#'              sslcert = "/etc/db-ssl/client-cert.pem")
#' # You will see warnings about the file not existing and/or needs editing.
#'
#' # Subsequently, read the file once per session:
#' db_conf <- db_read_conf()
#' }
#' @export
db_read_conf <- function(conf_file = "~/.db_conf.yml",
                         username = '',
                         host = '',
                         dbname = '',
                         sslmode = '',
                         sslca = '',
                         sslkey = '',
                         sslcert = '') {
    if (file.exists(conf_file)) {
        db_conf <<- yaml::read_yaml(file = conf_file)
        return(exists("db_conf") & is.list(db_conf) & length(db_conf) > 0)
    } else {
        db_conf <<-
            list(
                username = username,
                host = host,
                dbname = dbname,
                sslmode = sslmode,
                sslca = sslca,
                sslkey = sslkey,
                sslcert = sslcert
            )
        try(yaml::write_yaml(db_conf, file = conf_file))
        warning(paste("Edit", conf_file, "for correct database settings."))
        return(FALSE)
    }
}

#' Initialize Connection
#'
#' Initialize a connection to the database and return a DBIConnection.
#' @param conf_file (character) A file containing database connection parameters.
#'     (Default: "~/.db_conf.yml")
#' @return (DBIConnection) A DBIConnection for success; FALSE for failure.
#' @keywords database, sql, MariaDB, utility
#' @section Details:
#' A configuration file will be read and used to connect to the database.
#' @examples
#' \dontrun{
#' channel <- db_connect()
#' }
#' @export
db_connect <- function(conf_file = "~/.db_conf.yml") {
    if (!exists("db_conf")) db_read_conf(conf_file)

    if(exists("db_conf")) {
        if (!"password" %in% names(db_conf) & Sys.getenv("RSTUDIO") == "1") {
            db_conf[['password']] <- rstudioapi::askForPassword("Password:")
            db_conf <<- db_conf
        }

        if (db_conf[['username']] != '' & db_conf[['password']] != '') {
            if (!"drv" %in% names(db_conf)) {
                db_conf <- c(drv = RMariaDB::MariaDB(), db_conf)
            }

            do.call(RMariaDB::dbConnect, c(db_conf))
        }
    } else {
        warning(paste("Can't read", conf_file))
        return(FALSE)
    }
}

#' Run a Query
#'
#' Run a database query that returns the number of affected rows.
#' @param query (character) A SQL statement as a text string.
#' @param conf_file (character) A file containing database connection parameters.
#'     (Default: "~/.db_conf.yml")
#' @return (integer) The number of affected rows.
#' @keywords database, sql, MariaDB, utility
#' @section Details:
#' A SQL statement will be run and the number of affected rows will be returned.
#' @examples
#' \dontrun{
#' db_run_query("DELETE FROM my.tablename WHERE id = 1;")
#' }
#' @export
db_run_query <- function(query, conf_file = "~/.db_conf.yml") {
    channel <- db_connect(conf_file)
    if (!isFALSE(channel)) {
        res <- RMariaDB::dbExecute(channel, query)
        res_discon <- suppressWarnings(RMariaDB::dbDisconnect(channel))
        res
    }
}

#' Add an id Field
#'
#' Add an auto-number integer "id" field to a table.
#' @param tablename (character) The table name that will get the new "id" field.
#' @param fieldname (character) The field name to use for the new "id" field.
#'     (Default: "id")
#' @param pk (boolean) Add "id" as a primary key (TRUE) or not (FALSE).
#'     (Default: TRUE)
#' @param conf_file (character) A file containing database connection parameters.
#'     (Default: "~/.db_conf.yml")
#' @return (boolean) Success: TRUE; failure: FALSE.
#' @keywords database, sql, MariaDB, utility
#' @section Details:
#' An auto-incrementing, non-null, non-negative integer "id" field will be
#' added to a table, set as an index, and optionally set as a primary key.
#' @examples
#' \dontrun{
#' db_add_auto_id("iris")
#' }
#' @export
db_add_auto_id <- function(tablename, fieldname = "id", pk = TRUE,
                           conf_file = "~/.db_conf.yml") {
    pk_str <- ifelse(pk == TRUE, 'PRIMARY KEY', '')
    query <- paste("ALTER TABLE", tablename,
                   "ADD", fieldname, "INT UNSIGNED NOT NULL AUTO_INCREMENT",
                   pk_str, ", ADD INDEX (", fieldname, ");")
    db_run_query(query, conf_file = conf_file)
}

#' Fetch Results from a Query
#'
#' Run a database query that returns a dataframe.
#' @param query (character) A SQL statement as a text string.
#' @param conf_file (character) A file containing database connection parameters.
#'     (Default: "~/.db_conf.yml")
#' @return (dataframe) The query result returned as a dataframe.
#' @keywords database, sql, MariaDB, utility
#' @section Details:
#' A SQL statement will be run and a dataframe of results will be returned.
#' @examples
#' \dontrun{
#' db_fetch_query("SELECT * FROM my.tablename LIMIT 10;")
#' }
#' @export
db_fetch_query <- function(query, conf_file = "~/.db_conf.yml") {
    channel <- db_connect(conf_file)
    if (!isFALSE(channel)) {
        res_db <- RMariaDB::dbGetQuery(channel, query)
        res_discon <- suppressWarnings(RMariaDB::dbDisconnect(channel))
        res_db
    }
}

#' List tables in a database.
#'
#' Run a database query that lists the tables in a database.
#' @param conf_file (character) A file containing database connection parameters.
#'     (Default: "~/.db_conf.yml")
#' @return (character) The names of the tables in a database.
#' @keywords database, sql, MariaDB, utility
#' @section Details:
#' A SHOW TABLES query will return the names of the tables in the database.
#' @examples
#' \dontrun{
#' db_ls()
#' }
#' @export
db_ls <- function(conf_file = "~/.db_conf.yml") {
    as.character(db_fetch_query("SHOW TABLES;", conf_file = conf_file)[[1]])
}

#' Show structure of a table.
#'
#' Run a database query that returns a dataframe.
#' @param tablename (character) A table name to query for structure.
#' @param conf_file (character) A file containing database connection parameters.
#'     (Default: "~/.db_conf.yml")
#' @return (dataframe) The query result returned as a dataframe.
#' @keywords database, sql, MariaDB, utility
#' @section Details:
#' A SHOW COLUMNS query will return a dataframe of columns and their properties.
#' @examples
#' \dontrun{
#' db_str("iris")
#' }
#' @export
db_str <- function(tablename, conf_file = "~/.db_conf.yml") {
    query <- paste("SHOW COLUMNS FROM", tablename)
    db_fetch_query(query, conf_file = conf_file)
}

#' Count number of columns of a table.
#'
#' Run a database query that returns the number of columns in a table.
#' @param tablename (character) A table name to query for number of columns.
#' @param conf_file (character) A file containing database connection parameters.
#'     (Default: "~/.db_conf.yml")
#' @return (integer) The number of columns in a table.
#' @keywords database, sql, MariaDB, utility
#' @section Details:
#' A SQL query will return a dataframe containing the number of columns.
#' @examples
#' \dontrun{
#' db_ncol("iris")
#' }
#' @export
db_ncol <- function(tablename, conf_file = "~/.db_conf.yml") {
    as.integer(nrow(db_str(tablename, conf_file = conf_file)))
}

#' Count number of rows of a table.
#'
#' Run a database query that returns the number of rows in a table.
#' @param tablename (character) A table name to query for number of rows.
#' @param conf_file (character) A file containing database connection parameters.
#'     (Default: "~/.db_conf.yml")
#' @return (integer) The number of rows in a table.
#' @keywords database, sql, MariaDB, utility
#' @section Details:
#' A SELECT COUNT query will return the number of rows in a table.
#' @examples
#' \dontrun{
#' db_nrow("iris")
#' }
#' @export
db_nrow <- function(tablename, conf_file = "~/.db_conf.yml") {
    query <- paste("SELECT COUNT(*) as rows FROM", tablename)
    as.integer(db_fetch_query(query, conf_file = conf_file)[[1]])
}

#' Show dimensions of a table.
#'
#' Run database queries that returns the number of rows and columns in a table.
#' @param tablename (character) A table name to query for number of columns.
#' @param conf_file (character) A file containing database connection parameters.
#'     (Default: "~/.db_conf.yml")
#' @return (integer) A vector containing the count of rows and columns in a table.
#' @keywords database, sql, MariaDB, utility
#' @section Details:
#' SQL queries will return a vector containing the number of rows and columns.
#' @examples
#' \dontrun{
#' db_dim("iris")
#' }
#' @export
db_dim <- function(tablename, conf_file = "~/.db_conf.yml") {
    c(db_nrow(tablename, conf_file = conf_file),
      db_ncol(tablename, conf_file = conf_file))
}

#' Save a Dataframe as a Table
#'
#' Send a dataframe to the database as a new table.
#' @param df (dataframe) A dataframe to send to the database.
#' @param tablename (character) A table name to use for the new table.
#' @param conf_file (character) A file containing database connection parameters.
#'     (Default: "~/.db_conf.yml")
#' @return (boolean) Success: TRUE; failure: FALSE.
#' @keywords database, sql, MariaDB, utility
#' @section Details:
#' A dataframe will be sent to the database to be stored as a new table.
#' @examples
#' \dontrun{
#' db_send_table(datasets::iris, "iris")
#' }
#' @export
db_send_table <- function(df, tablename, conf_file = "~/.db_conf.yml") {
    channel <- db_connect(conf_file)
    if (!isFALSE(channel)) {
        res <- RMariaDB::dbWriteTable(channel, tablename, df)
        res_discon <- suppressWarnings(RMariaDB::dbDisconnect(channel))
        res
    }
}

#' Append a Dataframe to a Table
#'
#' Send a dataframe to the database to append to a table.
#' @param df (dataframe) A dataframe to append to a database table.
#' @param tablename (character) A table name to receive additional records.
#' @param conf_file (character) A file containing database connection parameters.
#'     (Default: "~/.db_conf.yml")
#' @return (integer) Number of affected (appended) rows.
#' @keywords database, sql, MariaDB, utility
#' @section Details:
#' A dataframe will be sent to the database to be appended to an existing table.
#' @examples
#' \dontrun{
#' db_append_table(datasets::iris, "iris")
#' }
#' @export
db_append_table <- function(df, tablename, conf_file = "~/.db_conf.yml") {
    channel <- db_connect(conf_file)
    if (!isFALSE(channel)) {
        res <- RMariaDB::dbAppendTable(channel, tablename, df)
        res_discon <- suppressWarnings(RMariaDB::dbDisconnect(channel))
        res
    }
}

#' Fetch a Table
#'
#' Retrieve a database table as a dataframe.
#' @param tablename (character) A table name to query for all records.
#' @param n (integer) The number of rows to return. (Default -1 means all rows.)
#' @param conf_file (character) A file containing database connection parameters.
#'     (Default: "~/.db_conf.yml")
#' @return (dataframe) The query result returned as a dataframe.
#' @keywords database, sql, MariaDB, utility
#' @section Details:
#' A SQL query will return a table as a dataframe. Use 'n' to limit the number
#' of rows returned.
#' @examples
#' \dontrun{
#' db_fetch_table("iris")
#' }
#' @export
db_fetch_table <- function(tablename, n = -1, conf_file = "~/.db_conf.yml") {
    channel <- db_connect(conf_file)
    if (!isFALSE(channel)) {
        res <- RMariaDB::dbSendQuery(channel, paste("SELECT * FROM", tablename))
        df <- RMariaDB::dbFetch(res, n)
        RMariaDB::dbClearResult(res)
        res_discon <- suppressWarnings(RMariaDB::dbDisconnect(channel))
        df
    }
}

#' Remove a Table
#'
#' Remove a table from a database.
#' @param tablename (character) A table name to remove from the database.
#' @param conf_file (character) A file containing database connection parameters.
#'     (Default: "~/.db_conf.yml")
#' @return (boolean) Success: TRUE; failure: FALSE.
#' @keywords database, sql, MariaDB, utility
#' @section Details:
#' A table will be removed from the database.
#' @examples
#' \dontrun{
#' db_rm("iris")
#' }
#' @export
db_rm <- function(tablename, conf_file = "~/.db_conf.yml") {
    channel <- db_connect(conf_file = conf_file)
    if (!isFALSE(channel)) {
        res <- RMariaDB::dbRemoveTable(channel, tablename)
        res_discon <- suppressWarnings(RMariaDB::dbDisconnect(channel))
        res
    }
}
