# RMariaDB package function examples. This file is provided for reference.

# Modified from:
# - https://mariadb.com/kb/en/rmariadb/#rmariadb-package-function-examples
# See also:
# - https://rmariadb.r-dbi.org/

library(RMariaDB)
library(getPass)

# Create ~/.my.cnf if it does not already exist.
my_cnf <- c('[client]',
            'username = "my_username"',
            'database = "my_dbname"',
            'host = "db.server.example.com"',
            'sslmode = "REQUIRED"',
            'sslca = "/etc/db-ssl/ca-cert.pem"',
            'sslkey = "/etc/db-ssl/client-key-pkcs1.pem"',
            'sslcert = "/etc/db-ssl/client-cert.pem"',
            'enable-cleartext-plugin')
if (!file.exists("~/.my.cnf")) write(my_cnf, "~/.my.cnf")

# Edit configuration file to make any needed changes.
file.edit("~/.my.cnf")

# Connect to my-db as defined in ~/.my.cnf
con <- dbConnect(MariaDB(), group = "client", password = getPass())

dbListTables(con)
dbWriteTable(con, "mtcars", mtcars)
dbListTables(con)

dbListFields(con, "mtcars")
dbReadTable(con, "mtcars")

# You can fetch all results:
res <- dbSendQuery(con, "SELECT * FROM mtcars WHERE cyl = 4")
dbFetch(res)
dbClearResult(res)

# Or a chunk at a time
res <- dbSendQuery(con, "SELECT * FROM mtcars WHERE cyl = 4")
while(!dbHasCompleted(res)){
    chunk <- dbFetch(res, n = 5)
    print(nrow(chunk))
}
# Clear the result
dbClearResult(res)

# Remove the table
dbRemoveTable(con, "mtcars")

# Disconnect from the database
dbDisconnect(con)

