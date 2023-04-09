using SQLite

export setup_database

function setup_database(filename::String)
    db = SQLite.DB(filename)
    return db
end
