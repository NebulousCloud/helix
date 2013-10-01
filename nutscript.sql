/*
Navicat MySQL Data Transfer

Source Server         : localhost_3306
Source Server Version : 50528
Source Host           : localhost:3306
Source Database       : nutscript

Target Server Type    : MYSQL
Target Server Version : 50528
File Encoding         : 65001

Date: 2013-09-30 18:33:50
*/

SET FOREIGN_KEY_CHECKS=0;
-- ----------------------------
-- Table structure for `characters`
-- ----------------------------
DROP TABLE IF EXISTS `characters`;
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
) ENGINE=InnoDB AUTO_INCREMENT=45 DEFAULT CHARSET=latin1;

-- ----------------------------
-- Records of characters
-- ----------------------------

-- ----------------------------
-- Table structure for `players`
-- ----------------------------
DROP TABLE IF EXISTS `players`;
CREATE TABLE `players` (
  `key` int(10) unsigned zerofill NOT NULL AUTO_INCREMENT,
  `steamid` bigint(30) unsigned NOT NULL,
  `whitelists` varchar(100) NOT NULL,
  `plydata` mediumtext NOT NULL,
  `rpschema` varchar(16) NOT NULL,
  PRIMARY KEY (`key`)
) ENGINE=InnoDB AUTO_INCREMENT=34 DEFAULT CHARSET=latin1;

-- ----------------------------
-- Records of players
-- ----------------------------
