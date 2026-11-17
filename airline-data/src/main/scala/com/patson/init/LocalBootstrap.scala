package com.patson.init

import java.sql.{Connection, DriverManager}

import com.patson.data.Constants._

/**
  * Entry point for running the game locally (see docker-compose.yml / LOCAL_PLAY.md).
  *
  * 1. Waits until the MySQL database accepts connections
  * 2. If the world has never been generated in this database, runs MainInit (takes a while, only once)
  * 3. Exits, so the caller can then start MainSimulation in a fresh JVM
  *
  * Must be run with airline-data as the working directory, since MainInit reads the csv/txt files there.
  */
object LocalBootstrap {
  val MARKER_TABLE = "local_bootstrap_marker"

  def main(args : Array[String]) : Unit = {
    waitForDatabase()

    if (isInitialized()) {
      println("World data already exists, skipping init")
    } else {
      println("No world data found. Generating the world (first launch only, this can take a while)...")
      val start = System.currentTimeMillis()
      MainInit.main(Array.empty)
      markInitialized()
      println(s"World generated in ${(System.currentTimeMillis() - start) / 1000} secs")
    }
    System.exit(0) //MainInit may leave non-daemon threads (actor system etc.) behind
  }

  private[this] def withConnection[T](f : Connection => T) : T = {
    Class.forName(DB_DRIVER)
    val connection = DriverManager.getConnection(DATABASE_CONNECTION, DATABASE_USER, DATABASE_PASSWORD)
    try {
      f(connection)
    } finally {
      connection.close()
    }
  }

  private[this] def waitForDatabase() : Unit = {
    val maxAttempts = 120
    var attempt = 0
    while (attempt < maxAttempts) {
      try {
        withConnection(_.isValid(5))
        println("Database is up")
        return
      } catch {
        case e : Exception =>
          attempt += 1
          println(s"Waiting for database at $DB_HOST ($attempt/$maxAttempts): ${e.getMessage}")
          Thread.sleep(2000)
      }
    }
    throw new IllegalStateException(s"Database at $DB_HOST did not become available")
  }

  private[this] def isInitialized() : Boolean = withConnection { connection =>
    val resultSet = connection.getMetaData.getTables(connection.getCatalog, null, MARKER_TABLE, null)
    try {
      resultSet.next()
    } finally {
      resultSet.close()
    }
  }

  private[this] def markInitialized() : Unit = withConnection { connection =>
    val statement = connection.createStatement()
    try {
      statement.execute(s"CREATE TABLE IF NOT EXISTS $MARKER_TABLE (initialized_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)")
      statement.execute(s"INSERT INTO $MARKER_TABLE () VALUES ()")
    } finally {
      statement.close()
    }
  }
}
