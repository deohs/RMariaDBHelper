# -----------------------------
# RMariaDBHelperExampleUsage.R
# -----------------------------

# This script contains sample commands for testing RMariaDBHelper functions.

# Optional: Set "enable-cleartext-plugin" option. Some DB servers need this.
# Note: For this to work, RMariaDBHelper and RMariaDB must not be loaded.
if ("RMariaDBHelper" %in% (.packages())) detach(package:RMariaDBHelper)
if ("RMariaDB" %in% (.packages())) detach(package:RMariaDB)
Sys.setenv(LIBMYSQL_ENABLE_CLEARTEXT_PLUGIN=1)

# Load RMariaDBHelper package.
library(RMariaDBHelper)

# Optional: Clear database configuration to force reading configuration file.
if (exists("db_conf")) rm("db_conf")

# Optional: Remove old configuration file, if it exists, to force creating it.
unlink("~/.db_conf.yml")

# Set up configuration file for first use, creating it if not found.
db_read_conf(conf_file = "~/.db_conf.yml",
             username = "my_username",
             host = "db.server.example.com",
             dbname = "my_dbname",
             sslmode = "REQUIRED",
             sslca = "/etc/db-ssl/ca-cert.pem",
             sslkey = "/etc/db-ssl/client-key-pkcs1.pem",
             sslcert = "/etc/db-ssl/client-cert.pem")

# Prepare a dataset for sending to the database. Store rownames as a column.
df <- datasets::USArrests
df$State <- as.character(row.names(df))
row.names(df) <- NULL

# Send a dataframe to the database as a new table.
db_send_table(df, "arrests")

# Add "id" as auto-incrementing integer primary key and create an index on it.
# This is not required but will help with some queries (below) and performance.
db_add_auto_id("arrests")

# Show a list of tables in a database.
db_ls()

# Show length and size of all tables in a database.
db_len()

# Show columns of a table.
db_str("arrests")

# Show columns of all tables.
db_str_all()

# Show indexes of a table.
db_fetch_query("SHOW INDEX FROM arrests;")

# Show number of rows in a table.
db_nrow("arrests")

# Show number of columns in a table.
db_ncol("arrests")

# Show dimensions of a table.
db_dim("arrests")

# Append to a table.
db_append_table(df, "arrests")

# Retrieve a table as a dataframe.
df.from.db <- db_fetch_table("arrests")
str(df.from.db)

# Retrieve first n rows of a table as a dataframe, as like head().
db_fetch_table("arrests", 6)

# Retrieve last n rows of a table as a dataframe, as like tail().
# Assumes "id" is stored in alphanumeric order, such as an auto-number key.
db_fetch_query("SELECT * FROM arrests ORDER BY id DESC LIMIT 6;")

# Remove a table.
db_rm("arrests")

# Clear the database configuration from memory when finished, for security.
rm(list = "db_conf")
