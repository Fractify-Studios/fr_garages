DROP TABLE IF EXISTS owned_vehicles;
CREATE TABLE owned_vehicles (
    owner VARCHAR(128) NOT NULL,
    second_owner VARCHAR(128) DEFAULT NULL,
    plate VARCHAR(64) NOT NULL PRIMARY KEY,
    model VARCHAR(128) NOT NULL,
    properties TEXT NOT NULL,
    type VARCHAR(128) DEFAULT 'car',
    `stored` BOOLEAN DEFAULT FALSE,
    parking VARCHAR(64) DEFAULT NULL,
    slot SMALLINT UNSIGNED DEFAULT NULL,
    INDEX (owner),
    INDEX (second_owner),
    INDEX (plate)
);
