CREATE DATABASE IF NOT EXISTS WildlifeCareChecker;
USE WildlifeCareChecker;


CREATE TABLE User (
    User_ID INT PRIMARY KEY AUTO_INCREMENT,
    User_Name VARCHAR(50) NOT NULL UNIQUE,
    Password VARCHAR(255) NOT NULL,
    Role VARCHAR(20) NOT NULL CHECK (Role IN ('Admin', 'Viewer'))
);


CREATE TABLE Conservation_Status (
    Status_ID INT PRIMARY KEY AUTO_INCREMENT,
    Status_Name VARCHAR(50) NOT NULL,
    Threat_Level VARCHAR(50),
    Criteria_for_Status TEXT
);


CREATE TABLE Animal (
    Animal_ID INT PRIMARY KEY AUTO_INCREMENT,
    Common_Name VARCHAR(100) NOT NULL,
    Scientific_Name VARCHAR(100),
    General_Description TEXT,
    Origin_Era VARCHAR(50),
    Status_ID INT,
    FOREIGN KEY (Status_ID) REFERENCES Conservation_Status(Status_ID) ON DELETE SET NULL
);

CREATE TABLE Species_History (
    History_ID INT PRIMARY KEY AUTO_INCREMENT,
    Animal_ID INT NOT NULL,
    Era_Name VARCHAR(50) NOT NULL,
    Population_Estimate INT,
    Habitat_Type VARCHAR(100),
    FOREIGN KEY (Animal_ID) REFERENCES Animal(Animal_ID) ON DELETE CASCADE
);


CREATE TABLE Prevention_Plan (
    Plan_ID INT PRIMARY KEY AUTO_INCREMENT,
    Animal_ID INT NOT NULL,
    Action_Steps TEXT NOT NULL,
    Organization_Involved VARCHAR(100),
    Success_Rate DECIMAL(5,2),
    FOREIGN KEY (Animal_ID) REFERENCES Animal(Animal_ID) ON DELETE CASCADE
);