SET FOREIGN_KEY_CHECKS=0;

CREATE TABLE `characters` (
  `key` mediumint(8) unsigned zerofill NOT NULL AUTO_INCREMENT,
  `steamid` bigint(30) unsigned NOT NULL,
  `charname` varchar(60) NOT NULL,
  `description` varchar(240) NOT NULL,
  `gender` varchar(6) NOT NULL,
  `money` mediumint(8) unsigned NOT NULL,
  `inv` mediumtext NOT NULL,
  `faction` tinyint(4) unsigned NOT NULL,
  `id` tinyint(4) unsigned NOT NULL,
  `chardata` mediumtext NOT NULL,
  `rpschema` varchar(16) NOT NULL,
  `model` tinytext NOT NULL,
  PRIMARY KEY (`key`)
) CHARSET=latin1;

CREATE TABLE `players` (
  `key` int(10) unsigned zerofill NOT NULL AUTO_INCREMENT,
  `steamid` bigint(30) unsigned NOT NULL,
  `whitelists` varchar(100) NOT NULL,
  `plydata` mediumtext NOT NULL,
  `rpschema` varchar(16) NOT NULL,
  PRIMARY KEY (`key`)
) CHARSET=latin1;