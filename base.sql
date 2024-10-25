DROP TABLE IF EXISTS owned_vehicles;
CREATE TABLE owned_vehicles (
    owner VARCHAR(255) NOT NULL,
    second_owner VARCHAR(255) DEFAULT NULL,
    plate VARCHAR(255) NOT NULL PRIMARY KEY,
    model VARCHAR(255) NOT NULL,
    properties TEXT NOT NULL,
    type VARCHAR(255) DEFAULT 'car',
    `stored` BOOLEAN DEFAULT FALSE,
    parking VARCHAR(255) DEFAULT NULL,
    slot INT DEFAULT NULL
);
