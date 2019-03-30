CREATE DATABASE IF NOT EXISTS vxaos_srv;
USE vxaos_srv;
CREATE TABLE IF NOT EXISTS accounts 
(
	account_id INT NOT NULL AUTO_INCREMENT, 
    username VARCHAR(50) NOT NULL, 
    password VARCHAR(50) NOT NULL, 
    email VARCHAR(150) NOT NULL, 
    account_group INT NOT NULL DEFAULT 0,
	PRIMARY KEY (account_id)
);
CREATE TABLE IF NOT EXISTS banks 
(
	bank_id INT NOT NULL AUTO_INCREMENT,
    account_id INT NOT NULL, 
	gold INT NOT NULL DEFAULT 0,
    PRIMARY KEY (bank_id),
    FOREIGN KEY (account_id) REFERENCES accounts(account_id)
);
CREATE TABLE IF NOT EXISTS bank_items 
(
	bank_item_id INT NOT NULL AUTO_INCREMENT,
    bank_id INT NOT NULL,
    item_id INT NOT NULL,
    item_amount INT DEFAULT 0,
    PRIMARY KEY (bank_item_id),
    FOREIGN KEY (bank_id) REFERENCES banks(bank_id)
);
CREATE TABLE IF NOT EXISTS bank_weapons
(
	bank_weapon_id INT NOT NULL AUTO_INCREMENT,
    bank_id INT NOT NULL,
    weapon_id INT NOT NULL,
    weapon_amount INT DEFAULT 0,
    PRIMARY KEY (bank_weapon_id),
    FOREIGN KEY (bank_id) REFERENCES banks(bank_id)
);
CREATE TABLE IF NOT EXISTS bank_armors
(
	bank_armor_id INT NOT NULL AUTO_INCREMENT,
    bank_id INT NOT NULL,
    armor_id INT NOT NULL,
    armor_amount INT DEFAULT 0,
    PRIMARY KEY (bank_armor_id),
    FOREIGN KEY (bank_id) REFERENCES banks(bank_id)
);
CREATE TABLE IF NOT EXISTS actors
(
	actor_id INT NOT NULL AUTO_INCREMENT,
	actor_slot_id INT NOT NULL,
    account_id INT NOT NULL,
    name VARCHAR(50) NOT NULL,
	character_name VARCHAR(50) NOT NULL,
	character_index INT NOT NULL,
	face_name VARCHAR(50) NOT NULL,
	face_index INT NOT NULL,
	class_id INT NOT NULL,
	sex INT NOT NULL,
	level INT NOT NULL,
	exp FLOAT NOT NULL,
	hp INT NOT NULL,
	mp INT NOT NULL,
    maxhp INT NOT NULL, 
    maxmp INT NOT NULL, 
    attack INT NOT NULL, 
    defense INT NOT NULL, 
    intelligence INT NOT NULL, 
    resistence INT NOT NULL, 
    agility INT NOT NULL, 
    luck INT NOT NULL,
	points INT NOT NULL,
	revive_map_id INT NOT NULL,
	revive_x FLOAT NOT NULL,
	revive_y FLOAT NOT NULL,
	map_id INT NOT NULL,
	x FLOAT NOT NULL,
	y FLOAT NOT NULL,
	direction INT NOT NULL,
	gold INT NOT NULL DEFAULT 0,
    deleted BOOL DEFAULT FALSE,
	PRIMARY KEY (actor_id),
    FOREIGN KEY (account_id) REFERENCES accounts(account_id)
);
CREATE TABLE IF NOT EXISTS actor_equips
(
	actor_equip_id INT NOT NULL AUTO_INCREMENT,
    actor_id INT NOT NULL,
    slot_id INT NOT NULL,
    equip_id INT DEFAULT 0,
    PRIMARY KEY (actor_equip_id),
	FOREIGN KEY (actor_id) REFERENCES actors(actor_id)
);
CREATE TABLE IF NOT EXISTS actor_items
(
	actor_item_id INT NOT NULL AUTO_INCREMENT,
	actor_id INT NOT NULL,
    item_id INT NOT NULL,
    item_amount INT DEFAULT 0,
    PRIMARY KEY (actor_item_id),
    FOREIGN KEY (actor_id) REFERENCES actors(actor_id)
);
CREATE TABLE IF NOT EXISTS actor_weapons
(
	actor_weapon_id INT NOT NULL AUTO_INCREMENT,
	actor_id INT NOT NULL,
    weapon_id INT NOT NULL,
    weapon_amount INT DEFAULT 0,
    PRIMARY KEY (actor_weapon_id),
    FOREIGN KEY (actor_id) REFERENCES actors(actor_id)
);
CREATE TABLE IF NOT EXISTS actor_armors
(
	actor_armor_id INT NOT NULL AUTO_INCREMENT,
	actor_id INT NOT NULL,
    armor_id INT NOT NULL,
    armor_amount INT DEFAULT 0,
    PRIMARY KEY (actor_armor_id),
    FOREIGN KEY (actor_id) REFERENCES actors(actor_id)
);
CREATE TABLE IF NOT EXISTS actor_hotbars
(
	actor_hotbar_id INT NOT NULL AUTO_INCREMENT,
	hotbar_slot_id INT NOT NULL,
    actor_id INT NOT NULL,
    type INT NOT NULL,
    item_id INT NOT NULL,
    PRIMARY KEY (actor_hotbar_id),
    FOREIGN KEY (actor_id) REFERENCES actors(actor_id)
);
CREATE TABLE IF NOT EXISTS actor_skills
(
	actor_skill_id INT NOT NULL AUTO_INCREMENT,
    actor_id INT NOT NULL,
    skill_id INT NOT NULL,
    PRIMARY KEY (actor_skill_id),
	FOREIGN KEY (actor_id) REFERENCES actors(actor_id)
);
CREATE TABLE IF NOT EXISTS actor_quests
(
	actor_quest_id INT NOT NULL AUTO_INCREMENT,
	actor_id INT NOT NULL,
    quest_id INT NOT NULL,
    state INT NOT NULL,
    kills INT NOt NULL,
    PRIMARY KEY (actor_quest_id),
    FOREIGN KEY (actor_id) REFERENCES actors(actor_id)
);
CREATE TABLE IF NOT EXISTS actor_friends
(
	actor_friend_id INT NOT NULL AUTO_INCREMENT,
    actor_id INT NOT NULL,
    friend_name VARCHAR(50) NOT NULL,
    PRIMARY KEY (actor_friend_id),
	FOREIGN KEY (actor_id) REFERENCES actors(actor_id)
);
CREATE TABLE IF NOT EXISTS actor_switches
(
	actor_switch_id INT NOT NULL AUTO_INCREMENT,
    switch_slot_id INT NOT NULL,
    actor_id INT NOT NULL,
    switch BOOL NOT NULL,
    PRIMARY KEY (actor_switch_id),
	FOREIGN KEY (actor_id) REFERENCES actors(actor_id)
);
CREATE TABLE IF NOT EXISTS actor_variables
(
	actor_variable_id INT NOT NULL AUTO_INCREMENT,
    variable_slot_id INT NOT NULL,
    actor_id INT NOT NULL,
    variable_id INT NOT NULL,
    PRIMARY KEY (actor_variable_id),
	FOREIGN KEY (actor_id) REFERENCES actors(actor_id)
);
CREATE TABLE IF NOT EXISTS actor_self_switches
(
	actor_self_switch_id INT NOT NULL AUTO_INCREMENT,
	actor_id INT NOT NULL,
    switch_key_1 INT NOT NULL,
    switch_key_2 INT NOT NULL,
    switch_key_3 VARCHAR(255) NOT NULL,
    switch_value BOOL NOT NULL,
    PRIMARY KEY (actor_self_switch_id),
    FOREIGN KEY (actor_id) REFERENCES actors(actor_id)
);