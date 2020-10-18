# -----------------------------
# RMariaDBHelperExampleUsage.R
# -----------------------------

# This script contains sample commands for testing RMariaDBHelper functions.

# ---------------------------------------------------------------------------
# Warning: Clear text password support is needed by some database servers.
# ---------------------------------------------------------------------------
# If you enable this, be sure that communications with the server are secure.
#
# Option 1: Set an environment variable, LIBMYSQL_ENABLE_CLEARTEXT_PLUGIN.
# To work, RMariaDBHelper, RMariaDB, and RMySQL must not be loaded.
unload_pkg <- function(x)
    if (x %in% (.packages()))
        detach(paste0('package:', x), character.only = TRUE, unload = TRUE)
res <- sapply(c('RMariaDBHelper', 'RMariaDB', 'RMySQL'), unload_pkg)
Sys.setenv(LIBMYSQL_ENABLE_CLEARTEXT_PLUGIN = 1)
#
# Option 2: Put "enable-cleartext-plugin" in your ~/.my.cnf file.
# This method may be preferable as it only needs to be run once.
my_cnf <- c("[client]", "enable-cleartext-plugin")
if (!file.exists("~/.my.cnf")) write(my_cnf, "~/.my.cnf")
# ---------------------------------------------------------------------------

# Load RMariaDBHelper package.
library(RMariaDBHelper)

# Optional: Clear database configuration to force reading configuration file.
if (exists("db_conf")) rm("db_conf")

# Optional: Remove old configuration file, if it exists, to force creating it.
unlink("~/.db_conf.yml")

# Set up configuration file for first use, creating it if not found.
# This only needs to be done once.
db_write_conf(conf_file = "~/.db_conf.yml",
              username = "my_username",
              host = "db.server.example.com",
              dbname = "my_dbname",
              sslmode = "REQUIRED",
              sslca = "/etc/db-ssl/ca-cert.pem",
              sslkey = "/etc/db-ssl/client-key-pkcs1.pem",
              sslcert = "/etc/db-ssl/client-cert.pem")

# Edit configuration file to make any needed changes.
file.edit("~/.db_conf.yml")

# Show a list of tables in a database.
db_ls()

# Prepare a dataset for sending to the database. Store rownames as a column.
df <- datasets::USArrests
df$State <- as.character(row.names(df))
row.names(df) <- NULL

# Send a dataframe to the database.
db_send_table(df, "arrests", overwrite = TRUE)

# Show a list of tables in a database.
db_ls()

# Show length and size of all tables in a database.
db_len()

# Show column names of a table.
db_colnames("arrests")

# Show column structure of a table.
db_str("arrests")

# Show columns of all tables.
db_str_all()

# Show number of rows in a table.
db_nrow("arrests")

# Show number of columns in a table.
db_ncol("arrests")

# Show dimensions of a table.
db_dim("arrests")

# Retrieve a table as a dataframe.
df.from.db <- db_fetch_table("arrests")
str(df.from.db)

# ---------------------------------------------------------------------------
# Advanced examples
# ---------------------------------------------------------------------------

# ---------------------------
# Adding a primary key field
# ---------------------------

# "arrests" already has a column with unique values: State. But if we
# appended more records (rows) we could end up duplicating state names.
# Adding an auto-number primary key field will ensure key uniqueness.

# Add "id" as auto-incrementing integer primary key and create an index on it.
# This is not required but will help with some queries (below) and performance.
db_add_auto_id("arrests")

# Show column structure of a table.
db_str("arrests")

# Show indexes of a table.
db_fetch_query("SHOW INDEX FROM arrests;")

# --------------
# Head and tail
# --------------

# Head is easy, but tail needs that auto-number "id" field we just created.

# Retrieve first n rows of a table as a dataframe, like head().
db_fetch_table("arrests", 6)

# Retrieve last n rows of a table as a dataframe, like tail().
# Assumes "id" is stored in alphanumeric order, such as an auto-number key.
db_fetch_query("SELECT * FROM arrests ORDER BY id DESC LIMIT 6;")

