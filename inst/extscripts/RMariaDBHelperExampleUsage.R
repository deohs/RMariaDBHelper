# -----------------------------
# RMariaDBHelperExampleUsage.R
# -----------------------------

# This script contains sample commands for testing RMariaDBHelper functions.

# Load database helper package.
library(RMariaDBHelper)

# Set up configuration file for first use, if not already present.
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

# Show columns of a table.
db_str("arrests")

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
