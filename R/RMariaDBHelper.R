#' Write Configuration
#'
#' Write database configuration settings to a file.
#' @param conf_file (character) Configuration file to write.
#'     (Default: "~/.db_conf.yml")
#' @param username (character) Username.  (Default: NULL)
#' @param host (character) Database server hostname.
#'     (Default: NULL)
#' @param dbname (character) Database name. (Default: NULL)
#' @param sslmode (character) SSL mode. (Default: NULL)
#' @param sslca (character) CCL CA path. (Default: NULL)
#' @param sslkey (character) SSL key path. (Default: NULL)
#' @param sslcert (character) SSL certificate path. (Default: NULL)
#' @keywords database, sql, MariaDB, utility
#' @section Details:
#' A configuration file will be created with the values provided. For details
#' about the arguments, see the documentation for RMariaDB::dbConnect.
#' @examples
#' \dontrun{
#' db_write_conf(conf_file = "~/.db_conf.yml",
#'               username = "my_username",
#'               host = "db.server.example.com",
#'               dbname = "my_dbname",
#'               sslmode = "REQUIRED",
#'               sslca = "/etc/db-ssl/ca-cert.pem",
#'               sslkey = "/etc/db-ssl/client-key-pkcs1.pem",
#'               sslcert = "/etc/db-ssl/client-cert.pem")
#' file.edit("~/.db_conf.yml")
#' }
#' @export
db_write_conf <- function(conf_file = "~/.db_conf.yml",
                          username = NULL,
                          host = NULL,
                          dbname = NULL,
                          sslmode = NULL,
                          sslca = NULL,
                          sslkey = NULL,
                          sslcert = NULL) {
      db_conf <-
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
}

#' Read Configuration
#'
#' Read database configuration file.
#' @param conf_file (character) Configuration file to read/write.
#'     (Default: "~/.db_conf.yml")
#' @keywords database, sql, MariaDB, utility
#' @section Details:
#' A configuration file will be read if found, otherwise one will be created.
#' @examples
#' \dontrun{
#' db_read_conf()
#' }
#' @export
db_read_conf <- function(conf_file = "~/.db_conf.yml") {
    if (file.exists(conf_file)) {
        db_conf <<- yaml::read_yaml(file = conf_file)
        return(exists("db_conf") & is.list(db_conf) & length(db_conf) > 0)
    } else {
        warning("Configuration file does not exist. Creating one...")
        db_write_conf(conf_file = conf_file)
        return(FALSE)
    }
}