# ---------------------
# Changing column type
# ---------------------

# Creating tables upon import has risks, just like when you import CSVs. The
# column types may not be exactly what you want. Here we do some fine tuning.

# Get Type of State field, like typeof().
db_get_type("arrests", "State")

# Q: Why is the Type of State set to varchar(14)?
max(nchar(df$State))
db_fetch_query("SELECT MAX(LENGTH(State)) FROM arrests;")

# Increase the maximum allowed width of State field.
db_set_type("arrests", "State", "varchar(32)")

# Show that column structure has changed.
db_str("arrests")

# -------------------------------------
# Changing column values: 4 variations
# -------------------------------------

# In R it is easy to add a new column with assignment, cbind(), or merging.
# But as SQL databases are meant to be updated by row, not by column, we find
# this to be a tricky task with MariaDB.

# For the next examples, create a dataframe of state abbreviations and names.
state_df <- data.frame(StateAbb = datasets::state.abb,
                       State = datasets::state.name,
                       stringsAsFactors = FALSE)

# Method #1: Add a new column and fill it with data, row by row. (Slow.)
system.time({
    db_add_col("arrests", "StateAbb", "varchar(2)")
    res <- mapply(function(x, y) {
        db_run_query(paste0(
            "UPDATE arrests SET StateAbb = '", x, "' WHERE State = '", y, "';"))
    }, state_df$StateAbb, state_df$State)
})

# Retrieve first n rows of a table as a dataframe, like head().
db_fetch_table("arrests", 6)

# Remove (drop) a column from a table.
db_drop_col("arrests", "StateAbb")

# Method #2: Overwrite the table with a new one made from a SQL JOIN. (Fast.)
system.time({
    db_send_table(state_df, "states", overwrite = TRUE)
    db_send_table(
        db_fetch_query(
        "SELECT a.Murder, a.Assault, a.UrbanPop, a.Rape, a.State, s.StateAbb
        FROM arrests a INNER JOIN states s ON a.State = s.State;"),
        "arrests", overwrite = TRUE)
})

# Retrieve first n rows of a table as a dataframe, like head().
db_fetch_table("arrests", 6)

# Remove (drop) a column from a table.
db_drop_col("arrests", "StateAbb")

# Method #3: Create a new table from a SQL JOIN. (Fastest for big tables.)
system.time({
    db_send_table(state_df, "states", overwrite = TRUE)
    db_rm("arrests2", fail_if_missing = FALSE)
    db_run_query(
         "CREATE TABLE arrests2 AS
         SELECT a.Murder, a.Assault, a.UrbanPop, a.Rape, a.State, s.StateAbb
         FROM arrests a INNER JOIN states s ON a.State = s.State;")
})

# Retrieve first n rows of a table as a dataframe, like head().
db_fetch_table("arrests2", 6)

# Method #4: Replace a table with a merged dataframe. (Fastest for small tables.)
system.time({
    db_send_table(
            merge(db_fetch_table("arrests"), state_df, by = "State"),
        "arrests", overwrite = TRUE)
})

# Retrieve first n rows of a table as a dataframe, like head().
db_fetch_table("arrests", 6)

# Remove (drop) a column from a table.
db_drop_col("arrests", "StateAbb")

# ---------------------------------------------------------------------------
# Appending rows: This is easier and faster than adding and filling columns.
# ---------------------------------------------------------------------------

# Append rows to a table from a dataframe. Here we append another copy of df.
system.time({
    db_append_table(df, "arrests")
})

# Show number of rows in a table.
db_nrow("arrests")

# ---------------------------------------------------------------------------
# Cleanup
# ---------------------------------------------------------------------------

# Remove extra tables.
res <- sapply(c('arrests', 'arrests2', 'states'), db_rm, fail_if_missing = FALSE)

# Clear the database configuration from memory when finished, for security.
rm(db_conf)
