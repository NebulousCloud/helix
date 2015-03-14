--[[
	Welcome to the NutScript database configuration.
	Here, you can change what method of data storage you would prefer.

	The following methods are available:
		- tmysql4
			- https://code.google.com/p/blackawps-glua-modules/source/browse/gm_tmysql4_boost/Release/
			- Includes both Windows and Linux
			- Requires setup (see below)
		- mysqloo
			- http://facepunch.com/showthread.php?t=1357773
			- Includes both Windows and Linux
			- Requires setup (see below)
		- sqlite
			- No download needed
			- No setup required

	If you want to use an external database (tmysql4 and mysqloo) then
	you will need to place the included .dll files into your server's
	lua/bin folder. Then place the libmysql files (tmysql's website says libs.rar and
	the mysqloo thread contains a link labeled libmysql) in the folder that contains
	srcds.

	The benefits of using an external database:
		- You can display stats on your website.
		- Can share data between servers.
		- Each to access data than with SQLite (SQLite data is stored in the sv.db file)
	Cons:
		- Requires setup
		- Some server providers do not allow the uploading of .dll files so you may need
		  to ask them for support.
	  	- Is not as instant as SQLite (but the delay should be barely noticable)

  	The following configurations are ONLY needed if you are going to be using an
  	external database for your NutScript installation.
--]]

-- Which method of storage: sqlite, tmysql4, mysqloo
nut.db.module = "sqlite"
-- The hostname for the MySQL server.
nut.db.hostname = "localhost"
-- The username to login to the database.
nut.db.username = "root"
-- The password that is associated with the username.
nut.db.password = "password"
-- The database that the user should login to.
nut.db.database = "nutscript"
-- The port for the database, you shouldn't need to change this.
nut.db.port = 3306