#' Initialize Connection
#'
#' Initialize a connection to the database and return a DBIConnection.
#' @param conf_file (character) A file containing database connection parameters.
#'     (Default: "~/.db_conf.yml")
#' @param ... Additional arguments passed to RMariaDB::MariaDB().
#' @return (DBIConnection) A DBIConnection for success; FALSE for failure.
#' @keywords database, sql, MariaDB, utility
#' @section Details:
#' A configuration file will be read and used to connect to the database.
#' @examples
#' \dontrun{
#' channel <- db_connect()
#' }
#' @export
db_connect <- function(conf_file = "~/.db_conf.yml", ...) {
    if (!exists("db_conf")) db_read_conf(conf_file)

    if(exists("db_conf")) {
        if (!"password" %in% names(db_conf)) {
            db_conf[['password']] <- getPass::getPass()
            db_conf <<- db_conf
        }

        if (db_conf[['username']] != '' & db_conf[['password']] != '') {
            if (!"drv" %in% names(db_conf)) {
                db_conf <- c(drv = RMariaDB::MariaDB(), db_conf)
            }

            do.call(RMariaDB::dbConnect, c(db_conf, ...))
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
#' @param ... Additional arguments passed to RMariaDB::dbExecute().
#' @return (integer) The number of affected rows.
#' @keywords database, sql, MariaDB, utility
#' @section Details:
#' A SQL statement will be run and the number of affected rows will be returned.
#' @examples
#' \dontrun{
#' db_run_query("DELETE FROM my.tablename WHERE id = 1;")
#' }
#' @export
db_run_query <- function(query, conf_file = "~/.db_conf.yml", ...) {
    channel <- db_connect(conf_file = conf_file)
    if (!isFALSE(channel)) {
        res <- RMariaDB::dbExecute(channel, query, ...)
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
#' @param pk (boolean) Add "id" as a PRIMARY KEY (TRUE) or not (FALSE).
#'     (Default: TRUE)
#' @param uniq (boolean) Add "id" as a UNIQUE primary key (TRUE) or not (FALSE).
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
db_add_auto_id <- function(tablename, fieldname = "id", pk = TRUE, uniq = TRUE,
                           conf_file = "~/.db_conf.yml") {
    pk_str <- ifelse(pk == TRUE, 'PRIMARY KEY', '')
    uniq_str <- ifelse(uniq == TRUE, 'UNIQUE', '')
    tablename <- paste0('`', gsub('[`;]', '', tablename), '`')
    index_name <- paste0('`ndx_', gsub('[`;]', '', fieldname), '`')
    fieldname <- paste0('`', gsub('[`;]', '', fieldname), '`')
    query <- paste("ALTER TABLE", tablename,
                   "ADD", fieldname, "INT UNSIGNED NOT NULL AUTO_INCREMENT",
                   pk_str, ", ADD", uniq_str, "INDEX", index_name, "(",
                   fieldname, ");")
    db_run_query(query, conf_file = conf_file)
}

#' Fetch Results from a Query
#'
#' Run a database query that returns a dataframe.
#' @param query (character) A SQL statement as a text string.
#' @param conf_file (character) A file containing database connection parameters.
#'     (Default: "~/.db_conf.yml")
#' @param ... Additional arguments passed to RMariaDB::dbGetQuery().
#' @return (dataframe) The query result returned as a dataframe.
#' @keywords database, sql, MariaDB, utility
#' @section Details:
#' A SQL statement will be run and a dataframe of results will be returned.
#' @examples
#' \dontrun{
#' db_fetch_query("SELECT * FROM my.tablename LIMIT 10;")
#' }
#' @export
db_fetch_query <- function(query, conf_file = "~/.db_conf.yml", ...) {
    channel <- db_connect(conf_file = conf_file)
    if (!isFALSE(channel)) {
        res_db <- RMariaDB::dbGetQuery(channel, query, ...)
        res_discon <- suppressWarnings(RMariaDB::dbDisconnect(channel))
        res_db
    }
}

#' List Tables in a Database.
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

#' Show Column Names for a Table
#'
#' Show a list of column (field) names for a table in a database.
#' @param tablename (character) A table name to query for column (field) names.
#' @param conf_file (character) A file containing database connection parameters.
#'     (Default: "~/.db_conf.yml")
#' @return (character) A vector of column (field) names.
#' @keywords database, sql, MariaDB, utility
#' @section Details:
#' The database will be queried for column (field) names for a table. These
#' names will be returned as a character vector.
#' @examples
#' \dontrun{
#' db_colnames("iris")
#' }
#' @export
db_colnames <- function(tablename, conf_file = "~/.db_conf.yml") {
  channel <- db_connect(conf_file = conf_file)
  if (!isFALSE(channel)) {
    res_db <- RMariaDB::dbListFields(channel, tablename)
    res_discon <- suppressWarnings(RMariaDB::dbDisconnect(channel))
    res_db
  }
}

#' Show Length and Size of Tables.
#'
#' Run a database query that lists the length and size of database tables.
#' @param conf_file (character) A file containing database connection parameters.
#'     (Default: "~/.db_conf.yml")
#' @return (dataframe) The length and size of each tables in a database.
#' @keywords database, sql, MariaDB, utility
#' @section Details:
#' A SQL query performed on information_schema.TABLES will return the length
#' and size of each table in the database and return the result as a dataframe.
#' @examples
#' \dontrun{
#' db_len()
#' }
#' @export
db_len <- function(conf_file = "~/.db_conf.yml") {
  if (!exists("db_conf")) db_read_conf(conf_file = conf_file)
  query <- paste0(
      'SELECT TABLE_NAME, TABLE_ROWS, DATA_LENGTH, INDEX_LENGTH,
      round(((DATA_LENGTH + INDEX_LENGTH) / 1024 / 1024),2) "Size in MB"
      FROM information_schema.TABLES WHERE TABLE_SCHEMA = "', db_conf$dbname,
      '" ORDER BY (DATA_LENGTH + INDEX_LENGTH) DESC;')
  db_fetch_query(query, conf_file = conf_file)
}

#' Show structure of a table.
#'
#' Run a database query on a table that shows the columns and their properties.
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
    tablename <- paste0('`', gsub('[`;]', '', tablename), '`')
    query <- paste("SHOW COLUMNS FROM", tablename)
    db_fetch_query(query, conf_file = conf_file)
}

#' Get the Type of a Field.
#'
#' Run a database query on a table that shows the type of a field (column).
#' @param tablename (character) A table name to query for structure.
#' @param fieldname (character) A field name to query for Field Type.
#' @param conf_file (character) A file containing database connection parameters.
#'     (Default: "~/.db_conf.yml")
#' @return (character) The Field Type.
#' @keywords database, sql, MariaDB, utility
#' @section Details:
#' An ALTER TABLE command will return the type of a field in a table in a
#' database.
#' @examples
#' \dontrun{
#' db_get_type("iris", "Species")
#' }
#' @export
db_get_type <- function(tablename, fieldname, conf_file = "~/.db_conf.yml") {
  tablename <- paste0('`', gsub('[`;]', '', tablename), '`')
  fieldname <- paste0("'", gsub("[';]", '', fieldname), "'")
  query <- paste("SHOW COLUMNS FROM", tablename, "WHERE Field =", fieldname)
  as.character(db_fetch_query(query, conf_file = conf_file)['Type'])
}

#' Set the Type of a Field.
#'
#' Set the type of a field (column) in a database table.
#' @param tablename (character) A table name in a database.
#' @param fieldname (character) A field name in a database table.
#' @param fieldtype (character) A field type to set for a field in a table.
#' @param conf_file (character) A file containing database connection parameters.
#'     (Default: "~/.db_conf.yml")
#' @return (integer) The number of rows affected by the field type change.
#' @keywords database, sql, MariaDB, utility
#' @section Details:
#' An ALTER TABLE command will change the type of a field in a table in a
#' database.
#' @examples
#' \dontrun{
#' db_set_type("iris", "Species", "varchar(32)")
#' }
#' @export
db_set_type <- function(tablename, fieldname, fieldtype,
                        conf_file = "~/.db_conf.yml") {
  tablename <- paste0('`', gsub('[`;]', '', tablename), '`')
  fieldname <- paste0("`", gsub("[`;]", '', fieldname), "`")
  fieldtype <- gsub("[;]", '', fieldtype)
  query <- paste("ALTER TABLE", tablename, "MODIFY", fieldname, fieldtype)
  db_run_query(query, conf_file = conf_file)
}

#' Add a Column (Field).
#'
#' Add a column (field) to a database table.
#' @param tablename (character) A table name in a database.
#' @param fieldname (character) A field name to add to a database table.
#' @param fieldtype (character) A field type to set for a field added to a table.
#' @param conf_file (character) A file containing database connection parameters.
#'     (Default: "~/.db_conf.yml")
#' @return (integer) The number of rows affected by the field addition.
#' @keywords database, sql, MariaDB, utility
#' @section Details:
#' An ALTER TABLE ... ADD COLUMN command will add a field to a table in a
#' database.
#' @examples
#' \dontrun{
#' db_add_col("iris", "Species", "varchar(32)")
#' }
#' @export
db_add_col <- function(tablename, fieldname, fieldtype,
                        conf_file = "~/.db_conf.yml") {
  tablename <- paste0('`', gsub('[`;]', '', tablename), '`')
  fieldname <- paste0("`", gsub("[`;]", '', fieldname), "`")
  fieldtype <- gsub("[;]", '', fieldtype)
  query <- paste("ALTER TABLE", tablename, "ADD COLUMN", fieldname, fieldtype)
  db_run_query(query, conf_file = conf_file)
}

#' Drop (Delete) a Column (Field).
#'
#' Remove a column (field) to a database table.
#' @param tablename (character) A table name in a database.
#' @param fieldname (character) A field name to remove from a database table.
#' @param conf_file (character) A file containing database connection parameters.
#'     (Default: "~/.db_conf.yml")
#' @return (integer) The number of rows affected by the field addition.
#' @keywords database, sql, MariaDB, utility
#' @section Details:
#' An ALTER TABLE ... DROP COLUMN command will remove a field from a table in
#' a database.
#' @examples
#' \dontrun{
#' db_drop_col("iris", "Species")
#' }
#' @export
db_drop_col <- function(tablename, fieldname, conf_file = "~/.db_conf.yml") {
  tablename <- paste0('`', gsub('[`;]', '', tablename), '`')
  fieldname <- paste0("`", gsub("[`;]", '', fieldname), "`")
  query <- paste("ALTER TABLE", tablename, "DROP COLUMN", fieldname)
  db_run_query(query, conf_file = conf_file)
}

#' Show structure of all tables.
#'
#' Show the columns and their properties for all of the tables in a database.
#' @param conf_file (character) A file containing database connection parameters.
#'     (Default: "~/.db_conf.yml")
#' @return (dataframe) The combined query results returned as a dataframe.
#' @keywords database, sql, MariaDB, utility
#' @section Details:
#' Results from SHOW COLUMNS queries for all tables in a database will be
#' combined into a single dataframe.
#' @examples
#' \dontrun{
#' db_str_all()
#' }
#' @export
db_str_all <- function(conf_file = "~/.db_conf.yml") {
    do.call('rbind',
            as.list(lapply(db_ls(conf_file = conf_file), function(x) {
                cbind(db_str(x, conf_file = conf_file), Table = x)
    })))
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
    sizes <- db_len()
    as.integer(sizes[sizes$TABLE_NAME == tablename, "TABLE_ROWS"])
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
#' @param ... Additional arguments passed to RMariaDB::dbWriteTable().
#' @return (boolean) Success: TRUE; failure: FALSE.
#' @keywords database, sql, MariaDB, utility
#' @section Details:
#' A dataframe will be sent to the database to be stored as a new table.
#' @examples
#' \dontrun{
#' db_send_table(datasets::iris, "iris")
#' }
#' @export
db_send_table <- function(df, tablename, conf_file = "~/.db_conf.yml", ...) {
    channel <- db_connect(conf_file = conf_file)
    if (!isFALSE(channel)) {
        res <- RMariaDB::dbWriteTable(channel, tablename, df, ...)
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
#' @param ... Additional arguments passed to RMariaDB::dbAppendTable().
#' @return (integer) Number of affected (appended) rows.
#' @keywords database, sql, MariaDB, utility
#' @section Details:
#' A dataframe will be sent to the database to be appended to an existing table.
#' @examples
#' \dontrun{
#' db_append_table(datasets::iris, "iris")
#' }
#' @export
db_append_table <- function(df, tablename, conf_file = "~/.db_conf.yml", ...) {
    channel <- db_connect(conf_file = conf_file)
    if (!isFALSE(channel)) {
        res <- RMariaDB::dbAppendTable(channel, tablename, df, ...)
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
#' of rows returned, where n = -1 means all records.
#' @examples
#' \dontrun{
#' db_fetch_table("iris")
#' }
#' @export
db_fetch_table <- function(tablename, n = -1, conf_file = "~/.db_conf.yml") {
    tablename <- paste0('`', gsub('[`;]', '', tablename), '`')
    db_fetch_query(paste('SELECT * FROM', tablename,
                         ifelse(n > 0, paste("LIMIT", as.integer(n)), "")))
}

#' Remove a Table
#'
#' Remove a table from a database.
#' @param tablename (character) A table name to remove from the database.
#' @param conf_file (character) A file containing database connection parameters.
#'     (Default: "~/.db_conf.yml")
#' @param ... Additional arguments passed to RMariaDB::RemoveTable().
#' @return (boolean) Success: TRUE; failure: FALSE.
#' @keywords database, sql, MariaDB, utility
#' @section Details:
#' A table will be removed from the database.
#' @examples
#' \dontrun{
#' db_rm("iris")
#' }
#' @export
db_rm <- function(tablename, conf_file = "~/.db_conf.yml", ...) {
    channel <- db_connect(conf_file = conf_file)
    if (!isFALSE(channel)) {
        res <- RMariaDB::dbRemoveTable(channel, tablename, ...)
        res_discon <- suppressWarnings(RMariaDB::dbDisconnect(channel))
        res
    }
}
