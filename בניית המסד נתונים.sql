use master
go
create database DynamicCalcDB
use DynamicCalcDB
go



CREATE TABLE t_data (
    data_id INT IDENTITY(1,1) PRIMARY KEY NOT NULL, 
    a FLOAT NOT NULL,                                
    b FLOAT NOT NULL,                                 
    c FLOAT NOT NULL,                                 
    d FLOAT NOT NULL                                 
);


CREATE TABLE t_targil (
    targil_id INT IDENTITY(1,1) PRIMARY KEY NOT NULL, 
    targil VARCHAR(MAX) NOT NULL,                     
    tnai VARCHAR(MAX) NULL,                           
    targil_false VARCHAR(MAX) NULL
);


CREATE TABLE t_result (
    results_id INT IDENTITY(1,1) PRIMARY KEY NOT NULL, 
    data_id INT NOT NULL,                              
    targil_id INT NOT NULL,                           
    method VARCHAR(50) NOT NULL,                       
    result FLOAT NULL,                                
    
    CONSTRAINT FK_Result_Data FOREIGN KEY (data_id) REFERENCES t_data(data_id),       
    CONSTRAINT FK_Result_Targil FOREIGN KEY (targil_id) REFERENCES t_targil(targil_id) 
);


CREATE TABLE t_log (
    log_id INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    targil_id INT NOT NULL,                            
    method VARCHAR(50) NOT NULL,                       
    run_time FLOAT NULL,                               
    
    CONSTRAINT FK_Log_Targil FOREIGN KEY (targil_id) REFERENCES t_targil(targil_id)
);

